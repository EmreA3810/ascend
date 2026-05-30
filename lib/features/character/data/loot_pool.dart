import 'package:flutter/material.dart';

enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class LootItem {
  final String id;
  final String name;
  final String slot; // 'hat', 'torso', 'pants'
  final Rarity rarity;
  final int xpCost;
  final Color color;

  const LootItem({
    required this.id,
    required this.name,
    required this.slot,
    required this.rarity,
    required this.xpCost,
    required this.color,
  });

  String get rarityName {
    switch (rarity) {
      case Rarity.common:
        return 'Sıradan';
      case Rarity.uncommon:
        return 'Sıradışı';
      case Rarity.rare:
        return 'Nadir';
      case Rarity.epic:
        return 'Epik';
      case Rarity.legendary:
        return 'Efsanevi';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.uncommon:
        return Colors.greenAccent;
      case Rarity.rare:
        return Colors.blueAccent;
      case Rarity.epic:
        return Colors.purpleAccent;
      case Rarity.legendary:
        return Colors.orangeAccent;
    }
  }
}

class LootPool {
  static final List<LootItem> items = [
    // --- HATS (Şapkalar) ---
    LootItem(
      id: 'straw_hat',
      name: 'Hasır Şapka 🌾',
      slot: 'hat',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.amber.shade200,
    ),
    LootItem(
      id: 'bandana',
      name: 'Kırmızı Bandana 🔴',
      slot: 'hat',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.redAccent,
    ),
    LootItem(
      id: 'cap',
      name: 'Spor Kep 🧢',
      slot: 'hat',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.blue,
    ),
    LootItem(
      id: 'beanie',
      name: 'Kışlık Bere ❄️',
      slot: 'hat',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.teal,
    ),
    LootItem(
      id: 'cowboy_hat',
      name: 'Kovboy Şapkası 🤠',
      slot: 'hat',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.brown,
    ),
    LootItem(
      id: 'iron_helmet',
      name: 'Demir Miğfer 🛡️',
      slot: 'hat',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.blueGrey,
    ),
    LootItem(
      id: 'mage_hat',
      name: 'Büyücü Şapkası 🔮',
      slot: 'hat',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.indigo,
    ),
    LootItem(
      id: 'ninja_mask',
      name: 'Ninja Maskesi 🥷',
      slot: 'hat',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.black87,
    ),
    LootItem(
      id: 'crown',
      name: 'Altın Kral Tacı 👑',
      slot: 'hat',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.amber,
    ),
    LootItem(
      id: 'cyber_visor',
      name: 'Siber Visor 🕶️',
      slot: 'hat',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.cyanAccent,
    ),

    // --- TORSO (Kıyafetler) ---
    LootItem(
      id: 'tshirt',
      name: 'Düz Tişört 👕',
      slot: 'torso',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.white70,
    ),
    LootItem(
      id: 'tunic',
      name: 'Basit Tunik 🪵',
      slot: 'torso',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.brown.shade300,
    ),
    LootItem(
      id: 'hoodie',
      name: 'Konforlu Hoodie 🧥',
      slot: 'torso',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.deepPurpleAccent,
    ),
    LootItem(
      id: 'leather_armor',
      name: 'Deri Zırh 🛡️',
      slot: 'torso',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.orange.shade700,
    ),
    LootItem(
      id: 'suit_jacket',
      name: 'Şık Ceket 👔',
      slot: 'torso',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.grey.shade800,
    ),
    LootItem(
      id: 'steel_chestplate',
      name: 'Çelik Göğüslük 🦾',
      slot: 'torso',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.grey.shade400,
    ),
    LootItem(
      id: 'mage_robe',
      name: 'Büyücü Cübbesi 🧙',
      slot: 'torso',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.purple,
    ),
    LootItem(
      id: 'assassin_cloak',
      name: 'Pelerinli Giysi 🦅',
      slot: 'torso',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.red.shade900,
    ),
    LootItem(
      id: 'paladin_armor',
      name: 'Işık Zırhı ✨',
      slot: 'torso',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.amberAccent,
    ),
    LootItem(
      id: 'cyber_suit',
      name: 'Siber Nano Zırh 🧬',
      slot: 'torso',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.blueAccent,
    ),

    // --- PANTS (Pantolonlar) ---
    LootItem(
      id: 'shorts',
      name: 'Spor Şort 🩳',
      slot: 'pants',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.grey.shade500,
    ),
    LootItem(
      id: 'trousers',
      name: 'Kumaş Pantolon 👖',
      slot: 'pants',
      rarity: Rarity.common,
      xpCost: 100,
      color: Colors.blueGrey.shade600,
    ),
    LootItem(
      id: 'jeans',
      name: 'Mavi Kot 👖',
      slot: 'pants',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.blue.shade800,
    ),
    LootItem(
      id: 'leather_greaves',
      name: 'Deri Pantolon 🦿',
      slot: 'pants',
      rarity: Rarity.uncommon,
      xpCost: 200,
      color: Colors.orange.shade900,
    ),
    LootItem(
      id: 'cargo_pants',
      name: 'Kargo Pantolon 🪖',
      slot: 'pants',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.green.shade800,
    ),
    LootItem(
      id: 'steel_greaves',
      name: 'Çelik Dizlikler 🦿',
      slot: 'pants',
      rarity: Rarity.rare,
      xpCost: 400,
      color: Colors.grey.shade500,
    ),
    LootItem(
      id: 'shadow_pants',
      name: 'Gölge Şalvarı 🥷',
      slot: 'pants',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.purple.shade900,
    ),
    LootItem(
      id: 'ronin_hakama',
      name: 'Geniş Hakama ⛩️',
      slot: 'pants',
      rarity: Rarity.epic,
      xpCost: 800,
      color: Colors.red.shade900,
    ),
    LootItem(
      id: 'paladin_greaves',
      name: 'Kutsal Bacaklık 🛡️',
      slot: 'pants',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.amberAccent,
    ),
    LootItem(
      id: 'cyber_pants',
      name: 'Siber Tayt ⚡',
      slot: 'pants',
      rarity: Rarity.legendary,
      xpCost: 1500,
      color: Colors.cyanAccent,
    ),
  ];

  static LootItem? getItemById(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<LootItem> getItemsBySlot(String slot) {
    return items.where((item) => item.slot == slot).toList();
  }

  static List<LootItem> getItemsByRarity(Rarity rarity) {
    return items.where((item) => item.rarity == rarity).toList();
  }
}
