import 'package:flutter_test/flutter_test.dart';
import 'package:ascend/core/services/focus_area_stat_service.dart';

void main() {
  group('FocusAreaStatService Tests', () {
    test('Fitness tek başına seçildiğinde sadece strength ve energy döner (Bilgi/Knowledge gizlenir)', () {
      final stats = FocusAreaStatService.getVisibleStats(['fitness']);
      expect(stats, contains('strength'));
      expect(stats, contains('energy'));
      expect(stats, isNot(contains('knowledge')));
      expect(stats, isNot(contains('focus')));
      expect(stats.length, 2);
    });

    test('Akademi seçildiğinde knowledge ve focus döner', () {
      final stats = FocusAreaStatService.getVisibleStats(['academic']);
      expect(stats, contains('knowledge'));
      expect(stats, contains('focus'));
      expect(stats, isNot(contains('strength')));
      expect(stats, isNot(contains('energy')));
      expect(stats.length, 2);
    });

    test('Okuma seçildiğinde knowledge ve focus döner', () {
      final stats = FocusAreaStatService.getVisibleStats(['reading']);
      expect(stats, contains('knowledge'));
      expect(stats, contains('focus'));
      expect(stats.length, 2);
    });

    test('Yazılım seçildiğinde focus ve knowledge döner', () {
      final stats = FocusAreaStatService.getVisibleStats(['coding']);
      expect(stats, contains('focus'));
      expect(stats, contains('knowledge'));
      expect(stats.length, 2);
    });

    test('Birden fazla alan seçildiğinde statların birleşimi döner', () {
      final stats = FocusAreaStatService.getVisibleStats(['fitness', 'academic']);
      expect(stats, contains('strength'));
      expect(stats, contains('energy'));
      expect(stats, contains('knowledge'));
      expect(stats, contains('focus'));
      expect(stats.length, 4);
    });

    test('Hiçbir alan seçilmediğinde veya atlandığında tüm 4 stat varsayılan olarak döner', () {
      final emptyStats = FocusAreaStatService.getVisibleStats([]);
      expect(emptyStats.length, 4);

      final skippedStats = FocusAreaStatService.getVisibleStats(['skipped']);
      expect(skippedStats.length, 4);
    });

    test('Her odak alanının seans tamamlama stat ödülleri doğru haritalanır', () {
      final fitnessBoosts = FocusAreaStatService.getSessionStatBoosts('fitness');
      expect(fitnessBoosts['strength'], 1);
      expect(fitnessBoosts['energy'], 1);
      expect(fitnessBoosts.containsKey('knowledge'), isFalse);

      final academicBoosts = FocusAreaStatService.getSessionStatBoosts('academic');
      expect(academicBoosts['knowledge'], 1);
      expect(academicBoosts['focus'], 1);

      final readingBoosts = FocusAreaStatService.getSessionStatBoosts('reading');
      expect(readingBoosts['knowledge'], 1);
      expect(readingBoosts['focus'], 1);

      final codingBoosts = FocusAreaStatService.getSessionStatBoosts('coding');
      expect(codingBoosts['focus'], 1);
      expect(codingBoosts['knowledge'], 1);
    });

    test('Türkçe etiket ve kısa kod haritalamaları doğrudur', () {
      expect(FocusAreaStatService.getStatLabel('strength'), 'Güç');
      expect(FocusAreaStatService.getStatLabel('energy'), 'Enerji');
      expect(FocusAreaStatService.getStatLabel('knowledge'), 'Bilgi');
      expect(FocusAreaStatService.getStatLabel('focus'), 'Odak');

      expect(FocusAreaStatService.getStatShortCode('strength'), 'STR');
      expect(FocusAreaStatService.getStatShortCode('energy'), 'ENG');
      expect(FocusAreaStatService.getStatShortCode('knowledge'), 'KNW');
      expect(FocusAreaStatService.getStatShortCode('focus'), 'FOC');
    });
  });
}
