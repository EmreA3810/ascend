import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/xp_gain_popup.dart';
import '../data/pomodoro_session_model.dart';
import '../providers/pomodoro_provider.dart';
import '../../user/providers/user_provider.dart';
import 'session_history_sheet.dart';
import '../../quests/providers/quest_provider.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with TickerProviderStateMixin {
  int _selectedWorkDuration = 25; // in minutes
  int _selectedBreakDuration = 5; // in minutes

  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;

  String _selectedFocusArea = 'academic'; // 'academic', 'fitness', 'reading', 'coding'

  // Workout Assistant state
  int _currentExerciseIndex = 0; // 0: Push-up, 1: Squat, 2: Plank
  int _completedSets = 0; // 0 to 3
  bool _isResting = false;
  int _restSecondsLeft = 30;
  Timer? _restTimer;

  late AnimationController _pulseController;

  // Immersive Mode
  OverlayEntry? _immersiveOverlay;
  bool _isImmersive = false;

  // Audio Player
  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.5;
  int _currentTrackIndex = 0;
  bool _isMusicPlaying = false;
  StreamSubscription? _playerSubscription;

  final List<Map<String, String>> _playlist = const [
    {
      'name': 'Soft Lofi Beats ☕',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      'name': 'Chill Ambient Rain 🌧️',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'name': 'Focus Forest Sound 🌲',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    },
    {
      'name': 'Deep Synth Meditation 🧘',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'
    },
  ];

  @override
  void initState() {
    super.initState();
    _secondsLeft = _selectedWorkDuration * 60;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Audio player sequential play listener
    _playerSubscription = _player.onPlayerComplete.listen((event) {
      _nextTrack();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _restTimer?.cancel();
    _pulseController.dispose();
    _playerSubscription?.cancel();
    _player.dispose();
    if (_isImmersive) {
      _immersiveOverlay?.remove();
    }
    super.dispose();
  }

  void _updateOverlay() {
    _immersiveOverlay?.markNeedsBuild();
  }

  void _updateState(VoidCallback fn) {
    setState(fn);
    _updateOverlay();
  }

  void _selectWorkDuration(int mins) {
    if (_isRunning) return;
    _updateState(() {
      _selectedWorkDuration = mins;
      if (!_isBreak) {
        _secondsLeft = mins * 60;
      }
    });
  }

  void _selectBreakDuration(int mins) {
    if (_isRunning) return;
    _updateState(() {
      _selectedBreakDuration = mins;
      if (_isBreak) {
        _secondsLeft = mins * 60;
      }
    });
  }

  void _startPause() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if (_isRunning) {
      _timer?.cancel();
      _updateState(() {
        _isRunning = false;
      });
    } else {
      _updateState(() {
        _isRunning = true;
      });
      
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 1) {
          _updateState(() {
            _secondsLeft--;
          });
        } else {
          _timer?.cancel();
          _onTimerComplete(user.uid);
        }
      });
    }
  }

  Future<void> _onTimerComplete(String uid) async {
    if (!_isBreak) {
      // Focus session ended
      final ended = DateTime.now();
      final started = ended.subtract(Duration(minutes: _selectedWorkDuration));
      final xpEarned = _selectedWorkDuration * 2;

      final session = PomodoroSessionModel(
        id: '',
        startedAt: started,
        endedAt: ended,
        workMinutes: _selectedWorkDuration,
        breakMinutes: _selectedBreakDuration,
        xpEarned: xpEarned,
        completed: true,
      );

      // Save to Firestore
      await ref.read(pomodoroRepositoryProvider).saveSession(uid, session);

      // Fetch active quests
      final dailyQuests = ref.read(dailyQuestsProvider).value ?? [];
      final weeklyQuests = ref.read(weeklyQuestsProvider).value ?? [];
      final customQuests = ref.read(customQuestsProvider).value ?? [];

      // 1. Increment standard Pomodoro completion daily quests (unit == 'seans')
      final seansQuests = dailyQuests.where((q) => q.unit == 'seans' && !q.isCompleted);
      for (final q in seansQuests) {
        await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, 1);
      }

      // 2. Focus area specific actions
      if (_selectedFocusArea == 'academic') {
        // Study duration quests
        final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
            .where((q) => q.unit == 'dk' && !q.isCompleted && (q.statBoost == 'knowledge' || q.title.toLowerCase().contains('ders') || q.title.toLowerCase().contains('çalışma')));
        for (final q in targetQuests) {
          await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, _selectedWorkDuration);
        }

        if (mounted) {
          XpGainPopup.show(context, xp: xpEarned, statName: 'knowledge', statAmount: 1);
        }
      } else if (_selectedFocusArea == 'coding') {
        // Coding duration quests
        final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
            .where((q) => q.unit == 'dk' && !q.isCompleted && (q.statBoost == 'focus' || q.title.toLowerCase().contains('kod') || q.title.toLowerCase().contains('yazılım')));
        for (final q in targetQuests) {
          await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, _selectedWorkDuration);
        }

        if (mounted) {
          XpGainPopup.show(context, xp: xpEarned, statName: 'focus', statAmount: 1);
        }
      } else if (_selectedFocusArea == 'reading') {
        // Okuma focus triggers the page dialog
        await _showReadingPageDialog(uid, xpEarned);
      } else {
        // General focus area
        if (mounted) {
          XpGainPopup.show(context, xp: xpEarned, statName: 'focus', statAmount: 1);
        }
      }

      // Automatically switch to break mode
      _updateState(() {
        _isBreak = true;
        _secondsLeft = _selectedBreakDuration * 60;
        _isRunning = false;
      });
    } else {
      // Break session ended
      _updateState(() {
        _isBreak = false;
        _secondsLeft = _selectedWorkDuration * 60;
        _isRunning = false;
      });
    }
  }

  Future<void> _showReadingPageDialog(String uid, int pomodoroXp) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final pages = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          title: Text(
            '📖 Kitap Okuma Günlüğü',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu odak seansında kaç sayfa kitap okudunuz?',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Örn. 20',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Lütfen sayfa sayısı girin';
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) return 'Geçerli bir sayfa sayısı girin';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '💡 Her sayfa için ekstra +3 XP kazanırsınız!',
                  style: GoogleFonts.inter(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: Text(
                'Pas Geç',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final val = int.parse(controller.text.trim());
                  Navigator.pop(ctx, val);
                }
              },
              child: Text(
                'Kaydet',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    int pagesRead = pages ?? 0;
    int pageXp = pagesRead * 3;
    int totalXp = pomodoroXp + pageXp;

    if (pagesRead > 0) {
      // 1. Add XP for pages to Firebase
      await ref.read(userRepositoryProvider).addXp(uid, pageXp);

      // 2. Increment reading quests progress
      final dailyQuests = ref.read(dailyQuestsProvider).value ?? [];
      final weeklyQuests = ref.read(weeklyQuestsProvider).value ?? [];
      final customQuests = ref.read(customQuestsProvider).value ?? [];

      final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
          .where((q) => q.unit == 'sayfa' && !q.isCompleted);
      for (final q in targetQuests) {
        await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, pagesRead);
      }
    }

    if (mounted) {
      XpGainPopup.show(context, xp: totalXp, statName: 'energy', statAmount: 1);
    }
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsLeft = 30;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft > 1) {
        setState(() {
          _restSecondsLeft--;
        });
      } else {
        _endRest();
      }
    });
  }

  void _endRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
    });
  }

  void _onSetCompleted(String uid) async {
    if (_isResting) return;

    final dailyQuests = ref.read(dailyQuestsProvider).value ?? [];
    final weeklyQuests = ref.read(weeklyQuestsProvider).value ?? [];
    final customQuests = ref.read(customQuestsProvider).value ?? [];

    // 1. Increment quest progress
    final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
        .where((q) => q.unit == 'set' && !q.isCompleted);
    for (final q in targetQuests) {
      await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, 1);
    }

    // 2. Award XP and boost strength stat
    await ref.read(userRepositoryProvider).addXp(uid, 10);
    await ref.read(userRepositoryProvider).boostStat(uid, 'strength', 1);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harika! Set tamamlandı. +10 XP ve +1 GÜÇ kazanıldı. 💪'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 3. Check progression
    setState(() {
      _completedSets++;
    });

    // Check if exercise completed
    if (_completedSets >= 3) {
      if (_currentExerciseIndex < 2) {
        // Move to next exercise
        _startRestTimer();
        setState(() {
          _currentExerciseIndex++;
          _completedSets = 0;
        });
      } else {
        // All exercises completed
        _onWorkoutComplete(uid);
      }
    } else {
      // Start rest timer between sets
      _startRestTimer();
    }
  }

  Future<void> _onWorkoutComplete(String uid) async {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _completedSets = 0;
      _currentExerciseIndex = 0;
    });

    // Save pomodoro session
    final ended = DateTime.now();
    final started = ended.subtract(const Duration(minutes: 25));
    const xpEarned = 50; // Special workout completion XP

    final session = PomodoroSessionModel(
      id: '',
      startedAt: started,
      endedAt: ended,
      workMinutes: 25,
      breakMinutes: 5,
      xpEarned: xpEarned,
      completed: true,
    );

    await ref.read(pomodoroRepositoryProvider).saveSession(uid, session);

    if (mounted) {
      XpGainPopup.show(context, xp: xpEarned, statName: 'strength', statAmount: 2);
    }
  }

  Widget _buildFocusAreaSelector() {
    final areas = [
      {'id': 'academic', 'label': 'Ders', 'icon': Icons.school, 'color': AppColors.statKnowledge},
      {'id': 'fitness', 'label': 'Spor', 'icon': Icons.fitness_center, 'color': AppColors.statStrength},
      {'id': 'reading', 'label': 'Okuma', 'icon': Icons.menu_book, 'color': AppColors.statEnergy},
      {'id': 'coding', 'label': 'Yazılım', 'icon': Icons.code, 'color': AppColors.statFocus},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: areas.map((area) {
          final isSelected = _selectedFocusArea == area['id'];
          final color = area['color'] as Color;
          return GestureDetector(
            onTap: _isRunning
                ? null
                : () {
                    setState(() {
                      _selectedFocusArea = area['id'] as String;
                    });
                  },
            child: Opacity(
              opacity: _isRunning && !isSelected ? 0.5 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : AppColors.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      area['icon'] as IconData,
                      color: isSelected ? color : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      area['label'] as String,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkoutAssistant(String uid, int level) {
    // Reps scaling based on user level
    final pushUpReps = (5 + level * 2).clamp(5, 40);
    final squatReps = (10 + level * 3).clamp(10, 60);
    final plankDuration = (20 + level * 5).clamp(20, 180);

    final exercises = [
      {
        'name': 'Şınav (Push-up)',
        'target': '$pushUpReps Tekrar',
        'desc': 'Göğüs ve kol kaslarını çalıştırır.',
        'icon': Icons.fitness_center,
      },
      {
        'name': 'Squat',
        'target': '$squatReps Tekrar',
        'desc': 'Bacak ve kalça kaslarını çalıştırır.',
        'icon': Icons.accessibility_new_rounded,
      },
      {
        'name': 'Plank',
        'target': '$plankDuration Saniye',
        'desc': 'Karın ve çekirdek (core) bölgesini güçlendirir.',
        'icon': Icons.timer_outlined,
      },
    ];

    final currentExercise = exercises[_currentExerciseIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.statStrength.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Antrenman Yardımcısı',
                style: GoogleFonts.inter(
                  color: AppColors.statStrength,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statStrength.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Egzersiz ${_currentExerciseIndex + 1}/3',
                  style: GoogleFonts.inter(
                    color: AppColors.statStrength,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isResting) ...[
            // Rest state
            Column(
              children: [
                const SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: null,
                        color: AppColors.secondary,
                        strokeWidth: 6,
                      ),
                      Icon(Icons.coffee_rounded, color: AppColors.secondary, size: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MOLA ZAMANI',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sonraki sete hazırlan: $_restSecondsLeft saniye kaldı',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: _endRest,
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  label: Text(
                    'Molayı Geç',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Workout state
            Column(
              children: [
                // Exercise details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statStrength.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentExercise['icon'] as IconData,
                          color: AppColors.statStrength,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentExercise['name'] as String,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentExercise['desc'] as String,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Target reps display
                Text(
                  currentExercise['target'] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                Text(
                  'Hedeflenen Tekrar / Süre',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 24),

                // Completed sets tracker dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isCompleted = index < _completedSets;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 48,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.statStrength
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.statStrength.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Set Completed Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statStrength,
                      elevation: 5,
                      shadowColor: AppColors.statStrength.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _onSetCompleted(uid),
                    icon: const Icon(Icons.fitness_center_rounded, color: Colors.white),
                    label: Text(
                      'Set Tamamlandı',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          // Exercise navigation
          if (!_isResting)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: _currentExerciseIndex > 0
                      ? () {
                          setState(() {
                            _currentExerciseIndex--;
                            _completedSets = 0;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Önceki Egzersiz'),
                  style: TextButton.styleFrom(
                    foregroundColor: _currentExerciseIndex > 0 ? AppColors.textSecondary : Colors.transparent,
                  ),
                ),
                TextButton.icon(
                  onPressed: _currentExerciseIndex < 2
                      ? () {
                          setState(() {
                            _currentExerciseIndex++;
                            _completedSets = 0;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Sonraki Egzersiz'),
                  style: TextButton.styleFrom(
                    foregroundColor: _currentExerciseIndex < 2 ? AppColors.textSecondary : Colors.transparent,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _reset() {
    _timer?.cancel();
    _updateState(() {
      _secondsLeft = _isBreak ? _selectedBreakDuration * 60 : _selectedWorkDuration * 60;
      _isRunning = false;
    });
  }

  void _skip() {
    _timer?.cancel();
    _updateState(() {
      _isBreak = !_isBreak;
      _secondsLeft = _isBreak ? _selectedBreakDuration * 60 : _selectedWorkDuration * 60;
      _isRunning = false;
    });
  }

  // Audio actions
  Future<void> _playCurrentTrack() async {
    final track = _playlist[_currentTrackIndex];
    await _player.play(UrlSource(track['url']!));
    await _player.setVolume(_volume);
    _updateState(() {
      _isMusicPlaying = true;
    });
  }

  Future<void> _pauseMusic() async {
    await _player.pause();
    _updateState(() {
      _isMusicPlaying = false;
    });
  }

  Future<void> _toggleMusic() async {
    if (_isMusicPlaying) {
      await _pauseMusic();
    } else {
      await _playCurrentTrack();
    }
  }

  Future<void> _nextTrack() async {
    _updateState(() {
      _currentTrackIndex = (_currentTrackIndex + 1) % _playlist.length;
    });
    await _playCurrentTrack();
  }

  Future<void> _prevTrack() async {
    _updateState(() {
      _currentTrackIndex = (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;
    });
    await _playCurrentTrack();
  }

  Future<void> _setVolume(double vol) async {
    _updateState(() {
      _volume = vol;
    });
    await _player.setVolume(vol);
  }

  // Immersive Overlay
  void _toggleImmersive(bool active) {
    setState(() {
      _isImmersive = active;
    });

    if (active) {
      _immersiveOverlay = OverlayEntry(
        builder: (ctx) => _buildImmersiveView(context),
      );
      Overlay.of(context).insert(_immersiveOverlay!);
    } else {
      _immersiveOverlay?.remove();
      _immersiveOverlay = null;
    }
  }

  String get _timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _isBreak ? _selectedBreakDuration * 60 : _selectedWorkDuration * 60;
    return total > 0 ? (1.0 - (_secondsLeft / total)).clamp(0.0, 1.0) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final Color accentColor = _isBreak ? AppColors.secondary : AppColors.primary;
    final todaySessionsAsync = ref.watch(todaySessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Pomodoro',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Track Info Bar
            Text(
              _isMusicPlaying
                  ? "Active Soft Track: ${_playlist[_currentTrackIndex]['name']}"
                  : "Music Paused 🎵",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Focus Area Selector
            _buildFocusAreaSelector(),
            const SizedBox(height: 12),

            if (_selectedFocusArea == 'fitness') ...[
              _buildWorkoutAssistant(user.uid, user.level),
            ] else ...[
              // Mode indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  _isBreak ? '☕ Mola Zamanı' : '⚡ Odak Modu',
                  style: GoogleFonts.inter(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              // Timer ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final glow = _isRunning ? (_pulseController.value * 0.25 + 0.1) : 0.05;
                  return Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: glow),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 210,
                      height: 210,
                      child: CircularProgressIndicator(
                        value: _progress,
                        backgroundColor: AppColors.cardBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeString,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _isBreak ? 'Mola' : 'Çalışma',
                          style: GoogleFonts.inter(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Screen Timer Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _startPause,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 15, spreadRadius: 1),
                        ],
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _skip,
                    icon: const Icon(Icons.skip_next_rounded, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _toggleImmersive(true),
                    icon: const Icon(Icons.fullscreen_rounded, size: 28, color: AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Custom Durations Row Selection Chips
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Çalışma Süresi (Dakika)',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [1, 15, 25, 45, 60].map((mins) {
                        final isSel = _selectedWorkDuration == mins;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text('$mins dk'),
                              selected: isSel,
                              onSelected: (_) => _selectWorkDuration(mins),
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.primary.withValues(alpha: 0.2),
                              labelStyle: GoogleFonts.inter(
                                color: isSel ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Mola Süresi (Dakika)',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [5, 10, 15].map((mins) {
                        final isSel = _selectedBreakDuration == mins;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              showCheckmark: false,
                              label: Text('$mins dk'),
                              selected: isSel,
                              onSelected: (_) => _selectBreakDuration(mins),
                              backgroundColor: AppColors.background,
                              selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                              labelStyle: GoogleFonts.inter(
                                color: isSel ? AppColors.secondary : AppColors.textSecondary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSel ? AppColors.secondary : AppColors.secondary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Music Controls Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Müzik Çalar',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 20),
                            onPressed: _prevTrack,
                          ),
                          IconButton(
                            icon: Icon(
                              _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                              color: AppColors.secondary,
                              size: 28,
                            ),
                            onPressed: _toggleMusic,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 20),
                            onPressed: _nextTrack,
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, color: AppColors.textSecondary, size: 16),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.secondary,
                          inactiveColor: AppColors.background,
                          onChanged: _setVolume,
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Horizontal Completed Sessions List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bugün Tamamlananlar',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const SessionHistorySheet(),
                    );
                  },
                  child: Text(
                    'Tüm Geçmiş',
                    style: GoogleFonts.inter(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Horizontal completed sessions list
            todaySessionsAsync.when(
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Container(
                    height: 70,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bugün henüz tamamlanmış seans yok. ⚡',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  );
                }
                return SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sessions.length,
                    itemBuilder: (ctx, i) {
                      final session = sessions[i];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '⚡ ${session.workMinutes} dk Odak',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+${session.xpEarned} XP',
                              style: GoogleFonts.inter(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SizedBox(height: 70, child: Center(child: CircularProgressIndicator())),
              error: (e, s) => SizedBox(
                height: 70,
                child: Center(
                  child: Text('Veriler alınamadı', style: GoogleFonts.inter(color: AppColors.error, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Immersive view builder
  Widget _buildImmersiveView(BuildContext context) {
    final Color accentColor = _isBreak ? AppColors.secondary : AppColors.primary;
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: size.width,
        height: size.height,
        color: AppColors.background,
        child: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background glow
              Positioned(
                top: size.height * 0.1,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final glow = _isRunning ? (_pulseController.value * 0.4 + 0.15) : 0.1;
                    return Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: glow),
                            blurRadius: 100,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Close / Exit button in top right
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 36),
                  onPressed: () {
                    _toggleImmersive(false);
                  },
                ),
              ),

              // Content Column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Active Song Title
                    Text(
                      _isMusicPlaying
                          ? "Active Soft Track: ${_playlist[_currentTrackIndex]['name']}"
                          : "Music Paused 🎵",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Mode Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _isBreak ? '☕ Mola Zamanı' : '⚡ Odak Modu',
                        style: GoogleFonts.inter(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Timer ring
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return SizedBox(
                          width: 240,
                          height: 240,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 240,
                                height: 240,
                                child: CircularProgressIndicator(
                                  value: _progress,
                                  backgroundColor: AppColors.cardBackground,
                                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  strokeWidth: 10,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _timeString,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    _isBreak ? 'Mola' : 'Çalışma',
                                    style: GoogleFonts.inter(color: accentColor, fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),

                    // Controls (Play/Pause, Reset, Skip)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh_rounded, size: 36, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: _startPause,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
                              ],
                            ),
                            child: Icon(
                              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: _skip,
                          icon: const Icon(Icons.skip_next_rounded, size: 36, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Music Controls Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                          onPressed: _prevTrack,
                        ),
                        IconButton(
                          icon: Icon(
                            _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                            color: AppColors.secondary,
                            size: 36,
                          ),
                          onPressed: _toggleMusic,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                          onPressed: _nextTrack,
                        ),
                      ],
                    ),

                    // Volume control
                    Row(
                      children: [
                        const Icon(Icons.volume_down_rounded, color: AppColors.textSecondary, size: 18),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: AppColors.secondary,
                            inactiveColor: AppColors.cardBackground,
                            onChanged: _setVolume,
                          ),
                        ),
                        const Icon(Icons.volume_up_rounded, color: AppColors.textSecondary, size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
