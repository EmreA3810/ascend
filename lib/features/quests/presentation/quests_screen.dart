import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/xp_gain_popup.dart';
import '../../../core/widgets/ascend_toast.dart';
import '../data/quest_model.dart';
import '../providers/quest_provider.dart';
import '../../user/providers/user_provider.dart';
import 'add_quest_sheet.dart';

class QuestsScreen extends ConsumerStatefulWidget {
  const QuestsScreen({super.key});

  @override
  ConsumerState<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends ConsumerState<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        ref.read(questRepositoryProvider).ensureWeeklyQuests(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getChestRarityName(int xp) {
    if (xp >= 200) return 'Efsanevi Sandık 👑';
    if (xp >= 100) return 'Epik Sandık 💜';
    if (xp >= 75) return 'Nadir Sandık 💙';
    if (xp >= 50) return 'Sıradışı Sandık 💚';
    return 'Sıradan Sandık 🤎';
  }

  bool _canManuallyIncrement(QuestModel quest) {
    final cleanUnit = quest.unit.trim().toLowerCase();
    final lowerTitle = quest.title.toLowerCase();

    // Antrenman, spor ve set bazlı görevlerde manuel artı butonu olmamalı (Antrenman Koçu ile yapılır)
    if (cleanUnit == 'set' ||
        lowerTitle.contains('antrenman') ||
        lowerTitle.contains('spor') ||
        lowerTitle.contains('fitness')) {
      return false;
    }

    // Problem çözme, ders çalışma, dakika ve pomodoro seanslarında manuel artı butonu olmamalı
    if (cleanUnit == 'problem' ||
        cleanUnit == 'dk' ||
        cleanUnit == 'seans' ||
        lowerTitle.contains('problem') ||
        lowerTitle.contains('ders') ||
        lowerTitle.contains('kod')) {
      return false;
    }

    // Yalnızca su içme, sayfa okuma veya adet bazlı basit alışkanlıklar manuel tıklanabilir
    return cleanUnit == 'bardak' || cleanUnit == 'adet' || cleanUnit == 'sayfa';
  }

  Future<void> _incrementProgress(String uid, QuestModel quest) async {
    final willComplete = quest.currentValue + 1 >= quest.targetValue;
    await ref.read(questRepositoryProvider).incrementQuestProgress(uid, quest.id, 1);
    if (willComplete && mounted) {
      XpGainPopup.show(
        context,
        xp: quest.xpReward,
        statName: quest.statBoost,
        statAmount: 1,
      );
      AscendToast.show(
        context,
        title: 'Ganimet Kazanıldı! 🎁',
        message: 'Görevi tamamladın ve bir [${_getChestRarityName(quest.xpReward)}] kazandın!',
        type: ToastType.success,
      );
    }
  }

  Future<void> _onRefresh() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      await ref.read(questRepositoryProvider).ensureDailyQuests(user.uid);
      await ref.read(questRepositoryProvider).ensureWeeklyQuests(user.uid);
    }
    ref.invalidate(dailyQuestsProvider);
    ref.invalidate(weeklyQuestsProvider);
    ref.invalidate(customQuestsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            'Görevler',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final weeklyQuestsAsync = ref.watch(weeklyQuestsProvider);
    final customQuestsAsync = ref.watch(customQuestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Görevler',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal),
          tabs: const [Tab(text: 'Günlük'), Tab(text: 'Haftalık'), Tab(text: 'Özel')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const AddQuestBottomSheet(),
          );
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyTab(user.uid, dailyQuestsAsync),
          _buildWeeklyTab(user.uid, weeklyQuestsAsync),
          _buildCustomTab(user.uid, customQuestsAsync),
        ],
      ),
    );
  }

  Widget _buildCustomTab(String uid, AsyncValue<List<QuestModel>> customQuestsAsync) {
    return customQuestsAsync.when(
      loading: () => _buildEmptyState('Özel görevler yükleniyor...'),
      error: (err, stack) => _buildEmptyState('Görevler yüklenemedi.'),
      data: (quests) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: quests.isEmpty
              ? _buildEmptyState('Özel görev bulunmuyor.')
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: quests.length,
                    itemBuilder: (ctx, i) {
                      final quest = quests[i];
                      return _buildQuestTile(uid, quest);
                    },
                  ),
                ),
        );
      },
    );
  }

  Widget _buildDailyTab(String uid, AsyncValue<List<QuestModel>> dailyQuestsAsync) {
    return dailyQuestsAsync.when(
      loading: () => _buildEmptyState('Bugünün görevleri yükleniyor...'),
      error: (err, stack) => _buildEmptyState('Görevler yüklenemedi.'),
      data: (quests) {
        final completed = quests.where((q) => q.isCompleted).length;
        final total = quests.length;
        final percent = total > 0 ? completed / total : 0.0;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: quests.isEmpty
              ? _buildEmptyState('Bugün için görev bulunmuyor.')
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Progress Summary Header Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.secondary.withValues(alpha: 0.05),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$completed / $total Tamamlandı',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bugünkü disiplin seviyen',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: CircularProgressIndicator(
                                    value: percent,
                                    backgroundColor: AppColors.background,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                                    strokeWidth: 5,
                                  ),
                                ),
                                Text(
                                  '${(percent * 100).toInt()}%',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List of Quests
                      Expanded(
                        child: ListView.builder(
                          itemCount: quests.length,
                          itemBuilder: (ctx, i) {
                            final quest = quests[i];
                            return _buildQuestTile(uid, quest);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildWeeklyTab(String uid, AsyncValue<List<QuestModel>> weeklyQuestsAsync) {
    return weeklyQuestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => Center(
        child: Text('Görevler yüklenirken hata oluştu', style: GoogleFonts.inter(color: Colors.white)),
      ),
      data: (quests) {
        final now = DateTime.now();
        final daysLeft = 7 - now.weekday;
        final daysLeftText = daysLeft == 0 ? 'Son Gün! ⚡' : '$daysLeft gün kaldı';
        final completedCount = quests.where((q) => q.isCompleted).length;
        final totalCount = quests.length;
        final progressRatio = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Haftalık Durum & Geri Sayım Kartı
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withValues(alpha: 0.15),
                      AppColors.cardBackground,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.05),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Colors.orangeAccent, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Haftalık Meydan Okuma',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Pazar 23:59 sıfırlanır • $daysLeftText',
                                  style: GoogleFonts.inter(
                                    color: Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.orangeAccent, size: 20),
                          tooltip: 'Haftalık Görevleri Yenile',
                          onPressed: () async {
                            await ref.read(questRepositoryProvider).forceRefreshWeeklyQuests(uid);
                            ref.invalidate(weeklyQuestsProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Haftalık görevler başarıyla yenilendi! 🔄'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Haftalık İlerleme',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        Text(
                          '$completedCount / $totalCount Tamamlandı',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressRatio,
                        minHeight: 8,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                      ),
                    ),
                  ],
                ),
              ),

              if (quests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colors.orangeAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Bu Hafta İçin Henüz Görevin Yok',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Odak alanlarına göre otomatik haftalık görev paketini hemen başlatabilirsin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await ref.read(questRepositoryProvider).ensureWeeklyQuests(uid);
                          ref.invalidate(weeklyQuestsProvider);
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Haftalık Görevleri Başlat',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...quests.map((quest) => _buildWeeklyQuestCard(uid, quest)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(Icons.assignment_turned_in_outlined, color: AppColors.textSecondary, size: 64),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni bir tane eklemek için + butonuna bas.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildQuestTile(String uid, QuestModel quest) {
    final isDone = quest.isCompleted;
    final iconData = QuestModel.iconFromName(quest.iconName);

    return Dismissible(
      key: Key(quest.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return true;
      },
      onDismissed: (direction) {
        ref.read(questRepositoryProvider).deleteQuest(uid, quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${quest.title}" görevi silindi.')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.05),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDone ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: isDone ? AppColors.success : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: GoogleFonts.inter(
                      color: isDone ? AppColors.textSecondary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${quest.xpReward} XP',
                          style: GoogleFonts.inter(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stat: ${quest.statBoost.toUpperCase()}',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (quest.targetValue > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isDone ? 1.0 : (quest.currentValue / quest.targetValue).clamp(0.0, 1.0),
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppColors.success : AppColors.primary),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isDone ? quest.targetValue : quest.currentValue}/${quest.targetValue} ${quest.unit}',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isDone && quest.targetValue > 1 && _canManuallyIncrement(quest)) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 28),
                onPressed: () => _incrementProgress(uid, quest),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
            ],
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AddQuestBottomSheet(initialQuest: quest),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            // Animated Circular Toggle
            GestureDetector(
              onTap: (quest.targetValue > 1 || const ['dk', 'set', 'sayfa', 'problem', 'bardak', 'seans'].contains(quest.unit))
                  ? () {
                      final isFitness = quest.unit == 'set' || quest.title.toLowerCase().contains('antrenman') || quest.title.toLowerCase().contains('spor');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isFitness
                              ? 'Bu görev Antrenman Koçu ile setler tamamlandıkça otomatik ilerler! 💪'
                              : 'Bu görev Pomodoro veya çalışma seansı tamamlandıkça otomatik ilerler! ⚡'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : () async {
                      final nextCompleted = !quest.isCompleted;
                      await ref.read(questRepositoryProvider).toggleQuest(uid, quest.id, nextCompleted);
                      
                      if (nextCompleted && mounted) {
                        XpGainPopup.show(
                          context,
                          xp: quest.xpReward,
                          statName: quest.statBoost,
                          statAmount: 1,
                        );
                        AscendToast.show(
                          context,
                          title: 'Ganimet Kazanıldı! 🎁',
                          message: 'Görevi tamamladın ve bir [${_getChestRarityName(quest.xpReward)}] kazandın!',
                          type: ToastType.success,
                        );
                      }
                    },
              child: _buildAnimatedCircularToggle(isDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCircularToggle(bool isCompleted) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: !isCompleted ? AppColors.background.withValues(alpha: 0.8) : null,
              border: Border.all(
                color: isCompleted ? AppColors.success.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: [
                if (isCompleted)
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
              ],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              scale: isCompleted ? 1.0 : 0.0,
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 26,
                    )
                  : null,
            ),
          ),
          // Pulse glow ring
          if (!isCompleted)
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                onEnd: () {},
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 1.0 + (value * 0.15),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: (1 - value) * 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklyQuestCard(String uid, QuestModel quest) {
    final isDone = quest.isCompleted;
    final progress = quest.progress;
    final iconData = QuestModel.iconFromName(quest.iconName);

    return Dismissible(
      key: Key(quest.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        ref.read(questRepositoryProvider).deleteQuest(uid, quest.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${quest.title}" görevi silindi.')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? AppColors.success.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Icon(iconData, color: Colors.orangeAccent, size: 22),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    quest.title,
                    style: GoogleFonts.inter(
                      color: isDone ? AppColors.textSecondary : Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // Reward Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${quest.xpReward} XP',
                    style: GoogleFonts.inter(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            if (!isDone && quest.targetValue > 1 && _canManuallyIncrement(quest)) ...[
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 26),
                    onPressed: () => _incrementProgress(uid, quest),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                ],
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => AddQuestBottomSheet(initialQuest: quest),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Checkbox
                GestureDetector(
                  onTap: (quest.targetValue > 1 || const ['dk', 'set', 'sayfa', 'problem', 'bardak', 'seans'].contains(quest.unit))
                      ? () {
                          final isFitness = quest.unit == 'set' || quest.title.toLowerCase().contains('antrenman') || quest.title.toLowerCase().contains('spor');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isFitness
                                  ? 'Bu görev Antrenman Koçu ile setler tamamlandıkça otomatik ilerler! 💪'
                                  : 'Bu görev Pomodoro veya çalışma seansı tamamlandıkça otomatik ilerler! ⚡'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      : () async {
                          final nextCompleted = !quest.isCompleted;
                          await ref.read(questRepositoryProvider).toggleQuest(uid, quest.id, nextCompleted);
                          
                          if (nextCompleted && mounted) {
                            XpGainPopup.show(
                              context,
                              xp: quest.xpReward,
                              statName: quest.statBoost,
                              statAmount: 1,
                            );
                          }
                        },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isDone
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 26, key: ValueKey(true))
                        : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 26, key: ValueKey(false)),
                  ),
                ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isDone ? 1.0 : progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppColors.success : Colors.orangeAccent),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isDone ? quest.targetValue : quest.currentValue}/${quest.targetValue} ${quest.unit}',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isDone ? 'Tamamlandı' : '${(progress * 100).toInt()}% tamamlandı',
          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11),
        ),
          ],
        ),
      ),
    );
  }
}
