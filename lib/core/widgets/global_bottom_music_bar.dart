import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../features/pomodoro/providers/ambient_audio_provider.dart';

class GlobalBottomMusicBar extends ConsumerWidget {
  const GlobalBottomMusicBar({super.key});

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
                  const Icon(Icons.music_note_rounded, color: AppColors.secondary, size: 22),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xF2141928),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: audioState.isPlaying
              ? AppColors.secondary.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.10),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: audioState.isPlaying
                ? AppColors.secondary.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. SATIR: Şarkı Bilgisi & Oynatma Kontrolleri (Mobil Dokunmatik Dostu)
          Row(
            children: [
              // Müzik İkon Rozeti (Tıklanınca parça seçiciyi açar)
              InkWell(
                onTap: () => _showMusicPicker(context, ref, audioState.currentTrackIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: audioState.isPlaying
                        ? AppColors.secondary.withValues(alpha: 0.22)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: audioState.isPlaying
                          ? AppColors.secondary.withValues(alpha: 0.45)
                          : Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    track['icon'] as IconData? ?? Icons.music_note_rounded,
                    color: audioState.isPlaying ? AppColors.secondary : AppColors.textSecondary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Şarkı Adı ve Durumu
              Expanded(
                child: InkWell(
                  onTap: () => _showMusicPicker(context, ref, audioState.currentTrackIndex),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              track['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white54, size: 18),
                        ],
                      ),
                      Text(
                        audioState.isPlaying ? 'Ortam Sesi Çalıyor 🎵' : 'Duraklatıldı • Dokun ve Başlat',
                        style: GoogleFonts.inter(
                          color: audioState.isPlaying ? AppColors.secondary : AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Kontrol Butonları
              // Önceki
              InkWell(
                onTap: () => ref.read(ambientAudioProvider.notifier).prevTrack(),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 20),
                ),
              ),
              const SizedBox(width: 2),

              // Oynat / Duraklat (Geniş 36x36 dairesel buton)
              InkWell(
                onTap: () => ref.read(ambientAudioProvider.notifier).toggle(),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: audioState.isPlaying
                        ? AppColors.secondary.withValues(alpha: 0.28)
                        : Colors.white.withValues(alpha: 0.12),
                    border: Border.all(
                      color: audioState.isPlaying
                          ? AppColors.secondary
                          : Colors.white24,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    audioState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: audioState.isPlaying ? AppColors.secondary : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 2),

              // Sonraki
              InkWell(
                onTap: () => ref.read(ambientAudioProvider.notifier).nextTrack(),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.skip_next_rounded, color: Colors.white70, size: 20),
                ),
              ),
            ],
          ),

          const SizedBox(height: 3),

          // 2. SATIR: İnce Ses Seviyesi Düzenleme Çubuğu & Yüzdesi
          Row(
            children: [
              const Icon(Icons.volume_down_rounded, size: 13, color: Colors.white38),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 9),
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
              const Icon(Icons.volume_up_rounded, size: 13, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                '${(audioState.volume * 100).round()}%',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
