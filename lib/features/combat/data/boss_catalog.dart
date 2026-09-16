import 'package:flutter/material.dart';
import 'boss_monster.dart';

/// Tematik canavar havuzu ve katalog erişimi.
/// Yeni boss eklemek için sadece bu listeye eleman eklemek yeterlidir.
class BossCatalog {
  static const List<BossMonster> monsters = [
    // Akademik / Ders Çalışma
    BossMonster(
      id: 'procrastination_demon',
      name: 'Erteleme İblisi',
      title: 'Zaman Yutan Kadim Varlık',
      category: 'academic',
      baseHpMultiplier: 10,
      icon: Icons.hourglass_disabled_rounded,
      emoji: '⏳',
      primaryColor: Color(0xFFE53935),
      accentColor: Color(0xFFFFB74D),
      minGold: 25,
      maxGold: 55,
      chestDropChances: {
        'common': 0.50,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.03,
      },
      defeatQuote: 'Erteleme İblisi dize getirildi! Zihnini özgürleştirdin ve görevi tamamladın.',
      escapeQuote: 'Erteleme İblisi gölgelere çekildi. Sorun değil, bir dahaki sefere yakalarsın!',
      description: 'Seni "biraz sonra yaparım" fısıltılarıyla kandırmaya çalışan karanlık güç.',
    ),
    BossMonster(
      id: 'sloth_titan',
      name: 'Tembellik Devi',
      title: 'Ağır Adımlı Taş Golem',
      category: 'academic',
      baseHpMultiplier: 12,
      icon: Icons.terrain_rounded,
      emoji: '🗿',
      primaryColor: Color(0xFF6D4C41),
      accentColor: Color(0xFFFFCC80),
      minGold: 30,
      maxGold: 60,
      chestDropChances: {
        'common': 0.45,
        'rare': 0.28,
        'epic': 0.12,
        'legendary': 0.04,
      },
      defeatQuote: 'Tembellik Devi tuzla buz oldu! Azmin taşları bile un ufak etti.',
      escapeQuote: 'Tembellik Devi derin uykusuna geri döndü. Bir sonraki sefere hazır ol!',
      description: 'Harekete geçmeni engelleyen, iradeni ağırlaştıran devasa kaya canavarı.',
    ),

    // Yazılım / Kodlama
    BossMonster(
      id: 'distraction_dragon',
      name: 'Dikkat Dağınıklığı Ejderi',
      title: 'Sekme Açan Kaos Alevi',
      category: 'coding',
      baseHpMultiplier: 10,
      icon: Icons.local_fire_department_rounded,
      emoji: '🐉',
      primaryColor: Color(0xFF7B1FA2),
      accentColor: Color(0xFF00E5FF),
      minGold: 25,
      maxGold: 50,
      chestDropChances: {
        'common': 0.50,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.03,
      },
      defeatQuote: 'Dikkat Dağınıklığı Ejderi söndürüldü! Akış (flow) haline başarıyla eriştin.',
      escapeQuote: 'Ejderha başka sekmelere kaçtı. Sorun yok, bir dahaki sefere alt edersin!',
      description: 'Sonsuz bildirimler ve yeni sekmelerle odağını ateşe veren ejderha.',
    ),
    BossMonster(
      id: 'bug_queen',
      name: 'Hata Böceği Kraliçesi',
      title: 'Çöken Kodların Hükümdarı',
      category: 'coding',
      baseHpMultiplier: 11,
      icon: Icons.bug_report_rounded,
      emoji: '👾',
      primaryColor: Color(0xFF00897B),
      accentColor: Color(0xFF76FF03),
      minGold: 30,
      maxGold: 55,
      chestDropChances: {
        'common': 0.48,
        'rare': 0.26,
        'epic': 0.12,
        'legendary': 0.04,
      },
      defeatQuote: 'Hata Böceği Kraliçesi temizlendi! Kodların pürüzsüzce derlendi.',
      escapeQuote: 'Kraliçe logların arasına saklandı. Bir sonraki derlemede yakalarsın!',
      description: 'Kod satırlarının arasına gizlenip odak noktanı dağıtan karanlık yaratık.',
    ),

    // Kitap Okuma
    BossMonster(
      id: 'anxiety_wraith',
      name: 'Odaksızlık Hortlağı',
      title: 'Uçuşan Düşünceler Fısıltısı',
      category: 'reading',
      baseHpMultiplier: 10,
      icon: Icons.auto_stories_rounded,
      emoji: '👻',
      primaryColor: Color(0xFF1E88E5),
      accentColor: Color(0xFFB388FF),
      minGold: 20,
      maxGold: 45,
      chestDropChances: {
        'common': 0.52,
        'rare': 0.24,
        'epic': 0.09,
        'legendary': 0.02,
      },
      defeatQuote: 'Odaksızlık Hortlağı dağıldı! Sayfaların derinliklerine daldın.',
      escapeQuote: 'Hortlak kitabın sayfaları arasına kaçtı. Merak etme, bir dahaki sefere!',
      description: 'Aynı sayfayı tekrar tekrar okumana sebep olan dalgınlık ruhu.',
    ),

    // Genel / Serbest Odak
    BossMonster(
      id: 'time_thief',
      name: 'Zaman Hırsızı Gölge',
      title: 'Dakikaları Çalan Sis',
      category: 'general',
      baseHpMultiplier: 10,
      icon: Icons.dark_mode_rounded,
      emoji: '🥷',
      primaryColor: Color(0xFF455A64),
      accentColor: Color(0xFFFFD54F),
      minGold: 25,
      maxGold: 50,
      chestDropChances: {
        'common': 0.50,
        'rare': 0.25,
        'epic': 0.10,
        'legendary': 0.03,
      },
      defeatQuote: 'Zaman Hırsızı yakalandı! Çalınan saatlerini geri kazandın.',
      escapeQuote: 'Gölge sislerin arasına karıştı. Bir dahaki sefere pusuda bekle!',
      description: 'Zamanın nasıl geçtiğini hissettirmeden çalan sinsi gölge.',
    ),

    // Fitness / HIIT Antrenman (Ortak Katman)
    BossMonster(
      id: 'fatigue_golem',
      name: 'Yorgunluk Golemi',
      title: 'Tükenişin Zırhlı Muhafızı',
      category: 'fitness',
      baseHpMultiplier: 15,
      icon: Icons.fitness_center_rounded,
      emoji: '💥',
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFD600),
      minGold: 35,
      maxGold: 70,
      chestDropChances: {
        'common': 0.40,
        'rare': 0.30,
        'epic': 0.15,
        'legendary': 0.05,
      },
      defeatQuote: 'Yorgunluk Golemi yıkıldı! Sınırlarını aştın ve kaslarını güçlendirdin.',
      escapeQuote: 'Golem geri çekildi. Dinlen ve bir sonraki antrenmanda daha güçlü gel!',
      description: 'Son tekrarda "bırak gitsin" diyen kas yanması golemi.',
    ),
  ];

  /// Odak alanına (`academic`, `coding`, `reading`, `general`, `fitness`) göre tematik boss getirir.
  static BossMonster getBossForFocusArea(String focusArea) {
    final matches = monsters.where((m) => m.category == focusArea).toList();
    if (matches.isNotEmpty) {
      return matches.first;
    }
    // Eşleşme yoksa genel boss döner
    return monsters.firstWhere(
      (m) => m.category == 'general',
      orElse: () => monsters.first,
    );
  }

  /// Tüm boss listesi (kullanıcı seçim arayüzü için)
  static List<BossMonster> getAllBosses() => monsters;

  /// ID ile boss bulma
  static BossMonster getById(String id) {
    return monsters.firstWhere(
      (m) => m.id == id,
      orElse: () => monsters.first,
    );
  }
}
