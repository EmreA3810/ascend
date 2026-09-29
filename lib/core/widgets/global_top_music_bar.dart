import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../features/pomodoro/providers/ambient_audio_provider.dart';

class GlobalTopMusicBar extends ConsumerWidget {
  const GlobalTopMusicBar({super.key});

  void _showMusicPicker(BuildContext context, WidgetRef ref, int currentIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161A26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                children: [
                  const Icon(Icons.music_note_rounded, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ortam Sesleri & Odak Müziği',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: AmbientAudioNotifier.playlist.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final track = AmbientAudioNotifier.playlist[i];
                    final isSel = currentIndex == i;
                    return InkWell(
                      onTap: () {
                        ref.read(ambientAudioProvider.notifier).selectTrack(i);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.secondary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel ? AppColors.secondary : Colors.white12,
                            width: isSel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              track['icon'] as IconData? ?? Icons.music_note_rounded,
                              color: isSel ? AppColors.secondary : Colors.white60,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track['name'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    track['desc'] as String,
                                    style: GoogleFonts.inter(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSel)
                              const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(ambientAudioProvider);
    final track = AmbientAudioNotifier.playlist[audioState.currentTrackIndex];

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Müzik Hapı (Pill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: audioState.isPlaying
                    ? AppColors.secondary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08),
              ),
              boxShadow: audioState.isPlaying
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  track['icon'] as IconData? ?? Icons.music_note_rounded,
                  color: audioState.isPlaying ? AppColors.secondary : AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _showMusicPicker(context, ref, audioState.currentTrackIndex),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          audioState.isPlaying ? (track['name'] as String) : 'Müzik Duraklatıldı 🎵',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: audioState.isPlaying ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54, size: 15),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Önceki
                InkWell(
                  onTap: () => ref.read(ambientAudioProvider.notifier).prevTrack(),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 15),
                  ),
                ),
                const SizedBox(width: 2),
                // Oynat / Duraklat
                InkWell(
                  onTap: () => ref.read(ambientAudioProvider.notifier).toggle(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: audioState.isPlaying
                          ? AppColors.secondary.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: audioState.isPlaying ? AppColors.secondary : Colors.white,
                      size: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Sonraki
                InkWell(
                  onTap: () => ref.read(ambientAudioProvider.notifier).nextTrack(),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.skip_next_rounded, color: Colors.white70, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),

          // 2. Ses Seviyesi Düzenleme Çubuğu
          Container(
            width: 200,
            height: 18,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.cardBackground.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_down_rounded, size: 12, color: Colors.white38),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.5,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      activeTrackColor: AppColors.secondary,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: AppColors.secondary,
                    ),
                    child: Slider(
                      value: audioState.volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: (v) => ref.read(ambientAudioProvider.notifier).setVolume(v),
                    ),
                  ),
                ),
                const Icon(Icons.volume_up_rounded, size: 12, color: Colors.white38),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
