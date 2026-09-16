import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/xp_gain_popup.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../data/pomodoro_session_model.dart';
import '../providers/pomodoro_provider.dart';
import '../../user/providers/user_provider.dart';
import 'session_history_sheet.dart';
import '../../quests/providers/quest_provider.dart';
import '../../../core/utils/sound_effects.dart';
import '../../combat/data/boss_monster.dart';
import '../../combat/data/boss_catalog.dart';
import '../../combat/domain/combat_calculator.dart';
import '../../combat/presentation/boss_painter.dart';
import 'widgets/zen_particles_widget.dart';
import 'widgets/zen_desk_widget.dart';
import 'widgets/boss_battle_arena.dart';
import 'widgets/boss_loot_dialog.dart';

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedWorkDuration = 25; // in minutes
  int _selectedBreakDuration = 5; // in minutes

  int _secondsLeft = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  Timer? _timer;

  // Odak Modu: 'battle' (Savaş Modu - Varsayılan) veya 'zen' (Zen Modu)
  String _selectedFocusMode = 'battle';
  BossMonster? _selectedBoss;
  DateTime? _sessionEndTime;
  bool _isAttacking = false;
  bool _isBossHit = false;

  String _selectedFocusArea = 'academic'; // 'academic', 'fitness', 'reading', 'coding'

  // Workout Coach state
  String _hiitState = 'ready'; // 'ready', 'countdown', 'work', 'rest', 'finished'
  int _hiitSecondsLeft = 40;
  int _hiitTotalWorkSeconds = 40;
  int _hiitTotalRestSeconds = 20;
  int _hiitCountdownSeconds = 3;
  bool _isHiitPaused = false;
  Timer? _hiitTimer;
  int _currentExerciseIndex = 0;
  int _completedSets = 0; // 0 to 3
  int _totalWorkoutSecondsElapsed = 0;

  // Exercise pool & user-selected routine
  final List<String> _selectedExerciseKeys = ['push_up', 'squat', 'plank'];

  final List<Map<String, dynamic>> _exerciseCatalog = [
    {
      'key': 'push_up',
      'name': 'Şınav (Push-up)',
      'desc': 'Göğüs, omuz ve arka kol kaslarını çalıştırır.',
      'icon': Icons.fitness_center_rounded,
      'tip': 'Gövdeni düz tut, nefes vererek yukarı bas! 💪',
      'calcTarget': (int level) => '${(8 + level * 2).clamp(8, 40)} Tekrar / 40s',
    },
    {
      'key': 'squat',
      'name': 'Squat',
      'desc': 'Bacak, kalça ve alt vücut gücünü artırır.',
      'icon': Icons.accessibility_new_rounded,
      'tip': 'Dizlerin parmak ucunu geçmesin, kalçanı geriye ver! 🦵',
      'calcTarget': (int level) => '${(12 + level * 3).clamp(12, 60)} Tekrar / 40s',
    },
    {
      'key': 'plank',
      'name': 'Plank',
      'desc': 'Karın ve çekirdek (core) dayanıklılığını artırır.',
      'icon': Icons.timer_rounded,
      'tip': 'Belini çökertme, karın kaslarını sıkarak sabit kal! 🔥',
      'calcTarget': (int level) => '${(20 + level * 5).clamp(20, 90)} Saniye / 40s',
    },
    {
      'key': 'lunge',
      'name': 'Lunge (Adımlama)',
      'desc': 'Bacak kuvveti, kalça ve denge koordinasyonunu artırır.',
      'icon': Icons.directions_walk_rounded,
      'tip': 'Ön dizin 90 derece bükülsün, gövdeni dik tut! 🚶',
      'calcTarget': (int level) => '${(10 + level * 2).clamp(10, 40)} Tekrar / 40s',
    },
    {
      'key': 'jumping_jack',
      'name': 'Jumping Jack',
      'desc': 'Nabzı yükselten dinamik kardiyo ve kondisyon hareketi.',
      'icon': Icons.flash_on_rounded,
      'tip': 'Kollarını ve bacaklarını ritmik şekilde açıp kapat! ⚡',
      'calcTarget': (int level) => '${(25 + level * 4).clamp(25, 80)} Tekrar / 40s',
    },
    {
      'key': 'crunch',
      'name': 'Mekik (Crunch)',
      'desc': 'Üst ve orta karın kaslarını hedefler.',
      'icon': Icons.self_improvement_rounded,
      'tip': 'Boynunu zorlamadan karın kaslarını sıkarak kalk! 🎯',
      'calcTarget': (int level) => '${(12 + level * 3).clamp(12, 50)} Tekrar / 40s',
    },
    {
      'key': 'mountain_climber',
      'name': 'Dağ Tırmanışı (Mountain Climber)',
      'desc': 'Karın kası aktivasyonu ve patlayıcı kardiyo.',
      'icon': Icons.terrain_rounded,
      'tip': 'Şınav pozisyonunda dizlerini sırayla göğsüne çek! 🏔️',
      'calcTarget': (int level) => '${(20 + level * 4).clamp(20, 70)} Tekrar / 40s',
    },
    {
      'key': 'dips',
      'name': 'Sandalye Dips',
      'desc': 'Arka kol (triceps) ve omuz kuvveti geliştirir.',
      'icon': Icons.chair_alt_rounded,
      'tip': 'Dirseklerini 90 derece bük ve güçlüce yukarı it! 🪑',
      'calcTarget': (int level) => '${(8 + level * 2).clamp(8, 35)} Tekrar / 40s',
    },
  ];

  List<Map<String, dynamic>> _getActiveExercises(int level) {
    return _selectedExerciseKeys.map((key) {
      final item = _exerciseCatalog.firstWhere(
        (e) => e['key'] == key,
        orElse: () => _exerciseCatalog.first,
      );
      final calcTarget = item['calcTarget'];
      String targetStr = '';
      if (calcTarget is Function) {
        try {
          targetStr = (calcTarget as dynamic)(level).toString();
        } catch (_) {
          targetStr = '${_hiitTotalWorkSeconds}s Egzersiz';
        }
      } else {
        targetStr = item['target']?.toString() ?? '${_hiitTotalWorkSeconds}s Egzersiz';
      }

      return {
        'key': item['key'],
        'name': item['name'] ?? 'Egzersiz',
        'target': targetStr,
        'desc': item['desc'] ?? '',
        'icon': item['icon'] ?? Icons.fitness_center_rounded,
        'tip': item['tip'] ?? '',
      };
    }).toList();
  }

  // Academic Assistant state
  List<Map<String, dynamic>>? _academicGoals;
  final TextEditingController _academicGoalController = TextEditingController();
  final TextEditingController _academicNoteController = TextEditingController();

  // Reading Assistant state
  final TextEditingController _readingStartPageController = TextEditingController(text: '1');
  final TextEditingController _readingEndPageController = TextEditingController(text: '20');
  final TextEditingController _readingNotesController = TextEditingController();

  // Coding Assistant state
  List<Map<String, dynamic>>? _codingTasks;
  final TextEditingController _codingTaskController = TextEditingController();
  final TextEditingController _codingNoteController = TextEditingController();
  String _codingSprintStage = 'Planlama'; // 'Planlama', 'Kodlama', 'Debug', 'Test'

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

  final List<Map<String, dynamic>> _playlist = const [
    {
      'name': 'Soft Lofi Beats ☕',
      'desc': 'Sakin Rhodes ve Piyano Akorları',
      'icon': Icons.coffee_rounded,
      'type': 'synth_lofi',
    },
    {
      'name': 'Huzurlu Yağmur Sesi 🌧️',
      'desc': 'Doğal Yağmur & Pembe Gürültü',
      'icon': Icons.water_drop_rounded,
      'type': 'synth_rain',
    },
    {
      'name': 'Zen Meditasyon (432Hz) 🧘',
      'desc': 'Tibet Kasesi & Derin Odak',
      'icon': Icons.self_improvement_rounded,
      'type': 'synth_zen',
    },
    {
      'name': 'Çam Ormanı Esintisi 🌲',
      'desc': 'Yumuşak Rüzgar Uğultusu',
      'icon': Icons.forest_rounded,
      'type': 'synth_breeze',
    },
  ];

  void _initAcademicGoals() {
    _academicGoals ??= [
      {'title': 'Konu tekrarı yap 📖', 'isCompleted': false},
      {'title': 'Pratik/Soru çözümü yap 📝', 'isCompleted': false},
      {'title': 'Yanlışlarını analiz et 🔍', 'isCompleted': false},
    ];
  }

  void _initCodingTasks() {
    _codingTasks ??= [
      {'title': 'Seans planını yap 🗺️', 'isCompleted': false},
      {'title': 'Kod yazımına başla 💻', 'isCompleted': false},
      {'title': 'Test et & Hataları gider 🐞', 'isCompleted': false},
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secondsLeft = _selectedWorkDuration * 60;
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Audio player sequential play listener
    _playerSubscription = _player.onPlayerComplete.listen((event) {
      _nextTrack();
    });

    _initAcademicGoals();
    _initCodingTasks();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString('pomodoro_focus_mode') ?? 'battle';
      if (mounted) {
        setState(() {
          _selectedFocusMode = (savedMode == 'zen') ? 'zen' : 'battle';
          _selectedBoss = BossCatalog.getBossForFocusArea(_selectedFocusArea);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedBoss = BossCatalog.getBossForFocusArea(_selectedFocusArea);
        });
      }
    }
  }

  Future<void> _changeFocusMode(String mode) async {
    if (_selectedFocusMode == mode) return;
    setState(() {
      _selectedFocusMode = mode;
    });
    if (_isRunning) {
      if (mode == 'zen') {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pomodoro_focus_mode', mode);
    } catch (_) {}
  }

  void _triggerHitEffect() {
    if (!mounted) return;
    setState(() {
      _isAttacking = true;
    });
    SoundEffects.playHit();

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        setState(() {
          _isBossHit = true;
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        setState(() {
          _isAttacking = false;
          _isBossHit = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _hiitTimer?.cancel();
    _pulseController.dispose();
    _playerSubscription?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_isImmersive) {
      _immersiveOverlay?.remove();
    }
    _academicGoalController.dispose();
    _academicNoteController.dispose();
    _readingStartPageController.dispose();
    _readingEndPageController.dispose();
    _readingNotesController.dispose();
    _codingTaskController.dispose();
    _codingNoteController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Wall-Clock Senkronizasyonu: Arka planda timer askıya alınması ve drift'e karşı kesin çözüm
      if (_isRunning && _sessionEndTime != null) {
        final now = DateTime.now();
        final diffSeconds = _sessionEndTime!.difference(now).inSeconds;
        final totalSeconds = (_isBreak ? _selectedBreakDuration : _selectedWorkDuration) * 60;

        if (diffSeconds <= 0) {
          _secondsLeft = 0;
          _timer?.cancel();
          _sessionEndTime = null;
          final user = ref.read(currentUserProvider).value;
          if (user != null) {
            _onTimerComplete(user.uid);
          }
        } else {
          _updateState(() {
            _secondsLeft = diffSeconds.clamp(0, totalSeconds);
          });
        }
      }

      // Zen modu tam ekranını geri yükle
      if (_isRunning && _selectedFocusMode == 'zen') {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }
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

  void _cancelSession() {
    _timer?.cancel();
    _sessionEndTime = null;
    if (_selectedFocusMode == 'zen') {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    final wasRunning = _isRunning;
    _updateState(() {
      _isRunning = false;
      _secondsLeft = _isBreak ? _selectedBreakDuration * 60 : _selectedWorkDuration * 60;
    });

    if (wasRunning && !_isBreak) {
      if (_selectedFocusMode == 'battle') {
        final boss = _selectedBoss ?? BossCatalog.getBossForFocusArea(_selectedFocusArea);
        _showBossEscapedDialog(boss);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.cardBackground,
            content: Text(
              '🌿 Seans durduruldu. Zihnini dinlendir ve dilediğinde tekrar başla.',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showBossEscapedDialog(BossMonster boss) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: boss.primaryColor.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: BossAvatar(
                boss: boss,
                hpPercentage: 1.0,
                size: 36,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Canavar Kaçtı!',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              boss.escapeQuote,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.tealAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ceza yok! Serin korunuyor. Dinlenip tekrar deneyebilirsin.',
                      style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _startPause() {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    if (_isRunning) {
      _timer?.cancel();
      _sessionEndTime = null;
      _updateState(() {
        _isRunning = false;
      });
      if (_selectedFocusMode == 'zen') {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } else {
      _sessionEndTime = DateTime.now().add(Duration(seconds: _secondsLeft));
      _updateState(() {
        _isRunning = true;
      });
      if (_selectedFocusMode == 'zen') {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
      
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 1) {
          _updateState(() {
            _secondsLeft--;
          });
          // Savaş Modu: Seans boyunca her 10 saniyede bir canavara vuruş darbesi
          if (_selectedFocusMode == 'battle' && !_isBreak && (_secondsLeft % 10 == 0)) {
            _triggerHitEffect();
          }
        } else {
          _timer?.cancel();
          _sessionEndTime = null;
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

      // FOC stat artışı (her iki modda da aynı şekilde artar)
      await ref.read(userRepositoryProvider).boostStat(uid, 'foc', 1);

      // Fetch active quests
      final dailyQuests = ref.read(dailyQuestsProvider).value ?? [];
      final weeklyQuests = ref.read(weeklyQuestsProvider).value ?? [];
      final customQuests = ref.read(customQuestsProvider).value ?? [];

      // 1. Increment standard Pomodoro completion daily quests
      final seansQuests = dailyQuests.where((q) => q.unit == 'seans' && !q.isCompleted);
      for (final q in seansQuests) {
        await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, 1);
      }

      // 2. Focus area specific actions
      if (_selectedFocusArea == 'academic') {
        final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
            .where((q) => q.unit == 'dk' && !q.isCompleted && (q.statBoost == 'knowledge' || q.title.toLowerCase().contains('ders') || q.title.toLowerCase().contains('çalışma')));
        for (final q in targetQuests) {
          await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, _selectedWorkDuration);
        }
      } else if (_selectedFocusArea == 'coding') {
        final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
            .where((q) => q.unit == 'dk' && !q.isCompleted && (q.statBoost == 'focus' || q.title.toLowerCase().contains('kod') || q.title.toLowerCase().contains('yazılım')));
        for (final q in targetQuests) {
          await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, _selectedWorkDuration);
        }
      } else if (_selectedFocusArea == 'reading') {
        await _showReadingPageDialog(uid, xpEarned);
      }

      // MOD BAZLI ÖDÜL VE KUTLAMA
      if (_selectedFocusMode == 'battle') {
        final boss = _selectedBoss ?? BossCatalog.getBossForFocusArea(_selectedFocusArea);
        final goldEarned = CombatCalculator.rollGoldReward(boss.minGold, boss.maxGold);
        final droppedChest = CombatCalculator.rollChestDrop(boss.chestDropChances);

        // Firestore güncellemeleri
        await ref.read(userRepositoryProvider).addGold(uid, goldEarned);
        if (droppedChest != null) {
          await ref.read(userRepositoryProvider).addChest(uid, droppedChest);
        }

        SoundEffects.playVictory();
        if (mounted) {
          await BossLootDialog.show(
            context,
            boss: boss,
            xpEarned: xpEarned,
            goldEarned: goldEarned,
            droppedChestRarity: droppedChest,
          );
        }
      } else {
        // Zen Modu
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SoundEffects.playVictory();
        if (mounted) {
          XpGainPopup.show(context, xp: xpEarned, statName: 'foc', statAmount: 1);
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
    int prefilledPages = 0;
    try {
      final start = int.tryParse(_readingStartPageController.text.trim()) ?? 0;
      final end = int.tryParse(_readingEndPageController.text.trim()) ?? 0;
      if (end > start) {
        prefilledPages = end - start;
      }
    } catch (_) {}

    final controller = TextEditingController(
      text: prefilledPages > 0 ? prefilledPages.toString() : '',
    );
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



  Widget _buildFocusModeSegmentedSwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF131826),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // ⚔️ Savaş Modu
          Expanded(
            child: InkWell(
              onTap: _isRunning ? null : () => _changeFocusMode('battle'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _selectedFocusMode == 'battle'
                      ? const LinearGradient(
                          colors: [Color(0xFFD32F2F), Color(0xFFFF5722)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedFocusMode == 'battle'
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⚔️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Savaş Modu',
                      style: GoogleFonts.inter(
                        color: _selectedFocusMode == 'battle' ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🌌 Zen Modu
          Expanded(
            child: InkWell(
              onTap: _isRunning ? null : () => _changeFocusMode('zen'),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: _selectedFocusMode == 'zen'
                      ? const LinearGradient(
                          colors: [Color(0xFF303F9F), Color(0xFF0097A7)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedFocusMode == 'zen'
                      ? [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: 0.3),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌌', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      'Zen Modu',
                      style: GoogleFonts.inter(
                        color: _selectedFocusMode == 'zen' ? Colors.white : Colors.white60,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startHiitWorkout(String uid) {
    _hiitTimer?.cancel();
    setState(() {
      _hiitState = 'countdown';
      _hiitCountdownSeconds = 3;
      _isHiitPaused = false;
      _currentExerciseIndex = 0;
      _completedSets = 0;
      _totalWorkoutSecondsElapsed = 0;
    });

    _hiitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isHiitPaused) return;

      SoundEffects.playTick();

      if (_hiitCountdownSeconds > 1) {
        setState(() {
          _hiitCountdownSeconds--;
        });
      } else {
        timer.cancel();
        _startHiitWorkPhase(uid);
      }
    });
  }

  void _startHiitWorkPhase(String uid) {
    _hiitTimer?.cancel();
    SoundEffects.playWorkStart();
    setState(() {
      _hiitState = 'work';
      _hiitSecondsLeft = _hiitTotalWorkSeconds;
      _isHiitPaused = false;
    });

    _hiitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isHiitPaused) return;

      setState(() {
        _totalWorkoutSecondsElapsed++;
      });

      if (_hiitSecondsLeft > 1) {
        setState(() {
          _hiitSecondsLeft--;
        });
      } else {
        timer.cancel();
        _onHiitSetCompleted(uid);
      }
    });
  }

  void _onHiitSetCompleted(String uid) async {
    _hiitTimer?.cancel();

    final dailyQuests = ref.read(dailyQuestsProvider).value ?? [];
    final weeklyQuests = ref.read(weeklyQuestsProvider).value ?? [];
    final customQuests = ref.read(customQuestsProvider).value ?? [];

    // Set bazlı görevleri ilerlet
    final targetQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
        .where((q) => q.unit == 'set' && !q.isCompleted);
    for (final q in targetQuests) {
      await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, 1);
    }

    // Dakika bazlı spor görevlerini de ilerlet
    final minuteQuests = [...dailyQuests, ...weeklyQuests, ...customQuests]
        .where((q) => q.unit == 'dk' && (q.title.toLowerCase().contains('spor') || q.title.toLowerCase().contains('fitness')) && !q.isCompleted);
    for (final q in minuteQuests) {
      await ref.read(questRepositoryProvider).incrementQuestProgress(uid, q.id, 1);
    }

    // XP ve stat boost
    await ref.read(userRepositoryProvider).addXp(uid, 15);
    await ref.read(userRepositoryProvider).boostStat(uid, 'strength', 1);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Set Tamamlandı! +15 XP ve +1 GÜÇ kazanıldı.'),
          backgroundColor: AppColors.statStrength,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _completedSets++;
    });

    if (_completedSets >= 3) {
      if (_currentExerciseIndex < _selectedExerciseKeys.length - 1) {
        setState(() {
          _currentExerciseIndex++;
          _completedSets = 0;
        });
        _startHiitRestPhase(uid);
      } else {
        _onHiitWorkoutFinished(uid);
      }
    } else {
      _startHiitRestPhase(uid);
    }
  }

  void _startHiitRestPhase(String uid) {
    _hiitTimer?.cancel();
    SoundEffects.playRestStart();
    setState(() {
      _hiitState = 'rest';
      _hiitSecondsLeft = _hiitTotalRestSeconds;
      _isHiitPaused = false;
    });

    _hiitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isHiitPaused) return;

      if (_hiitSecondsLeft > 1) {
        setState(() {
          _hiitSecondsLeft--;
        });
      } else {
        timer.cancel();
        _startHiitWorkPhase(uid);
      }
    });
  }

  void _skipHiitRest(String uid) {
    _startHiitWorkPhase(uid);
  }

  void _toggleHiitPause() {
    setState(() {
      _isHiitPaused = !_isHiitPaused;
    });
  }

  void _resetHiitWorkout() {
    _hiitTimer?.cancel();
    setState(() {
      _hiitState = 'ready';
      _currentExerciseIndex = 0;
      _completedSets = 0;
      _isHiitPaused = false;
      _hiitSecondsLeft = _hiitTotalWorkSeconds;
    });
  }

  Future<void> _onHiitWorkoutFinished(String uid) async {
    _hiitTimer?.cancel();
    SoundEffects.playVictory();

    setState(() {
      _hiitState = 'finished';
    });

    final totalSecs = _totalWorkoutSecondsElapsed;
    final totalMinutes = (totalSecs / 60.0).clamp(0.5, 90.0);
    final totalSetsDone = _selectedExerciseKeys.length * 3;
    final xpEarned = ((totalMinutes * 16) + (totalSetsDone * 7)).round().clamp(40, 250);
    final estimatedCalories = (totalMinutes * 8.5).round().clamp(15, 600);
    final strengthGain = totalSetsDone >= 6 ? 4 : 2;

    final ended = DateTime.now();
    final started = ended.subtract(Duration(seconds: totalSecs > 0 ? totalSecs : 60));

    final session = PomodoroSessionModel(
      id: '',
      startedAt: started,
      endedAt: ended,
      workMinutes: totalMinutes.ceil().clamp(1, 60),
      breakMinutes: 5,
      xpEarned: xpEarned,
      completed: true,
    );

    await ref.read(pomodoroRepositoryProvider).saveSession(uid, session);
    await ref.read(userRepositoryProvider).addXp(uid, xpEarned);
    await ref.read(userRepositoryProvider).boostStat(uid, 'strength', strengthGain);

    if (mounted) {
      _showWorkoutSummaryDialog(
        totalSeconds: totalSecs,
        totalSets: totalSetsDone,
        exerciseCount: _selectedExerciseKeys.length,
        xpEarned: xpEarned,
        strengthGain: strengthGain,
        estimatedCalories: estimatedCalories,
      );
    }
  }

  void _showWorkoutSummaryDialog({
    required int totalSeconds,
    required int totalSets,
    required int exerciseCount,
    required int xpEarned,
    required int strengthGain,
    required int estimatedCalories,
  }) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.statStrength.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.statStrength, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.statStrength.withValues(alpha: 0.5),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  'ANTRENMAN TAMAMLANDI!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Harika bir disiplin gösterdin! İşte sonuçların:',
                  style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.timer_outlined,
                        label: 'Süre',
                        value: timeStr,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.repeat_rounded,
                        label: 'Setler',
                        value: '$totalSets Set',
                        color: AppColors.statStrength,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.local_fire_department_rounded,
                        label: 'Kalori',
                        value: '~$estimatedCalories kcal',
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryMetric(
                        icon: Icons.fitness_center_rounded,
                        label: 'Egzersiz',
                        value: '$exerciseCount Hareket',
                        color: AppColors.statEnergy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.gold, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            '+$xpEarned XP & Altın',
                            style: GoogleFonts.inter(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 24, color: Colors.white12),
                      Row(
                        children: [
                          const Icon(Icons.fitness_center_rounded, color: AppColors.statStrength, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+$strengthGain GÜÇ',
                            style: GoogleFonts.inter(
                              color: AppColors.statStrength,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      _resetHiitWorkout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statStrength,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: Text(
                      'Harika İştin! 🚀',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
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
                      final newArea = area['id'] as String;
                      _selectedFocusArea = newArea;
                      _selectedBoss = BossCatalog.getBossForFocusArea(newArea);
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
    final exercises = _getActiveExercises(level);
    final currentExercise = exercises.isNotEmpty
        ? exercises[_currentExerciseIndex.clamp(0, exercises.length - 1)]
        : {
            'name': 'Egzersiz',
            'target': '40s',
            'desc': '',
            'icon': Icons.fitness_center_rounded,
            'tip': '',
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hiitState == 'work'
              ? AppColors.statStrength.withValues(alpha: 0.5)
              : (_hiitState == 'rest'
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : AppColors.statStrength.withValues(alpha: 0.2)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_hiitState == 'work' ? AppColors.statStrength : AppColors.secondary).withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.statStrength.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.statStrength, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Antrenman Koçu',
                    style: GoogleFonts.inter(
                      color: AppColors.statStrength,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      SoundEffects.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                      color: SoundEffects.isMuted ? Colors.white38 : AppColors.statStrength,
                      size: 20,
                    ),
                    tooltip: SoundEffects.isMuted ? 'Sesi Aç' : 'Sesi Kapat',
                    onPressed: () {
                      setState(() {
                        SoundEffects.toggleMute();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.statStrength.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _hiitState == 'ready'
                          ? '${exercises.length} Egzersiz • 3 Set'
                          : (_hiitState == 'finished'
                              ? 'Tamamlandı 🏆'
                              : 'Egzersiz ${_currentExerciseIndex + 1}/${exercises.length} • Set ${_completedSets + 1}/3'),
                      style: GoogleFonts.inter(
                        color: AppColors.statStrength,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- DURUM 1: HAZIRLIK / BAŞLANGIÇ EKRANI ---
          if (_hiitState == 'ready') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.15)),
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => _showExerciseSelectionSheet(context, level),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.statStrength.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🔥 ${_hiitTotalWorkSeconds}s Egzersiz',
                              style: GoogleFonts.inter(color: AppColors.statStrength, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('➔', style: TextStyle(color: Colors.white54)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '☕ ${_hiitTotalRestSeconds}s Mola',
                              style: GoogleFonts.inter(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.tune_rounded, size: 16, color: AppColors.statStrength),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Süreleri ve hareket havuzunu özelleştirmek için dokun. Başladığında telefon sana koçluk eder.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Egzersiz Listesi Başlığı & Düzenle Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Antrenman Programı (${exercises.length} Hareket)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: AppColors.statStrength.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showExerciseSelectionSheet(context, level),
                  icon: const Icon(Icons.tune_rounded, color: AppColors.statStrength, size: 16),
                  label: Text(
                    'Düzenle',
                    style: GoogleFonts.inter(
                      color: AppColors.statStrength,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Egzersiz Listesi Önizleme
            ...List.generate(exercises.length, (idx) {
              final ex = exercises[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(ex['icon'] as IconData, color: AppColors.statStrength, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex['name'] as String,
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ex['target'] as String,
                            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle_outline, color: AppColors.statStrength, size: 18),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Başlat Butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statStrength,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  shadowColor: AppColors.statStrength.withValues(alpha: 0.4),
                ),
                onPressed: () => _startHiitWorkout(uid),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                label: Text(
                  'Antrenmanı Başlat 🔥',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ]

          // --- DURUM 2: 3, 2, 1 GERİ SAYIM ---
          else if (_hiitState == 'countdown') ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text(
                    'HAZIRLAN!',
                    style: GoogleFonts.inter(
                      color: AppColors.statStrength,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 110,
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.statStrength.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.statStrength, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statStrength.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Text(
                      '$_hiitCountdownSeconds',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'İlk Hareket: ${currentExercise['name']}',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentExercise['tip'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ]

          // --- DURUM 3: ÇALIŞMA (WORK) AŞAMASI (40 SANİYE) ---
          else if (_hiitState == 'work') ...[
            Column(
              children: [
                // Durum Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.statStrength.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fitness_center_rounded, color: AppColors.statStrength, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ÇALIŞMA AŞAMASI • HEDEFİ ZORLA!',
                        style: GoogleFonts.inter(
                          color: AppColors.statStrength,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dairesel Geri Sayım Sayacı
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        value: (_hiitSecondsLeft / _hiitTotalWorkSeconds).clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statStrength),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '00:${_hiitSecondsLeft.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _isHiitPaused ? 'DURAKLATILDI' : 'SANİYE',
                          style: GoogleFonts.inter(
                            color: _isHiitPaused ? Colors.amber : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Egzersiz Bilgi Kartı
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.statStrength.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(currentExercise['icon'] as IconData, color: AppColors.statStrength, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentExercise['name'] as String,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              currentExercise['tip'] as String,
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Set İlerleme Çubukları
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final isDone = i < _completedSets;
                    final isCurrent = i == _completedSets;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 50,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.statStrength
                            : (isCurrent ? AppColors.statStrength.withValues(alpha: 0.5) : AppColors.background),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isCurrent ? AppColors.statStrength : Colors.transparent,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Kontrol Butonları (Erken geçiş kaldırıldı, sadece duraklat ve antrenmanı bitir)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _toggleHiitPause,
                        icon: Icon(_isHiitPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        label: Text(_isHiitPaused ? 'Devam Et' : 'Duraklat'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent.shade100,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _resetHiitWorkout,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: Text(
                          'Antrenmanı Bitir',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]

          // --- DURUM 4: DİNLENME (REST) AŞAMASI (20 SANİYE) ---
          else if (_hiitState == 'rest') ...[
            Column(
              children: [
                // Durum Rozeti
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.coffee_rounded, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'DİNLENME AŞAMASI • NEFES AL & SU İÇ',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dinlenme Sayacı
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CircularProgressIndicator(
                        value: (_hiitSecondsLeft / _hiitTotalRestSeconds).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '00:${_hiitSecondsLeft.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'MOLA',
                          style: GoogleFonts.inter(
                            color: AppColors.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sonraki Egzersiz Önizleme Kartı
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          exercises[_currentExerciseIndex]['icon'] as IconData,
                          color: AppColors.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sıradaki Set: ${exercises[_currentExerciseIndex]['name']}',
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Set ${_completedSets + 1}/3 için hazırlanıyorsun...',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Molayı Geç Butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _skipHiitRest(uid),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(
                      'Molayı Geç ve Başla ➔',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ]

          // --- DURUM 5: TAMAMLANDI EKRANI ---
          else if (_hiitState == 'finished') ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    'HARİKA İŞ! ANTRENMAN BİTTİ',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bugün sınırlarını zorladın ve tüm turları tamamladın!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Kazanılan Ödüller
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.statStrength.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('⚡ +75 XP', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Deneyim', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white12),
                        Column(
                          children: [
                            const Text('💪 +3 GÜÇ', style: TextStyle(color: AppColors.statStrength, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Stat Gelişimi', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Container(width: 1, height: 30, color: Colors.white12),
                        Column(
                          children: [
                            Text(
                              '⏱️ ${_totalWorkoutSecondsElapsed ~/ 60 + 1} dk',
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Antrenman', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Yeniden Başlat Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statStrength,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _resetHiitWorkout,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(
                        'Yeni Antrenman Başlat',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExerciseSelectionSheet(BuildContext context, int level) {
    const workSecondsOptions = [20, 30, 40, 45, 60];
    const restSecondsOptions = [10, 15, 20, 30, 45];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setSheetState) {
            return Container(
              height: MediaQuery.of(sheetContext).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Antrenman Ayarları & Hareketler',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Süreleri belirle, hareket ekle veya çıkar (${_selectedExerciseKeys.length} seçili)',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Süre Ayarları Paneli
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.statStrength),
                            const SizedBox(width: 6),
                            Text(
                              'Çalışma Süresi: ${_hiitTotalWorkSeconds}s',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: workSecondsOptions.map((sec) {
                              final isSelected = _hiitTotalWorkSeconds == sec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${sec}s'),
                                  selected: isSelected,
                                  selectedColor: AppColors.statStrength,
                                  backgroundColor: AppColors.cardBackground,
                                  labelStyle: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() {
                                        _hiitTotalWorkSeconds = sec;
                                        if (_hiitState == 'ready') _hiitSecondsLeft = sec;
                                      });
                                      setState(() {
                                        _hiitTotalWorkSeconds = sec;
                                        if (_hiitState == 'ready') _hiitSecondsLeft = sec;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.coffee_outlined, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            Text(
                              'Mola / Dinlenme Süresi: ${_hiitTotalRestSeconds}s',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: restSecondsOptions.map((sec) {
                              final isSelected = _hiitTotalRestSeconds == sec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${sec}s'),
                                  selected: isSelected,
                                  selectedColor: AppColors.secondary,
                                  backgroundColor: AppColors.cardBackground,
                                  labelStyle: GoogleFonts.inter(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 11,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() {
                                        _hiitTotalRestSeconds = sec;
                                      });
                                      setState(() {
                                        _hiitTotalRestSeconds = sec;
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hareket Havuzu Başlığı & Yeni Hareket Ekle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hareket Havuzu',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          backgroundColor: AppColors.statStrength.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showAddCustomExerciseDialog(sheetContext, setSheetState),
                        icon: const Icon(Icons.add, color: AppColors.statStrength, size: 16),
                        label: Text(
                          'Yeni Hareket Ekle',
                          style: GoogleFonts.inter(
                            color: AppColors.statStrength,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Egzersiz Listesi
                  Expanded(
                    child: ListView.separated(
                      itemCount: _exerciseCatalog.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final item = _exerciseCatalog[idx];
                        final key = item['key'] as String;
                        final isSelected = _selectedExerciseKeys.contains(key);
                        final isCustom = key.startsWith('custom_');

                        final calcTarget = item['calcTarget'];
                        String targetStr = '';
                        if (calcTarget is Function) {
                          try {
                            targetStr = (calcTarget as dynamic)(level).toString();
                          } catch (_) {
                            targetStr = '${_hiitTotalWorkSeconds}s Egzersiz';
                          }
                        } else {
                          targetStr = item['target']?.toString() ?? '${_hiitTotalWorkSeconds}s Egzersiz';
                        }

                        return GestureDetector(
                          onTap: () {
                            if (isSelected) {
                              if (_selectedExerciseKeys.length <= 1) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('En az 1 egzersiz seçili olmalıdır!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() {
                                _selectedExerciseKeys.remove(key);
                              });
                            } else {
                              setSheetState(() {
                                _selectedExerciseKeys.add(key);
                              });
                            }
                            setState(() {
                              if (_currentExerciseIndex >= _selectedExerciseKeys.length) {
                                _currentExerciseIndex = 0;
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.statStrength.withValues(alpha: 0.12)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.statStrength
                                    : AppColors.primary.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.statStrength.withValues(alpha: 0.2)
                                        : Colors.white10,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData? ?? Icons.fitness_center_rounded,
                                    color: isSelected ? AppColors.statStrength : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['name'] as String? ?? 'Egzersiz',
                                              style: GoogleFonts.inter(
                                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          if (isCustom)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Özel',
                                                style: GoogleFonts.inter(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        targetStr,
                                        style: GoogleFonts.inter(
                                          color: isSelected ? AppColors.statStrength : AppColors.textSecondary.withValues(alpha: 0.7),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if ((item['desc'] ?? '').toString().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item['desc'] as String,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isCustom)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                    onPressed: () {
                                      if (_selectedExerciseKeys.length <= 1 && isSelected) {
                                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                                          const SnackBar(
                                            content: Text('En az 1 egzersiz seçili kalmalıdır!'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                        return;
                                      }
                                      setSheetState(() {
                                        _selectedExerciseKeys.remove(key);
                                        _exerciseCatalog.removeWhere((e) => e['key'] == key);
                                      });
                                      setState(() {
                                        if (_currentExerciseIndex >= _selectedExerciseKeys.length) {
                                          _currentExerciseIndex = 0;
                                        }
                                      });
                                    },
                                  ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.statStrength : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? AppColors.statStrength : Colors.white30,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statStrength,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(
                        'Ayarları & Programı Kaydet (${_selectedExerciseKeys.length} Hareket)',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCustomExerciseDialog(BuildContext parentContext, StateSetter setSheetState) {
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '15 Tekrar');
    final tipController = TextEditingController();
    IconData selectedIcon = Icons.fitness_center_rounded;

    final List<IconData> iconOptions = [
      Icons.fitness_center_rounded,
      Icons.flash_on_rounded,
      Icons.directions_run_rounded,
      Icons.sports_gymnastics_rounded,
      Icons.timer_rounded,
      Icons.self_improvement_rounded,
      Icons.favorite_rounded,
      Icons.sports_mma_rounded,
    ];

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.statStrength.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_task_rounded, color: AppColors.statStrength, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Yeni Hareket Ekle',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hareket Adı', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Örn: Barfiks, Burpee, İp Atlama...',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Hedef / Tekrar / Açıklama', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: targetController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Örn: 15 Tekrar veya 50 Zıplama',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Koç İpucu (Opsiyonel)', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tipController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Örn: Sırtını dik tut ve ritmini bozma! 💪',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('İkon Seç', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: iconOptions.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.statStrength.withValues(alpha: 0.25) : AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.statStrength : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(icon, color: isSelected ? AppColors.statStrength : AppColors.textSecondary, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('İptal', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statStrength,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final target = targetController.text.trim().isNotEmpty ? targetController.text.trim() : 'Maksimum Tekrar';
                    final tip = tipController.text.trim().isNotEmpty ? tipController.text.trim() : 'Formunu koru ve pes etme! 🔥';
                    final customKey = 'custom_${DateTime.now().millisecondsSinceEpoch}';

                    final newExercise = {
                      'key': customKey,
                      'name': name,
                      'desc': 'Özel Antrenman Hareketi',
                      'icon': selectedIcon,
                      'tip': tip,
                      'calcTarget': (int level) => '$target / ${_hiitTotalWorkSeconds}s',
                    };

                    setState(() {
                      _exerciseCatalog.add(newExercise);
                      _selectedExerciseKeys.add(customKey);
                    });
                    setSheetState(() {});

                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(
                        content: Text('🔥 "$name" hareketi başarıyla eklendi ve seçildi!'),
                        backgroundColor: AppColors.statStrength,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text('Ekle', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);

      final type = track['type'] as String?;
      Uint8List bytes;
      if (type == 'synth_rain') {
        bytes = SoundEffects.getRainWav();
      } else if (type == 'synth_zen') {
        bytes = SoundEffects.getZenMeditationWav();
      } else if (type == 'synth_breeze') {
        bytes = SoundEffects.getForestBreezeWav();
      } else {
        bytes = SoundEffects.getLofiBeatsWav();
      }

      await _player.play(BytesSource(bytes));
      _updateState(() {
        _isMusicPlaying = true;
      });
    } catch (_) {
      try {
        await _player.play(BytesSource(SoundEffects.getLofiBeatsWav()));
        _updateState(() {
          _isMusicPlaying = true;
        });
      } catch (_) {}
    }
  }

  Future<void> _selectTrack(int index) async {
    _updateState(() {
      _currentTrackIndex = index;
    });
    await _playCurrentTrack();
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

  Widget _buildCategoryAssistantCard() {
    switch (_selectedFocusArea) {
      case 'academic':
        return _buildAcademicAssistant();
      case 'reading':
        return _buildReadingAssistant();
      case 'coding':
        return _buildCodingAssistant();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAcademicAssistant() {
    _initAcademicGoals();
    final accentColor = AppColors.statKnowledge;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderColor: accentColor,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_rounded, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Akademik Çalışma Planı',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bu odak seansındaki hedeflerini belirle ve tamamla:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),

          // Goals Checklist
          if (_academicGoals != null)
            ...List.generate(_academicGoals!.length, (index) {
              final goal = _academicGoals![index];
              final isCompleted = goal['isCompleted'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: isCompleted,
                      activeColor: accentColor,
                      checkColor: Colors.white,
                      side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                      onChanged: (val) {
                        setState(() {
                          goal['isCompleted'] = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        goal['title'] as String,
                        style: GoogleFonts.inter(
                          color: isCompleted ? AppColors.textSecondary : Colors.white,
                          fontSize: 13,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _academicGoals!.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 4),
          // Add goal field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _academicGoalController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Yeni hedef ekle...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _academicGoals!.add({'title': val.trim(), 'isCompleted': false});
                        _academicGoalController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.add, color: accentColor, size: 20),
                onPressed: () {
                  final val = _academicGoalController.text;
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _academicGoals!.add({'title': val.trim(), 'isCompleted': false});
                      _academicGoalController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Study Notes Text Field
          Text(
            'Hızlı Çalışma Notları / Formüller:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _academicNoteController,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Formülleri, önemli terimleri veya notları buraya karala...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingAssistant() {
    final accentColor = AppColors.primary; // Purple

    // Calculate pages automatically
    int totalPages = 0;
    try {
      final start = int.tryParse(_readingStartPageController.text.trim()) ?? 0;
      final end = int.tryParse(_readingEndPageController.text.trim()) ?? 0;
      if (end > start) {
        totalPages = end - start;
      }
    } catch (_) {}

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderColor: accentColor,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Kitap Okuma Günlüğü',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Şu anki okuma oturumunun detaylarını gir:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Start Page and End Page Inputs Side by Side
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Başlangıç Sayfası',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _readingStartPageController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'örn. 1',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hedef Sayfa',
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _readingEndPageController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'örn. 20',
                        hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: accentColor),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (totalPages > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Hedeflenen Okuma: $totalPages sayfa (+${totalPages * 3} XP)',
                    style: GoogleFonts.inter(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Reading notes and quotes
          Text(
            'Beğenilen Alıntılar / Günlük Çıkarım:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _readingNotesController,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Okurken aldığın notları veya günün çıkarımını yaz...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodingAssistant() {
    _initCodingTasks();
    final accentColor = AppColors.statFocus; // Cyan

    final stages = ['Planlama', 'Kodlama', 'Hata Ayıklama', 'Test'];

    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderColor: accentColor,
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.code_rounded, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Yazılım Geliştirici Sprint Masası',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sprint Stage Selector
          Text(
            'Sprint Aşaması:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stages.map((stage) {
              final isSelected = _codingSprintStage == stage;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _codingSprintStage = stage;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? accentColor.withValues(alpha: 0.2) : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accentColor : AppColors.primary.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        stage,
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          Text(
            'Sprint Görev & Bug Listesi:',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Coding Tasks Checklist
          if (_codingTasks != null)
            ...List.generate(_codingTasks!.length, (index) {
              final task = _codingTasks![index];
              final isCompleted = task['isCompleted'] as bool;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: isCompleted,
                      activeColor: accentColor,
                      checkColor: Colors.white,
                      side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                      onChanged: (val) {
                        setState(() {
                          task['isCompleted'] = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text(
                        task['title'] as String,
                        style: GoogleFonts.inter(
                          color: isCompleted ? AppColors.textSecondary : Colors.white,
                          fontSize: 13,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _codingTasks!.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 4),
          // Add coding task field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codingTaskController,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Yeni görev veya bug ekle...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      setState(() {
                        _codingTasks!.add({'title': val.trim(), 'isCompleted': false});
                        _codingTaskController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(Icons.add, color: accentColor, size: 20),
                onPressed: () {
                  final val = _codingTaskController.text;
                  if (val.trim().isNotEmpty) {
                    setState(() {
                      _codingTasks!.add({'title': val.trim(), 'isCompleted': false});
                      _codingTaskController.clear();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Code Scratchpad
          Text(
            'Kod Karalama Defteri (TODOs, Fikirler):',
            style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _codingNoteController,
            maxLines: 2,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Değişken adları, regex yapıları veya todo hatırlatıcılarını yaz...',
              hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 12),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.all(10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChips() {
    return Container(
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
    );
  }

  Widget _buildMusicControlsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _playlist[_currentTrackIndex]['icon'] as IconData? ?? Icons.music_note_rounded,
                    color: _isMusicPlaying ? AppColors.secondary : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _playlist[_currentTrackIndex]['name'] as String,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _isMusicPlaying ? 'Çalıyor (Kesintisiz Döngü)' : 'Duraklatıldı',
                        style: GoogleFonts.inter(
                          color: _isMusicPlaying ? AppColors.secondary : AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 22),
                    onPressed: _prevTrack,
                    tooltip: 'Önceki Parça',
                  ),
                  IconButton(
                    icon: Icon(
                      _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    onPressed: _toggleMusic,
                    tooltip: _isMusicPlaying ? 'Durdur' : 'Çal',
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 22),
                    onPressed: _nextTrack,
                    tooltip: 'Sonraki Parça',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_playlist.length, (i) {
                final track = _playlist[i];
                final isSel = _currentTrackIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    showCheckmark: false,
                    avatar: Icon(
                      track['icon'] as IconData? ?? Icons.music_note_rounded,
                      size: 14,
                      color: isSel ? Colors.white : AppColors.textSecondary,
                    ),
                    label: Text(track['name'] as String),
                    selected: isSel,
                    onSelected: (_) => _selectTrack(i),
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.secondary.withValues(alpha: 0.35),
                    labelStyle: GoogleFonts.inter(
                      color: isSel ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                    side: BorderSide(
                      color: isSel ? AppColors.secondary : Colors.white10,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }

  // --- ZEN MODU: Müzik Seçici Modalı ---
  void _showZenMusicPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎵 Zen Ambiyans Müziği',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: Icon(
                          _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: AppColors.secondary,
                          size: 28,
                        ),
                        onPressed: () {
                          _toggleMusic();
                          setSheetState(() {});
                        },
                        tooltip: _isMusicPlaying ? 'Durdur' : 'Çal',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_playlist.length, (i) {
                    final track = _playlist[i];
                    final isSel = _currentTrackIndex == i;
                    return InkWell(
                      onTap: () {
                        _selectTrack(i);
                        setSheetState(() {});
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.secondary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel ? AppColors.secondary : Colors.white10,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              track['icon'] as IconData? ?? Icons.music_note_rounded,
                              color: isSel ? AppColors.secondary : Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track['name'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    track['desc'] as String? ?? '',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel)
                              Icon(
                                _isMusicPlaying ? Icons.equalizer_rounded : Icons.check_circle_rounded,
                                color: AppColors.secondary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 16),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.secondary,
                          inactiveColor: Colors.white12,
                          onChanged: (v) {
                            _setVolume(v);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 16),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- ZEN MODU: Tam Ekran Çalışma Görünümü ---
  Widget _buildZenRunningFullscreen(dynamic user, Color accentColor) {
    return Material(
      color: const Color(0xFF0C101A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Arka Plan Partikülleri (Seçili ambiyans sesine duyarlı & 25 partikül optimize)
          Positioned.fill(
            child: ZenParticlesWidget(
              trackType: _playlist[_currentTrackIndex]['type'] as String?,
            ),
          ),

          // 2. Üst Bar: Parça bilgisi, müzik durdurma/değiştirme & Tam ekrandan ayrılma
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Şarkı seçici pill
                  InkWell(
                    onTap: () => _showZenMusicPicker(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _playlist[_currentTrackIndex]['icon'] as IconData? ?? Icons.music_note_rounded,
                            color: _isMusicPlaying ? accentColor : Colors.white38,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _playlist[_currentTrackIndex]['name'] as String,
                            style: GoogleFonts.inter(
                              color: _isMusicPlaying ? Colors.white : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.expand_more_rounded, color: Colors.white54, size: 16),
                        ],
                      ),
                    ),
                  ),

                  // Müzik Kontrolleri & Tam Ekran Çıkışı
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Önceki Müzik',
                        onPressed: _prevTrack,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: accentColor,
                          size: 28,
                        ),
                        tooltip: _isMusicPlaying ? 'Müziği Durdur' : 'Müziği Çal',
                        onPressed: _toggleMusic,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 22),
                        tooltip: 'Sonraki Müzik',
                        onPressed: _nextTrack,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white54, size: 26),
                        tooltip: 'Normal Görünüme Dön',
                        onPressed: () {
                          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                          _updateState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Merkez: Karakter, Saat, İnce Bar ve Müzik Kontrolleri
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ZenDeskWidget(
                  equippedItems: user.equippedItems,
                  isWorking: true,
                ),
                const SizedBox(height: 16),

                // Seans Durumu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _isBreak ? '☕ MOLA ZAMANI' : '🌌 ZEN ODAK SEANSI',
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Büyük Minimalist Dijital Saat
                Text(
                  _timeString,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: accentColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // İnce Progress Bar
                SizedBox(
                  width: 250,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Minimal Sayaç Kontrolleri
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Duraklat / Devam Et
                    GestureDetector(
                      onTap: _startPause,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.2),
                          border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
                        ),
                        child: Icon(
                          _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // Seansı Bitir / Kaç
                    GestureDetector(
                      onTap: _cancelSession,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Zen Modu Hızlı Müzik Çalar Barı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showZenMusicPicker(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _playlist[_currentTrackIndex]['icon'] as IconData? ?? Icons.music_note_rounded,
                              color: _isMusicPlaying ? accentColor : Colors.white38,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _playlist[_currentTrackIndex]['name'] as String,
                              style: GoogleFonts.inter(
                                color: _isMusicPlaying ? Colors.white : Colors.white60,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 14, color: Colors.white12),
                      const SizedBox(width: 2),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Önceki Parça',
                        onPressed: _prevTrack,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          _isMusicPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                          color: accentColor,
                          size: 24,
                        ),
                        tooltip: _isMusicPlaying ? 'Durdur' : 'Çal',
                        onPressed: _toggleMusic,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Sonraki Parça',
                        onPressed: _nextTrack,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ZEN MODU: Bekleme Görünümü ---
  Widget _buildZenIdleView(dynamic user, Color accentColor) {
    return Column(
      children: [
        ZenDeskWidget(
          equippedItems: user.equippedItems,
          isWorking: false,
        ),
        const SizedBox(height: 16),

        Text(
          _timeString,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          _isBreak ? 'Mola Hazırlığı' : 'Huzurlu ve Kesintisiz Odaklanma',
          style: GoogleFonts.inter(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),

        GestureDetector(
          onTap: _startPause,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF303F9F), Color(0xFF0097A7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0097A7).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Zen Seansını Başlat',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildDurationChips(),
        const SizedBox(height: 16),

        _buildCategoryAssistantCard(),
        const SizedBox(height: 16),

        _buildMusicControlsCard(),
      ],
    );
  }

  // --- SAVAŞ MODU: Boss Battle Görünümü ---
  Widget _buildBattleModeView(dynamic user, Color accentColor) {
    final boss = _selectedBoss ?? BossCatalog.getBossForFocusArea(_selectedFocusArea);
    final totalSeconds = (_isBreak ? _selectedBreakDuration : _selectedWorkDuration) * 60;
    final maxHp = boss.calculateMaxHp(_selectedWorkDuration);

    return Column(
      children: [
        // 1. Boss Arenası (Boss kartı, HP barı, Karakter ve vuruş animasyonu)
        BossBattleArena(
          boss: boss,
          secondsLeft: _secondsLeft,
          totalSeconds: totalSeconds,
          maxHp: maxHp,
          isRunning: _isRunning,
          isAttacking: _isAttacking,
          isBossHit: _isBossHit,
          equippedItems: user.equippedItems,
          onBossChanged: (b) {
            setState(() {
              _selectedBoss = b;
            });
          },
          onManualAttack: _triggerHitEffect,
        ),

        // 2. Dairesel Savaş Sayacı
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glow = _isRunning ? (_pulseController.value * 0.25 + 0.1) : 0.05;
            final scale = _isRunning ? (1.0 + (_pulseController.value * 0.015)) : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: boss.primaryColor.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: boss.primaryColor.withValues(alpha: glow),
                      blurRadius: 32,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.cardBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(boss.accentColor),
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
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    _isBreak ? '☕ Mola' : '⚔️ Savaş',
                    style: GoogleFonts.inter(color: boss.accentColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Savaş Kontrol Butonları
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Erken Bitir / Kaç
            IconButton(
              onPressed: _cancelSession,
              tooltip: 'Seansı Bitir',
              icon: const Icon(Icons.stop_circle_outlined, size: 30, color: Colors.white60),
            ),
            const SizedBox(width: 16),
            // Başlat / Duraklat
            GestureDetector(
              onTap: _startPause,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [boss.primaryColor, boss.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: boss.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 4. Süre Seçim Çipleri
        _buildDurationChips(),
        const SizedBox(height: 16),

        // 5. Kategori Asistanı
        _buildCategoryAssistantCard(),
        const SizedBox(height: 16),

        // 6. Müzik Seçim Kartı
        _buildMusicControlsCard(),
      ],
    );
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

    // Zen Modunda sayaç çalışırken tam ekran immersive görünüm
    if (_selectedFocusMode == 'zen' && _isRunning) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C101A),
        body: _buildZenRunningFullscreen(user, accentColor),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          _selectedFocusMode == 'zen' ? 'Zen Odak' : 'Pomodoro İstasyonu',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const SessionHistorySheet(),
              );
            },
            tooltip: 'Seans Geçmişi',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Mod Anahtarı: Savaş Modu | Zen Modu
            if (_selectedFocusArea != 'fitness') ...[
              _buildFocusModeSegmentedSwitch(),
              const SizedBox(height: 6),
            ],

            // 2. Track Info Bar
            Text(
              _isMusicPlaying
                  ? "Active Soft Track: ${_playlist[_currentTrackIndex]['name']}"
                  : "Music Paused 🎵",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // 3. Focus Area Selector
            _buildFocusAreaSelector(),
            const SizedBox(height: 12),

            // 4. Mod Görünümleri: Fitness vs Zen vs Savaş
            if (_selectedFocusArea == 'fitness') ...[
              _buildWorkoutAssistant(user.uid, user.level),
            ] else if (_selectedFocusMode == 'zen') ...[
              _buildZenIdleView(user, accentColor),
            ] else ...[
              _buildBattleModeView(user, accentColor),
            ],
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
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutBack,
                            scale: _isRunning ? 1.04 : 1.0,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    accentColor.withValues(alpha: _isRunning ? 0.82 : 0.68),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(color: accentColor.withValues(alpha: _isRunning ? 0.46 : 0.26), blurRadius: 22, spreadRadius: 2),
                                ],
                              ),
                              child: Icon(
                                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
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
