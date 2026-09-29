import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/sound_effects.dart';

class AmbientAudioState {
  final int currentTrackIndex;
  final bool isPlaying;
  final double volume;

  const AmbientAudioState({
    this.currentTrackIndex = 0,
    this.isPlaying = false,
    this.volume = 0.5,
  });

  AmbientAudioState copyWith({
    int? currentTrackIndex,
    bool? isPlaying,
    double? volume,
  }) {
    return AmbientAudioState(
      currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      volume: volume ?? this.volume,
    );
  }
}

class AmbientAudioNotifier extends Notifier<AmbientAudioState> {
  static final AudioPlayer _player = AudioPlayer();
  StreamSubscription? _completeSub;

  static const List<Map<String, dynamic>> playlist = [
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

  @override
  AmbientAudioState build() {
    _completeSub ??= _player.onPlayerComplete.listen((_) {
      nextTrack();
    });

    ref.onDispose(() {
      _completeSub?.cancel();
      _completeSub = null;
      _player.dispose();
    });

    return const AmbientAudioState();
  }

  Future<void> playCurrentTrack() async {
    final track = playlist[state.currentTrackIndex];
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(state.volume);

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
      state = state.copyWith(isPlaying: true);
    } catch (_) {
      try {
        await _player.play(BytesSource(SoundEffects.getLofiBeatsWav()));
        state = state.copyWith(isPlaying: true);
      } catch (_) {}
    }
  }

  Future<void> pause() async {
    await _player.pause();
    state = state.copyWith(isPlaying: false);
  }

  Future<void> toggle() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await playCurrentTrack();
    }
  }

  Future<void> selectTrack(int index) async {
    state = state.copyWith(currentTrackIndex: index);
    await playCurrentTrack();
  }

  Future<void> nextTrack() async {
    final nextIdx = (state.currentTrackIndex + 1) % playlist.length;
    state = state.copyWith(currentTrackIndex: nextIdx);
    await playCurrentTrack();
  }

  Future<void> prevTrack() async {
    final prevIdx = (state.currentTrackIndex - 1 + playlist.length) % playlist.length;
    state = state.copyWith(currentTrackIndex: prevIdx);
    await playCurrentTrack();
  }

  Future<void> setVolume(double vol) async {
    state = state.copyWith(volume: vol);
    await _player.setVolume(vol);
  }
}

final ambientAudioProvider =
    NotifierProvider<AmbientAudioNotifier, AmbientAudioState>(AmbientAudioNotifier.new);
