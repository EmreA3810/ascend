import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/glassmorphic_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shell/providers/shell_provider.dart';

class NotificationService {
  static const String _lastReminderKey = 'last_motivational_reminder_date';

  /// Check and show daily motivational reminder popup if not shown today
  static Future<void> checkDailyReminder(BuildContext context, WidgetRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString(_lastReminderKey);
    final todayStr = DateUtils.dateOnly(DateTime.now()).toString();

    // Already shown today? Skip
    if (lastShownStr == todayStr) return;

    // Wait a brief moment after app starts so user is on dashboard
    await Future.delayed(const Duration(seconds: 3));
    // Save that it is shown today
    await prefs.setString(_lastReminderKey, todayStr);

    if (!context.mounted) return;

    // Show motivational reminder dialog
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (ctx) => _ReminderDialog(ref: ref),
    );
  }
}

class _ReminderDialog extends StatelessWidget {
  final WidgetRef ref;
  const _ReminderDialog({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassmorphicCard(
        borderColor: AppColors.secondary.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.secondary,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'GÜNLÜK MÜCADELE ÇAĞRISI!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Zaman daralıyor Savaşçı! Bugün hedeflerine odaklanıp seviye atlamak için harika bir gün. Bir odaklanma seansı başlatmaya hazır mısın?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Sonra',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      // Switch to Pomodoro tab
                      ref.read(shellIndexProvider.notifier).setIndex(2);
                    },
                    child: Text(
                      'Odaklan ⏱️',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
