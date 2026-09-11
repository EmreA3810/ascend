import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class _Tone {
  final double freq;
  final double durationSec;
  final double volume;

  const _Tone(this.freq, this.durationSec, {this.volume = 0.6});
}

/// Ascend ses efektleri yöneticisi
/// Harici ses dosyalarına veya internet bağlantısına ihtiyaç duymadan
/// saf Dart ile bellek içinde (in-memory) PCM WAV dalga formları sentezler.
class SoundEffects {
  static final AudioPlayer _player = AudioPlayer();
  static bool isMuted = false;

  static Uint8List? _tickWav;
  static Uint8List? _workStartWav;
  static Uint8List? _restStartWav;
  static Uint8List? _victoryWav;
  static Uint8List? _statUpWav;

  static void toggleMute() {
    isMuted = !isMuted;
  }

  /// 3-2-1 geri sayım tık sesi
  static Future<void> playTick() async {
    _tickWav ??= _synthesizeWav([const _Tone(920, 0.05, volume: 0.5)]);
    await _playBytes(_tickWav!);
  }

  /// Antrenman seti başlama / Düdük sesi
  static Future<void> playWorkStart() async {
    _workStartWav ??= _synthesizeWav([
      const _Tone(587.33, 0.09, volume: 0.55), // D5
      const _Tone(880.00, 0.22, volume: 0.65), // A5
    ]);
    await _playBytes(_workStartWav!);
  }

  /// Dinlenme aşaması sakinleşme tonu
  static Future<void> playRestStart() async {
    _restStartWav ??= _synthesizeWav([
      const _Tone(659.25, 0.12, volume: 0.5),  // E5
      const _Tone(440.00, 0.24, volume: 0.45), // A4
    ]);
    await _playBytes(_restStartWav!);
  }

  /// Antrenman veya Pomodoro tamamlandığında Zafer Fanfarı
  static Future<void> playVictory() async {
    _victoryWav ??= _synthesizeWav([
      const _Tone(523.25, 0.10, volume: 0.6),  // C5
      const _Tone(659.25, 0.10, volume: 0.6),  // E5
      const _Tone(783.99, 0.12, volume: 0.65), // G5
      const _Tone(1046.50, 0.45, volume: 0.7), // C6
    ]);
    await _playBytes(_victoryWav!);
  }

  /// Stat artırıldığında seviye atlama sesi
  static Future<void> playStatUp() async {
    _statUpWav ??= _synthesizeWav([
      const _Tone(523.25, 0.07, volume: 0.5),  // C5
      const _Tone(783.99, 0.16, volume: 0.6),  // G5
      const _Tone(1046.50, 0.25, volume: 0.65), // C6
    ]);
    await _playBytes(_statUpWav!);
  }

  static Uint8List? _errorWav;

  /// Uyarı / Hata / Odak bozulma tonu
  static Future<void> playError() async {
    _errorWav ??= _synthesizeWav([
      const _Tone(320.00, 0.12, volume: 0.7),
      const _Tone(220.00, 0.28, volume: 0.75),
    ]);
    await _playBytes(_errorWav!);
  }

  static Uint8List? _lofiWav;
  static Uint8List? _rainWav;
  static Uint8List? _zenWav;
  static Uint8List? _breezeWav;

  /// Lofi Chill Piano & Rhodes Akorları (Döngüsel odak müziği)
  static Uint8List getLofiBeatsWav() {
    if (_lofiWav != null) return _lofiWav!;
    const sampleRate = 22050;
    const duration = 10.0;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <int>[];

    // Fmaj7 -> G7 -> Em7 -> Am7 akor dizilimi
    final chords = [
      [349.23, 440.0, 523.25, 659.25], // Fmaj7
      [392.00, 493.88, 587.33, 698.46], // G7
      [329.63, 392.00, 493.88, 587.33], // Em7
      [440.00, 523.25, 659.25, 783.99], // Am7
    ];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final chordIndex = (t / 2.5).floor().clamp(0, 3);
      final chord = chords[chordIndex];
      final chordT = t % 2.5;

      final env = exp(-chordT * 1.35);
      final tremolo = 1.0 + 0.12 * sin(2 * pi * 4.5 * t);

      double sum = 0;
      for (int k = 0; k < chord.length; k++) {
        final f = chord[k];
        sum += sin(2 * pi * f * chordT) + 0.3 * sin(4 * pi * f * chordT);
      }
      final lofiHum = sin(2 * pi * 55.0 * t) * 0.08;
      final val = ((sum / 4.0) * env * tremolo + lofiHum) * 11000 * 0.55;
      samples.add(val.round().clamp(-32768, 32767));
    }

    _lofiWav = _samplesToWav(samples, sampleRate: sampleRate);
    return _lofiWav!;
  }

  /// Doğal Yağmur & Pembe Gürültü Sesi (Konsantrasyon ve derin çalışma)
  static Uint8List getRainWav() {
    if (_rainWav != null) return _rainWav!;
    const sampleRate = 22050;
    const duration = 6.0;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <int>[];
    final random = Random(42);

    double b0 = 0, b1 = 0, b2 = 0;

    for (int i = 0; i < totalSamples; i++) {
      final white = random.nextDouble() * 2 - 1;
      b0 = 0.99765 * b0 + white * 0.0990460;
      b1 = 0.96300 * b1 + white * 0.2965164;
      b2 = 0.57000 * b2 + white * 1.0526913;
      final pink = b0 + b1 + b2 + white * 0.1848;

      final isDrop = random.nextInt(3000) == 0;
      final drop = isDrop ? (random.nextDouble() * 0.7) : 0.0;

      final progress = i / totalSamples;
      double loopWindow = 1.0;
      if (progress < 0.05) loopWindow = progress / 0.05;
      if (progress > 0.95) loopWindow = (1.0 - progress) / 0.05;

      final val = (pink * 0.22 + drop) * 12500 * loopWindow;
      samples.add(val.round().clamp(-32768, 32767));
    }

    _rainWav = _samplesToWav(samples, sampleRate: sampleRate);
    return _rainWav!;
  }

  /// 432 Hz Zen Tibet Çanı & Derin Meditasyon Tonu
  static Uint8List getZenMeditationWav() {
    if (_zenWav != null) return _zenWav!;
    const sampleRate = 22050;
    const duration = 8.0;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <int>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final waveSweep = (sin(2 * pi * 0.22 * t) + 1.0) * 0.5;

      final fundamental = sin(2 * pi * 432.0 * t);
      final sub = 0.65 * sin(2 * pi * 108.0 * t);
      final overtone = 0.35 * sin(2 * pi * 864.0 * t);
      final fifth = 0.25 * sin(2 * pi * 648.0 * t);

      final envelope = 0.75 + 0.25 * waveSweep;
      final val = (fundamental + sub + overtone + fifth) * envelope * 4500;
      samples.add(val.round().clamp(-32768, 32767));
    }

    _zenWav = _samplesToWav(samples, sampleRate: sampleRate);
    return _zenWav!;
  }

  /// Çam Ormanı & Hafif Rüzgar Esintisi
  static Uint8List getForestBreezeWav() {
    if (_breezeWav != null) return _breezeWav!;
    const sampleRate = 22050;
    const duration = 7.0;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <int>[];
    final random = Random(123);

    double filterState = 0;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final white = random.nextDouble() * 2 - 1;
      final windLfo = (sin(2 * pi * 0.28 * t) + 1.0) * 0.5;
      final cutoff = 0.08 + (windLfo * 0.12);

      filterState += cutoff * (white - filterState);
      final rustle = 0.12 * sin(2 * pi * (480 + 30 * windLfo) * t) * (windLfo * 0.4);

      final val = (filterState * 0.7 + rustle) * 12000;
      samples.add(val.round().clamp(-32768, 32767));
    }

    _breezeWav = _samplesToWav(samples, sampleRate: sampleRate);
    return _breezeWav!;
  }

  static Future<void> _playBytes(Uint8List bytes) async {
    if (isMuted) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Ses çalma hatası kullanıcı akışını asla engellememelidir.
    }
  }

  static Uint8List _synthesizeWav(List<_Tone> tones, {int sampleRate = 22050}) {
    final samples = <int>[];

    for (final tone in tones) {
      final totalSamples = (tone.durationSec * sampleRate).toInt();
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        final progress = i / totalSamples;

        // Tıklamaları ve ani ses kesilmelerini önlemek için Envelope eğrisi
        double envelope = 1.0;
        if (progress < 0.1) {
          envelope = progress / 0.1;
        } else if (progress > 0.65) {
          envelope = (1.0 - progress) / 0.35;
        }

        final fundamental = sin(2 * pi * tone.freq * t);
        final harmonic = 0.25 * sin(4 * pi * tone.freq * t);
        final value = ((fundamental + harmonic) / 1.25) * 16000 * envelope * tone.volume;
        samples.add(value.round().clamp(-32768, 32767));
      }
    }

    return _samplesToWav(samples, sampleRate: sampleRate);
  }

  static Uint8List _samplesToWav(List<int> samples, {int sampleRate = 22050}) {
    final subChunk2Size = samples.length * 2;
    final chunkSize = 36 + subChunk2Size;
    final byteData = ByteData(44 + subChunk2Size);

    // RIFF Chunk
    byteData.setUint8(0, 0x52); // R
    byteData.setUint8(1, 0x49); // I
    byteData.setUint8(2, 0x46); // F
    byteData.setUint8(3, 0x46); // F
    byteData.setUint32(4, chunkSize, Endian.little);
    // WAVE
    byteData.setUint8(8, 0x57);  // W
    byteData.setUint8(9, 0x41);  // A
    byteData.setUint8(10, 0x56); // V
    byteData.setUint8(11, 0x45); // E

    // fmt Subchunk (PCM = 16 bytes)
    byteData.setUint8(12, 0x66); // f
    byteData.setUint8(13, 0x6D); // m
    byteData.setUint8(14, 0x74); // t
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);  // PCM format
    byteData.setUint16(22, 1, Endian.little);  // 1 Kanal (Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little); // Byte Rate
    byteData.setUint16(32, 2, Endian.little);  // Block Align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample

    // data Subchunk
    byteData.setUint8(36, 0x64); // d
    byteData.setUint8(37, 0x61); // a
    byteData.setUint8(38, 0x74); // t
    byteData.setUint8(39, 0x61); // a
    byteData.setUint32(40, subChunk2Size, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      byteData.setInt16(44 + (i * 2), samples[i], Endian.little);
    }

    return byteData.buffer.asUint8List();
  }
}
