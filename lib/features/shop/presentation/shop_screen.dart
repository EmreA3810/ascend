import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sound_effects.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../data/companion_data.dart';
import 'companion_widget.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MAĞAZA',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        actions: [
          if (user != null) ...[
            // Streak shields badge
            Container(
              margin: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Colors.cyanAccent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.streakShields}/3',
                    style: GoogleFonts.inter(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Gold balance chip
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.gold}',
                    style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.pets, size: 18), text: 'Yoldaşlar'),
            Tab(icon: Icon(Icons.shield_outlined, size: 18), text: 'Kalkan & İksir'),
            Tab(icon: Icon(Icons.card_giftcard, size: 18), text: 'Sandıklar'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCompanionsTab(user),
                _buildItemsTab(user),
                _buildChestsTab(user),
              ],
            ),
    );
  }

  // 1. COMPANIONS TAB
  Widget _buildCompanionsTab(UserModel user) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: CompanionData.companions.length,
      itemBuilder: (context, index) {
        final companion = CompanionData.companions[index];
        final isUnlocked = user.unlockedCompanions.contains(companion.id);
        final isEquipped = user.equippedCompanion == companion.id;
        final isLevelLocked = user.level < companion.requiredLevel;
        final canAfford = user.gold >= companion.goldCost;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isEquipped
                  ? companion.primaryColor
                  : isUnlocked
                      ? Colors.white24
                      : isLevelLocked
                          ? Colors.white10
                          : companion.primaryColor.withValues(alpha: 0.3),
              width: isEquipped ? 2 : 1,
            ),
            boxShadow: isEquipped
                ? [
                    BoxShadow(
                      color: companion.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CompanionWidget(
                    companion: companion,
                    size: 60,
                    showSpeechBubbleOnTap: true,
                    showNameTag: false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              companion.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isLevelLocked
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isLevelLocked ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                'Seviye ${companion.requiredLevel}+',
                                style: GoogleFonts.inter(
                                  color: isLevelLocked ? Colors.redAccent : Colors.greenAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          companion.species,
                          style: GoogleFonts.inter(color: companion.accentColor, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: companion.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '✨ ${companion.buffDescription}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                companion.flavorText,
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (!isUnlocked)
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${companion.goldCost} Altın',
                          style: GoogleFonts.inter(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Envanterinde Mevcut',
                        style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  _buildCompanionActionButton(user, companion, isUnlocked, isEquipped, isLevelLocked, canAfford),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompanionActionButton(
    UserModel user,
    CompanionModel companion,
    bool isUnlocked,
    bool isEquipped,
    bool isLevelLocked,
    bool canAfford,
  ) {
    if (isEquipped) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
        label: Text('Kuşanılmış', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.greenAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          await ref.read(userRepositoryProvider).unequipCompanion(user.uid);
          SoundEffects.playTick();
        },
      );
    }

    if (isUnlocked) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: companion.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          await ref.read(userRepositoryProvider).equipCompanion(user.uid, companion.id);
          SoundEffects.playStatUp();
        },
        child: Text('Kuşan', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      );
    }

    if (isLevelLocked) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.lock, size: 14, color: Colors.white38),
        label: Text('Kilitli (Sv. ${companion.requiredLevel})', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: null,
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
      label: Text('Satın Al', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Colors.amber.shade700 : Colors.white12,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: canAfford
          ? () async {
              final success = await ref.read(userRepositoryProvider).buyCompanion(
                    user.uid,
                    companion.id,
                    companion.goldCost,
                    companion.requiredLevel,
                  );
              if (success && mounted) {
                SoundEffects.playVictory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text(
                      'Tebrikler! ${companion.name} artık seninle yolculuk ediyor! 🎉',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            }
          : null,
    );
  }

  // 2. ITEMS & POTIONS TAB
  Widget _buildItemsTab(UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak Shield
        _buildItemCard(
          icon: Icons.shield_rounded,
          iconColor: Colors.cyanAccent,
          title: 'Streak Kalkanı (Amulet)',
          badge: 'Aktif: ${user.streakShields}/3',
          description: 'Bir gün uygulamaya girmesen bile serini sıfırlanmaktan kurtarır. Kaçırılan günde otomatik harcanır.',
          cost: 350,
          canBuy: user.gold >= 350 && user.streakShields < 3,
          buttonText: user.streakShields >= 3 ? 'Kapasite Dolu (3/3)' : 'Satın Al (350 🪙)',
          onBuy: () async {
            final ok = await ref.read(userRepositoryProvider).buyStreakShield(user.uid, 350);
            if (ok && mounted) {
              SoundEffects.playStatUp();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.blueAccent,
                  content: Text('Streak Kalkanı envantere eklendi! 🛡️', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 16),
        // 2x XP Potion
        _buildItemCard(
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.purpleAccent,
          title: '2x Odaklanma İksiri (1 Saat)',
          badge: 'İksir',
          description: '1 saat boyunca tamamlanan tüm pomodoro ve görevlerden iki kat XP kazandırır.',
          cost: 250,
          canBuy: user.gold >= 250,
          buttonText: 'Satın Al (250 🪙)',
          onBuy: () async {
            if (user.gold >= 250) {
              await ref.read(userRepositoryProvider).spendGold(user.uid, 250);
              SoundEffects.playStatUp();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.purpleAccent,
                    content: Text('2x XP Etkisi 1 saatliğine etkinleştirildi! ⚡', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(height: 16),
        // Gold Magnet
        _buildItemCard(
          icon: Icons.attractions_rounded,
          iconColor: Colors.amber,
          title: 'Altın Mıknatısı',
          badge: 'Güçlendirme',
          description: 'Bugün yapacağın tüm antrenman koçlukları ve görevlerden +%50 daha fazla altın kazandırır.',
          cost: 300,
          canBuy: user.gold >= 300,
          buttonText: 'Satın Al (300 🪙)',
          onBuy: () async {
            if (user.gold >= 300) {
              await ref.read(userRepositoryProvider).spendGold(user.uid, 300);
              SoundEffects.playStatUp();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.amber.shade700,
                    content: Text('Altın Mıknatısı aktif! Görevlerden bereket fışkırıyor 🧲', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String badge,
    required String description,
    required int cost,
    required bool canBuy,
    required String buttonText,
    required VoidCallback onBuy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColor.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(badge, style: GoogleFonts.inter(color: iconColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canBuy ? AppColors.primary : Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: canBuy ? onBuy : null,
              child: Text(buttonText, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. CHESTS TAB
  Widget _buildChestsTab(UserModel user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChestCard(
          user: user,
          rarity: 'rare',
          name: 'Nadir Ekipman Sandığı',
          cost: 400,
          color: Colors.blueAccent,
          icon: '📦',
          perks: 'İçerisinden Nadir Seviye Şapka, Zırh veya Pantolon çıkar.',
        ),
        const SizedBox(height: 16),
        _buildChestCard(
          user: user,
          rarity: 'legendary',
          name: 'Efsanevi Kahraman Sandığı',
          cost: 900,
          color: Colors.orangeAccent,
          icon: '👑',
          perks: 'İçerisinden Efsanevi Seviye Işıltılı Kozmetikler & Muazzam Stat artışları çıkar.',
        ),
      ],
    );
  }

  Widget _buildChestCard({
    required UserModel user,
    required String rarity,
    required String name,
    required int cost,
    required Color color,
    required String icon,
    required String perks,
  }) {
    final canBuy = user.gold >= cost;
    final ownedCount = user.chestsEarned[rarity] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Envanterinde: $ownedCount Adet',
                      style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text('$cost', style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(perks, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: Text('Satın Al ($cost 🪙)', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: canBuy ? color : Colors.white12,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: canBuy
                  ? () async {
                      await ref.read(userRepositoryProvider).spendGold(user.uid, cost);
                      await ref.read(userRepositoryProvider).addChest(user.uid, rarity);
                      SoundEffects.playStatUp();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: color,
                            content: Text('$name envanterine eklendi! Gardıroptan açabilirsin 🎉', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
