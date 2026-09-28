import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TitleInfo {
  final String title;
  final String category; // 'coding', 'fitness', 'reading', 'academic', 'general'
  final String description;
  final IconData icon;
  final Color color;

  const TitleInfo({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class TitleService {
  static const List<TitleInfo> allTitles = [
    // === CODING / YAZILIM ===
    TitleInfo(
      title: 'Kod Çırağı',
      category: 'coding',
      description: 'Yazılım dünyasına ilk adımlarını atan hevesli geliştirici.',
      icon: Icons.code_rounded,
      color: AppColors.statFocus,
    ),
    TitleInfo(
      title: 'Bug Avcısı',
      category: 'coding',
      description: 'Hataları affetmeyen, satır satır temizlik yapan dedektif.',
      icon: Icons.bug_report_rounded,
      color: Colors.redAccent,
    ),
    TitleInfo(
      title: 'Terminal Büyücüsü',
      category: 'coding',
      description: 'Komut satırında klavyesiyle harikalar yaratan usta.',
      icon: Icons.terminal_rounded,
      color: Colors.tealAccent,
    ),
    TitleInfo(
      title: 'Algoritma Mimarı',
      category: 'coding',
      description: 'Karmaşık sorunlara zarif ve hızlı çözümler inşa eden zihin.',
      icon: Icons.account_tree_rounded,
      color: AppColors.secondary,
    ),
    TitleInfo(
      title: 'Siber Şövalye',
      category: 'coding',
      description: 'Kodlarının sağlamlığıyla projelerini savunan dijital muhafız.',
      icon: Icons.security_rounded,
      color: Colors.indigoAccent,
    ),
    TitleInfo(
      title: 'Full-Stack Efsanesi',
      category: 'coding',
      description: 'Arayüzden veritabanına tüm katmanlara hükmeden usta.',
      icon: Icons.layers_rounded,
      color: AppColors.gold,
    ),
    TitleInfo(
      title: 'Refactor Ustası',
      category: 'coding',
      description: 'Spagetti kodları sanat eserine dönüştüren titiz geliştirici.',
      icon: Icons.auto_fix_high_rounded,
      color: Colors.cyanAccent,
    ),

    // === FITNESS / SPOR ===
    TitleInfo(
      title: 'Çaylak Sporcu',
      category: 'fitness',
      description: 'Harekete geçen ve bedenini disipline sokmaya başlayan atlet.',
      icon: Icons.directions_run_rounded,
      color: AppColors.statStrength,
    ),
    TitleInfo(
      title: 'Demir Yumruk',
      category: 'fitness',
      description: 'Ağırlıkların altında pes etmeyen, çelik iradeli savaşçı.',
      icon: Icons.fitness_center_rounded,
      color: Colors.deepOrangeAccent,
    ),
    TitleInfo(
      title: 'Fırtına Koşucusu',
      category: 'fitness',
      description: 'Kardiyo seanslarında rüzgarı arkasına alan hızlı atlet.',
      icon: Icons.speed_rounded,
      color: Colors.amberAccent,
    ),
    TitleInfo(
      title: 'Titan Atlet',
      category: 'fitness',
      description: 'Fiziksel sınırları zorlayıp her gün güçlenen dev irade.',
      icon: Icons.shield_rounded,
      color: AppColors.statStrength,
    ),
    TitleInfo(
      title: 'Disiplin Makinesi',
      category: 'fitness',
      description: 'Motivasyonu değil disiplini pusula edinen yorulmaz sporcu.',
      icon: Icons.bolt_rounded,
      color: Colors.orangeAccent,
    ),
    TitleInfo(
      title: 'Yenilmez Gladyatör',
      category: 'fitness',
      description: 'Arenada sonuna kadar ter döken ve asla geri adım atmayan şampiyon.',
      icon: Icons.sports_mma_rounded,
      color: AppColors.gold,
    ),

    // === READING / KİTAP & GELİŞİM ===
    TitleInfo(
      title: 'Kitap Kurdu',
      category: 'reading',
      description: 'Satırların arasında kaybolup sayfaları yutan meraklı zihin.',
      icon: Icons.menu_book_rounded,
      color: AppColors.primary,
    ),
    TitleInfo(
      title: 'Felsefe Gezgini',
      category: 'reading',
      description: 'Büyük düşünürlerin izinde hakikati arayan derin akıl.',
      icon: Icons.psychology_rounded,
      color: Colors.purpleAccent,
    ),
    TitleInfo(
      title: 'Bilgelik Arayıcısı',
      category: 'reading',
      description: 'Öğrendiği her bilgiyi hayatına rehber yapan bilinçli okur.',
      icon: Icons.lightbulb_rounded,
      color: AppColors.gold,
    ),
    TitleInfo(
      title: 'Zihin Üstadı',
      category: 'reading',
      description: 'Konsantrasyonunu ve zihinsel berraklığını zirveye taşıyan düşünür.',
      icon: Icons.self_improvement_rounded,
      color: Colors.tealAccent,
    ),
    TitleInfo(
      title: 'Kadim Bilge',
      category: 'reading',
      description: 'Yüzlerce kitaptan süzülen bilgeliği ruhunda taşıyan alim.',
      icon: Icons.auto_stories_rounded,
      color: Colors.deepPurpleAccent,
    ),

    // === ACADEMIC / DERS ÇALIŞMA ===
    TitleInfo(
      title: 'Ders Çırağı',
      category: 'academic',
      description: 'Masasının başında geleceğini inşa eden azimli öğrenci.',
      icon: Icons.school_rounded,
      color: AppColors.statKnowledge,
    ),
    TitleInfo(
      title: 'Not Avcısı',
      category: 'academic',
      description: 'Önemli detayları kaçırmayan, eksiksiz çalışan taktiksel zihin.',
      icon: Icons.edit_note_rounded,
      color: Colors.blueAccent,
    ),
    TitleInfo(
      title: 'Sınav Fatihi',
      category: 'academic',
      description: 'Zorlu test ve soruları bir bir fetheden akademik savaşçı.',
      icon: Icons.military_tech_rounded,
      color: AppColors.gold,
    ),
    TitleInfo(
      title: 'Hafıza Üstadı',
      category: 'academic',
      description: 'Konuları kavramada ve hatırlamada üstün başarı gösteren zeka.',
      icon: Icons.psychology_alt_rounded,
      color: Colors.cyanAccent,
    ),
    TitleInfo(
      title: 'Büyük Alim',
      category: 'academic',
      description: 'Disiplinli çalışmasıyla akademik zirveye tırmanan lider öğrenci.',
      icon: Icons.workspace_premium_rounded,
      color: Colors.purpleAccent,
    ),

    // === GENERAL / GENEL ===
    TitleInfo(
      title: 'Acemi Savaşçı',
      category: 'general',
      description: 'Ascend dünyasına adım atan yeni ve cesur savaşçı.',
      icon: Icons.explore_rounded,
      color: Colors.white70,
    ),
    TitleInfo(
      title: 'Odak Ustası',
      category: 'general',
      description: 'Tüm dikkat dağıtıcıları susturup tek bir hedefe kilitlenen zihin.',
      icon: Icons.center_focus_strong_rounded,
      color: AppColors.secondary,
    ),
    TitleInfo(
      title: 'Zaman Bükücü',
      category: 'general',
      description: 'Her dakikasını en yüksek verimle değerlendiren zaman efendisi.',
      icon: Icons.hourglass_top_rounded,
      color: Colors.tealAccent,
    ),
    TitleInfo(
      title: 'Şafak Muhafızı',
      category: 'general',
      description: 'Güne erken başlayıp hedeflerini herkesten önce tamamlayan irade.',
      icon: Icons.wb_sunny_rounded,
      color: Colors.amber,
    ),
    TitleInfo(
      title: 'Efsanevi Kahraman',
      category: 'general',
      description: 'Tüm zorlukları aşıp zirveye adını yazdıran efsane.',
      icon: Icons.stars_rounded,
      color: AppColors.gold,
    ),
  ];

  /// Verilen unvan adına ait TitleInfo'yu döner.
  static TitleInfo getTitleInfo(String titleName) {
    return allTitles.firstWhere(
      (t) => t.title.toLowerCase() == titleName.toLowerCase(),
      orElse: () => TitleInfo(
        title: titleName,
        category: 'general',
        description: 'Özel Ascend unvanı.',
        icon: Icons.military_tech_rounded,
        color: AppColors.secondary,
      ),
    );
  }

  /// Kullanıcının odak alanlarına ve halihazırda açtığı unvanlara göre
  /// rastgele YENİ bir unvan seçer.
  static TitleInfo? getRandomTitleForUser(
    List<String> userFocusAreas,
    List<String> currentUnlockedTitles,
  ) {
    final lowerUnlocked = currentUnlockedTitles.map((t) => t.toLowerCase()).toSet();
    final validAreas = userFocusAreas.where((a) => a != 'skipped').toSet();

    // 1. Önce kullanıcının seçili odak alanlarındaki açılmamış unvanları filtrele
    List<TitleInfo> candidates = allTitles.where((t) {
      if (lowerUnlocked.contains(t.title.toLowerCase())) return false;
      return validAreas.contains(t.category);
    }).toList();

    // 2. Eğer odak alanlarındaki tüm unvanlar açılmışsa genel havuza bak
    if (candidates.isEmpty) {
      candidates = allTitles.where((t) {
        if (lowerUnlocked.contains(t.title.toLowerCase())) return false;
        return t.category == 'general';
      }).toList();
    }

    // 3. Hala boşsa tüm havuzdaki açılmamış olanlara bak
    if (candidates.isEmpty) {
      candidates = allTitles.where((t) {
        return !lowerUnlocked.contains(t.title.toLowerCase());
      }).toList();
    }

    if (candidates.isEmpty) return null; // Tüm unvanlar açılmış

    final random = Random();
    return candidates[random.nextInt(candidates.length)];
  }

  /// Kategori etiketini döner
  static String getCategoryLabel(String category) {
    switch (category) {
      case 'coding':
        return 'Yazılım & Kariyer';
      case 'fitness':
        return 'Spor & Sağlık';
      case 'reading':
        return 'Kitap & Gelişim';
      case 'academic':
        return 'Ders & Akademi';
      default:
        return 'Genel';
    }
  }
}
