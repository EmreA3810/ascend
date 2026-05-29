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

      if (mounted) {
        XpGainPopup.show(context, xp: xpEarned, statName: 'focus', statAmount: 1);
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
                    children: [15, 25, 45, 60].map((mins) {
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
