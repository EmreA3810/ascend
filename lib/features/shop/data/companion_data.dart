import 'package:flutter/material.dart';

class CompanionModel {
  final String id;
  final String name;
  final String species;
  final int requiredLevel;
  final int goldCost;
  final String buffDescription;
  final String flavorText;
  final List<String> quotes;
  final Color primaryColor;
  final Color accentColor;
  final String emoji;

  const CompanionModel({
    required this.id,
    required this.name,
    required this.species,
    required this.requiredLevel,
    required this.goldCost,
    required this.buffDescription,
    required this.flavorText,
    required this.quotes,
    required this.primaryColor,
    required this.accentColor,
    required this.emoji,
  });
}

class CompanionData {
  static const List<CompanionModel> companions = [
    CompanionModel(
      id: 'archimedes',
      name: 'Archimedes',
      species: 'Bilge Baykuş',
      requiredLevel: 3,
      goldCost: 800,
      buffDescription: '+2 Bilgi Statı & Odaklanma Başarı Bonusu',
      flavorText: 'Kadim kütüphanelerden süzülüp gelen Archimedes, keskin gözleriyle dikkatinin dağılmasına asla izin vermez.',
      quotes: [
        'Hoo-hoo! Bilgi kılıçtan daha keskindir!',
        'Bugün zihnini eğit, yarın dünyayı yönet.',
        'Dikkatini topla savaşçı, odaklandığında yenilmezsin.',
        'Gözlerim üzerinde, pes etmek yok!',
      ],
      primaryColor: Color(0xFF6366F1),
      accentColor: Color(0xFFA5B4FC),
      emoji: '🦉',
    ),
    CompanionModel(
      id: 'kitsune',
      name: 'Kitsune',
      species: 'Siber Tilki',
      requiredLevel: 5,
      goldCost: 1400,
      buffDescription: '+2 Çeviklik & Görevlerden +%15 Altın',
      flavorText: 'Neon ve siber enerjiden doğan 9 kuyruklu tilki. Görevleri şimşek hızında bitirmen için sana rehberlik eder.',
      quotes: [
        'Hadi biraz hızlanalım, geride kalıyorsun!',
        'Görevler önümüzde eriyip gidiyor, aferin!',
        'Siber sinirlerim zafere kilitlendi!',
        'Taktik ve hız: İşte gerçek gücün sırrı!',
      ],
      primaryColor: Color(0xFF06B6D4),
      accentColor: Color(0xFF67E8F9),
      emoji: '🦊',
    ),
    CompanionModel(
      id: 'pyror',
      name: 'Pyror',
      species: 'Yavru Ejderha',
      requiredLevel: 8,
      goldCost: 2200,
      buffDescription: '+3 Güç Statı & Antrenman Alev Aurası',
      flavorText: 'Yanardağların kalbinde uyanan sevimli ama kudretli yavru ejderha. İçindeki çalışma ateşini körükler.',
      quotes: [
        'Rooaaar! İçindeki ateşi serbest bırak!',
        'Yorulduğunda kanat çırp, ejderhalar yere inmez!',
        'Birlikte her zorluğu yakıp kül edeceğiz!',
        'Bir set daha! Ejderha nefesi gibi güçlü ol!',
      ],
      primaryColor: Color(0xFFEF4444),
      accentColor: Color(0xFFFCA5A5),
      emoji: '🐲',
    ),
    CompanionModel(
      id: 'umbra',
      name: 'Umbra',
      species: 'Gölge Kedisi',
      requiredLevel: 10,
      goldCost: 3200,
      buffDescription: '+3 İrade & Tüm Görevlerden +%20 XP',
      flavorText: 'Gecenin sessizliğinden süzülen gizemli gölge kedisi. Sarsılmaz disiplini ve sakinliğiyle seni korur.',
      quotes: [
        'Miyav... Sessiz ol ve işini mükemmel yap.',
        'Gürültüye gerek yok, başarıların konuşsun.',
        'Karanlıkta bile yolunu bulacak iradeye sahipsin.',
        'Pusuda bekle ve hedefine tam zamanında saldır.',
      ],
      primaryColor: Color(0xFF8B5CF6),
      accentColor: Color(0xFFC4B5FD),
      emoji: '🐱',
    ),
    CompanionModel(
      id: 'atlas',
      name: 'Atlas',
      species: 'Kozmik Rün Golemi',
      requiredLevel: 12,
      goldCost: 4500,
      buffDescription: '+4 Dayanıklılık & Sarsılmaz Zihin Aurası',
      flavorText: 'Antik rün taşlarından inşa edilmiş yürüyen bir hisar. Hiçbir zorluk onun karşısında duramaz.',
      quotes: [
        '*Rünik Titreşim* Dağlar gibi dimdik dur!',
        'Zaman akar, rünler kalır. Disiplinin ebedidir.',
        'Yorulmak fani bir yanılsamadır, devam et!',
        'Kaya gibi sert, rüzgar gibi kararlı ol.',
      ],
      primaryColor: Color(0xFFF59E0B),
      accentColor: Color(0xFFFDE68A),
      emoji: '🗿',
    ),
  ];

  static CompanionModel? getById(String? id) {
    if (id == null) return null;
    try {
      return companions.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
