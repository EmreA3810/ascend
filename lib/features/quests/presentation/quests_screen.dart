import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/xp_gain_popup.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(dailyQuestsProvider);
    ref.invalidate(weeklyQuestsProvider);
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
          tabs: const [Tab(text: 'Günlük'), Tab(text: 'Haftalık')],
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
        ],
      ),
    );
  }

  Widget _buildDailyTab(String uid, AsyncValue<List<QuestModel>> dailyQuestsAsync) {
    return dailyQuestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Görevler yüklenirken hata oluştu', style: GoogleFonts.inter(color: Colors.white)),
            TextButton(
              onPressed: _onRefresh,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.primary)),
            )
          ],
        ),
      ),
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
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.cardBackground,
          child: quests.isEmpty
              ? _buildEmptyState('Bu hafta için görev bulunmuyor.')
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: quests.length,
                    itemBuilder: (ctx, i) {
                      final quest = quests[i];
                      return _buildWeeklyQuestCard(uid, quest);
                    },
                  ),
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
                ],
              ),
            ),
            // Checkbox
            GestureDetector(
              onTap: () async {
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
                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 30, key: ValueKey(true))
                    : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 30, key: ValueKey(false)),
              ),
            ),
          ],
        ),
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
                const SizedBox(width: 8),
                // Checkbox
                GestureDetector(
                  onTap: () async {
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
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: isDone ? 1.0 : progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppColors.success : Colors.orangeAccent),
                minHeight: 6,
              ),
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
