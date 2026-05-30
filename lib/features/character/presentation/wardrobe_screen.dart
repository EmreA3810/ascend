import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../data/loot_pool.dart';
import 'character_painter.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> with SingleTickerProviderStateMixin {
  String _selectedSlot = 'hat'; // 'hat', 'torso', 'pants'
  
  // Sandık animasyon durumları
  bool _isOpeningChest = false;
  LootItem? _unlockedItem;
  int _refundGold = 0;
  
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // Altın harcama kontrolü
  bool _canAfford(UserModel user, int amount) {
    return user.gold >= amount;
  }

  // Sandık Satışı
  void _sellChestAction(UserModel user, String rarityKey) async {
    int goldReward = 30;
    String name = 'Sıradan Sandık';
    if (rarityKey == 'uncommon') { goldReward = 60; name = 'Sıradışı Sandık'; }
    else if (rarityKey == 'rare') { goldReward = 120; name = 'Nadir Sandık'; }
    else if (rarityKey == 'epic') { goldReward = 250; name = 'Epik Sandık'; }
    else if (rarityKey == 'legendary') { goldReward = 600; name = 'Efsanevi Sandık'; }
    else if (rarityKey == 'random') { goldReward = 150; name = 'Rastgele Sandık'; }

    final repo = ref.read(userRepositoryProvider);
    await repo.sellChest(user.uid, rarityKey, goldReward);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name satıldı! +$goldReward Altın kazanıldı. 🪙'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 150 Altın Karşılığında Rastgele Sandık Al
  void _buyRandomChestAction(UserModel user) async {
    if (!_canAfford(user, 150)) {
      _showErrorSnackBar('Yetersiz Altın! Rastgele Sandık almak için 150 Altın gerekir.');
      return;
    }

    final repo = ref.read(userRepositoryProvider);
    await repo.spendGold(user.uid, 150);
    await repo.addChest(user.uid, 'random');

    _showSuccessSnackBar('150 Altın harcanarak Rastgele Şans Sandığı satın alındı! 🎁');
  }

  // Sandık Açma Animasyonu ve Ödül Belirleme
  void _openChestAction(UserModel user, String rarityKey) async {
    setState(() {
      _isOpeningChest = true;
      _unlockedItem = null;
      _refundGold = 0;
    });

    // Sallanma animasyonunu çalıştır
    await _shakeController.forward(from: 0.0);
    await _shakeController.reverse();
    await _shakeController.forward(from: 0.0);
    await _shakeController.reverse();
    
    // Gecikme vererek heyecan katıyoruz
    await Future.delayed(const Duration(milliseconds: 600));

    // Rastgele giysi seçme
    LootItem? chosenItem;
    final rand = Random();

    if (rarityKey == 'random') {
      // Şans olasılıkları: %50 Common, %25 Uncommon, %15 Rare, %8 Epic, %2 Legendary
      final roll = rand.nextDouble() * 100;
      Rarity selectedRarity = Rarity.common;
      if (roll >= 98) {
        selectedRarity = Rarity.legendary;
      } else if (roll >= 90) {
        selectedRarity = Rarity.epic;
      } else if (roll >= 75) {
        selectedRarity = Rarity.rare;
      } else if (roll >= 50) {
        selectedRarity = Rarity.uncommon;
      }
      
      final candidates = LootPool.getItemsByRarity(selectedRarity);
      if (candidates.isNotEmpty) {
        chosenItem = candidates[rand.nextInt(candidates.length)];
      }
    } else {
      // Sandık kalitesine göre giysi seçimi
      Rarity r = Rarity.common;
      if (rarityKey == 'uncommon') {
        r = Rarity.uncommon;
      } else if (rarityKey == 'rare') {
        r = Rarity.rare;
      } else if (rarityKey == 'epic') {
        r = Rarity.epic;
      } else if (rarityKey == 'legendary') {
        r = Rarity.legendary;
      }

      final candidates = LootPool.getItemsByRarity(r);
      if (candidates.isNotEmpty) {
        chosenItem = candidates[rand.nextInt(candidates.length)];
      }
    }

    if (chosenItem == null) {
      setState(() => _isOpeningChest = false);
      _showErrorSnackBar('Üzgünüz, sandıktan eşya seçilemedi.');
      return;
    }

    final bool alreadyUnlocked = user.unlockedItems.contains(chosenItem.id);
    final repo = ref.read(userRepositoryProvider);

    if (alreadyUnlocked) {
      // Zaten varsa: Altın iadesi yapılıyor (Maliyetin %50'si)
      _refundGold = (chosenItem.xpCost * 0.5).toInt();
      // Sandığı düş ve Altın ekle
      await repo.sellChest(user.uid, rarityKey, _refundGold);
    } else {
      // Yeni eşya: Sandığı düş ve unlockedItems'a ekle
      await repo.openChest(user.uid, rarityKey, chosenItem.id);
    }

    setState(() {
      _unlockedItem = chosenItem;
    });
  }

  // Doğrudan Altın harcayarak eşya satın alma
  void _unlockItemDirectly(UserModel user, LootItem item) async {
    if (!_canAfford(user, item.xpCost)) {
      _showErrorSnackBar('Yetersiz Altın! Bu giysi için ${item.xpCost} Altın gerekir.');
      return;
    }

    final repo = ref.read(userRepositoryProvider);
    await repo.unlockItemDirectly(user.uid, item.id, item.xpCost);
    _showSuccessSnackBar('${item.name} başarıyla satın alındı! 🧥');
  }

  // Giysi Kuşanma
  void _equipItemAction(UserModel user, LootItem item) async {
    final repo = ref.read(userRepositoryProvider);
    final currentEquipped = user.equippedItems[item.slot];
    
    if (currentEquipped == item.id) {
      // Zaten kuşanılmışsa çıkar
      await repo.equipItem(user.uid, item.slot, '');
      _showSuccessSnackBar('${item.name} çıkarıldı.');
    } else {
      // Kuşan
      await repo.equipItem(user.uid, item.slot, item.id);
      _showSuccessSnackBar('${item.name} kuşanıldı. ⚔️');
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Karakter Gardırobu',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Hata: $err', style: GoogleFonts.inter(color: AppColors.error))),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          final xpRatio = user.xpToNextLevel > 0 ? (user.xp / user.xpToNextLevel).clamp(0.0, 1.0) : 0.0;

          // Sandık envanterleri
          final chests = user.chestsEarned;
          final List<Map<String, dynamic>> chestList = [
            {'key': 'common', 'name': 'Sıradan', 'icon': '📦', 'color': Colors.grey, 'count': chests['common'] ?? 0},
            {'key': 'uncommon', 'name': 'Sıradışı', 'icon': '🟢', 'color': Colors.greenAccent, 'count': chests['uncommon'] ?? 0},
            {'key': 'rare', 'name': 'Nadir', 'icon': '🔵', 'color': Colors.blueAccent, 'count': chests['rare'] ?? 0},
            {'key': 'epic', 'name': 'Epik', 'icon': '🟣', 'color': Colors.purpleAccent, 'count': chests['epic'] ?? 0},
            {'key': 'legendary', 'name': 'Efsanevi', 'icon': '👑', 'color': Colors.orangeAccent, 'count': chests['legendary'] ?? 0},
            {'key': 'random', 'name': 'Rastgele', 'icon': '🎁', 'color': Colors.cyanAccent, 'count': chests['random'] ?? 0},
          ];

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- XP ve Level Üst Barı ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    user.title,
                                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text('🪙 ', style: TextStyle(fontSize: 12)),
                                        Text(
                                          '${user.gold} Altın',
                                          style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'Level ${user.level}',
                                      style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Seviye İlerlemesi:',
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                '${user.xp} / ${user.xpToNextLevel} XP',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                              ),
                              FractionallySizedBox(
                                widthFactor: xpRatio,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [AppColors.success, AppColors.secondary]),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.success.withValues(alpha: 0.4), blurRadius: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Karakter Canlı Önizleme Alanı ---
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(color: AppColors.secondary.withValues(alpha: 0.02), blurRadius: 20),
                          ],
                        ),
                        child: CharacterAvatar(
                          equippedItems: user.equippedItems,
                          size: 160,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Sandıklar & Satın Alma Alanı ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sandık Envanteri 📦',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: AppColors.secondary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: () => _buyRandomChestAction(user),
                          icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                          label: Text(
                            '150 Altın ile Sandık Al',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Sandık Kartları Yatay Liste
                    SizedBox(
                      height: 115,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: chestList.length,
                        itemBuilder: (ctx, idx) {
                          final chest = chestList[idx];
                          final count = chest['count'] as int;
                          final color = chest['color'] as Color;
                          final key = chest['key'] as String;

                          return Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withValues(alpha: count > 0 ? 0.4 : 0.1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(chest['icon'] as String, style: const TextStyle(fontSize: 18)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: count > 0 ? 0.2 : 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'x$count',
                                        style: GoogleFonts.inter(
                                          color: count > 0 ? color : AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  chest['name'] as String,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                if (count > 0)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _openChestAction(user, key),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'AÇ',
                                              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _sellChestAction(user, key),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withValues(alpha: 0.2),
                                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'SAT',
                                              style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 9),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    'Kilitli 🔒',
                                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 9),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Gardırop Kıyafet Bölümü (Şapka, Kıyafet, Pantolon Seçimi) ---
                    Row(
                      children: ['hat', 'torso', 'pants'].map((slot) {
                        final isSel = _selectedSlot == slot;
                        String label = 'Şapka';
                        IconData icon = Icons.face_rounded;
                        Color col = AppColors.statKnowledge;
                        if (slot == 'torso') { label = 'Kıyafet'; icon = Icons.checkroom_rounded; col = AppColors.primary; }
                        else if (slot == 'pants') { label = 'Pantolon'; icon = Icons.airline_seat_legroom_extra_rounded; col = AppColors.statFocus; }

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              showCheckmark: false,
                              avatar: Icon(icon, color: isSel ? Colors.black : AppColors.textSecondary, size: 16),
                              label: Text(label),
                              selected: isSel,
                              onSelected: (_) => setState(() => _selectedSlot = slot),
                              backgroundColor: AppColors.cardBackground,
                              selectedColor: col,
                              labelStyle: GoogleFonts.inter(
                                color: isSel ? Colors.black : AppColors.textSecondary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              side: BorderSide(
                                color: isSel ? col : AppColors.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Giysi Grid Görünümü
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: LootPool.getItemsBySlot(_selectedSlot).length,
                      itemBuilder: (ctx, idx) {
                        final item = LootPool.getItemsBySlot(_selectedSlot)[idx];
                        final isUnlocked = user.unlockedItems.contains(item.id);
                        final isEquipped = user.equippedItems[item.slot] == item.id;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isEquipped
                                  ? item.rarityColor
                                  : (isUnlocked ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent),
                              width: 1.5,
                            ),
                            boxShadow: isEquipped
                                ? [BoxShadow(color: item.rarityColor.withValues(alpha: 0.15), blurRadius: 10)]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.rarityColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: item.rarityColor.withValues(alpha: 0.4), width: 0.8),
                                    ),
                                    child: Text(
                                      item.rarityName,
                                      style: GoogleFonts.inter(color: item.rarityColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 14),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: item.color.withValues(alpha: 0.15),
                                    border: Border.all(color: item.color.withValues(alpha: 0.3)),
                                  ),
                                  child: Icon(
                                    _selectedSlot == 'hat'
                                        ? Icons.face_rounded
                                        : (_selectedSlot == 'torso' ? Icons.checkroom : Icons.wc),
                                    color: item.color,
                                    size: 26,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.name,
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              if (isUnlocked)
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isEquipped ? Colors.grey.shade800 : AppColors.success,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => _equipItemAction(user, item),
                                    child: Text(
                                      isEquipped ? 'Çıkar' : 'Kuşan',
                                      style: GoogleFonts.inter(
                                        color: isEquipped ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 28,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                                      side: const BorderSide(color: AppColors.primary, width: 0.8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => _unlockItemDirectly(user, item),
                                    icon: const Icon(Icons.monetization_on_rounded, size: 12, color: Colors.amber),
                                    label: Text(
                                      '${item.xpCost} Altın',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // --- Sandık Açılımı Örtü/Overlay Görünümü ---
              if (_isOpeningChest)
                Container(
                  color: Colors.black.withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (ctx, child) {
                      final dx = sin(_shakeController.value * 10 * pi) * 8;
                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: GlassmorphicCard(
                        borderColor: _unlockedItem != null ? _unlockedItem!.rarityColor : AppColors.secondary,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_unlockedItem == null) ...[
                              const Text(
                                '🎁',
                                style: TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Sandık Açılıyor...',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Ganimet hazırlanıyor, heyecan dorukta!',
                                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              const CircularProgressIndicator(color: AppColors.secondary),
                            ] else ...[
                              Text(
                                _unlockedItem!.rarity == Rarity.legendary ? '👑' : '🎁',
                                style: const TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'YENİ GANİMET AÇILDI!',
                                style: GoogleFonts.inter(
                                  color: _unlockedItem!.rarityColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _unlockedItem!.color.withValues(alpha: 0.15),
                                  border: Border.all(color: _unlockedItem!.color, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _unlockedItem!.color.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _unlockedItem!.slot == 'hat'
                                      ? Icons.face_rounded
                                      : (_unlockedItem!.slot == 'torso' ? Icons.checkroom : Icons.wc),
                                  color: _unlockedItem!.color,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _unlockedItem!.name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '[${_unlockedItem!.rarityName}] ${_unlockedItem!.slot == 'hat' ? 'Şapka' : (_unlockedItem!.slot == 'torso' ? 'Kıyafet' : 'Pantolon')}',
                                style: GoogleFonts.inter(color: _unlockedItem!.rarityColor, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              if (_refundGold > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    'Bu eşyaya zaten sahiptiniz!\n+$_refundGold Altın İade Edildi! 🪙',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _unlockedItem!.rarityColor,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        _equipItemAction(user, _unlockedItem!);
                                        setState(() {
                                          _isOpeningChest = false;
                                        });
                                      },
                                      child: Text(
                                        'Hemen Kuşan ⚔️',
                                        style: GoogleFonts.inter(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textSecondary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: AppColors.textSecondary),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isOpeningChest = false;
                                        });
                                      },
                                      child: Text(
                                        'Kapat',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
