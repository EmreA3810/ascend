import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  static const int _workSeconds = 25 * 60;
  static const int _breakSeconds = 5 * 60;

  int _secondsLeft = _workSeconds;
  bool _isRunning = false;
  bool _isBreak = false;
  int _sessionCount = 0;
  Timer? _timer;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startPause() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _timer?.cancel();
          setState(() {
            _isBreak = !_isBreak;
            _secondsLeft = _isBreak ? _breakSeconds : _workSeconds;
            if (!_isBreak) _sessionCount++;
            _isRunning = false;
          });
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = _isBreak ? _breakSeconds : _workSeconds;
      _isRunning = false;
    });
  }

  String get _timeString {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    final total = _isBreak ? _breakSeconds : _workSeconds;
    return 1.0 - (_secondsLeft / total);
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _isBreak ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pomodoro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Mode indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                _isBreak ? '☕ Mola Zamanı' : '⚡ Odak Modu',
                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 48),
            // Timer ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final glow = _isRunning ? (_pulseController.value * 0.3 + 0.1) : 0.1;
                return Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: glow),
                        blurRadius: 40,
                        spreadRadius: 10,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        _isBreak ? 'Mola' : 'Çalışma',
                        style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 32, color: AppColors.textSecondary),
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
                  onPressed: () {
                    _timer?.cancel();
                    setState(() {
                      _isBreak = !_isBreak;
                      _secondsLeft = _isBreak ? _breakSeconds : _workSeconds;
                      _isRunning = false;
                    });
                  },
                  icon: const Icon(Icons.skip_next_rounded, size: 32, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 48),
            // Session dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: i < _sessionCount % 4 ? 16 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: i < _sessionCount % 4 ? AppColors.success : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: i < _sessionCount % 4
                        ? [BoxShadow(color: AppColors.success.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$_sessionCount Pomodoro Tamamlandı',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            // XP Preview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoTile('Bugün', '$_sessionCount Seans'),
                  Container(width: 1, height: 32, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  _buildInfoTile('Kazanılan XP', '+${_sessionCount * 40}'),
                  Container(width: 1, height: 32, color: AppColors.textSecondary.withValues(alpha: 0.2)),
                  _buildInfoTile('Süre', '${_sessionCount * 25} dk'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
