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
        ref.read(questRepositoryProvider).ensureInstantQuests(user.uid);
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
      await ref.read(questRepositoryProvider).ensureInstantQuests(user.uid);
    }
    ref.invalidate(dailyQuestsProvider);
    ref.invalidate(weeklyQuestsProvider);
    ref.invalidate(instantQuestsProvider);
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
    final instantQuestsAsync = ref.watch(instantQuestsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            toolbarHeight: 46,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)], // Zümrüt Yeşili & Açık Nane
              ).createShader(bounds),
              child: Text(
                'GÖREVLER',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(42),
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF10B981), // Zümrüt Yeşili
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 12),
                  tabs: const [Tab(text: 'Günlük'), Tab(text: 'Haftalık'), Tab(text: 'Anlık')],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDailyTab(user.uid, dailyQuestsAsync),
            _buildWeeklyTab(user.uid, weeklyQuestsAsync),
            _buildInstantTab(user.uid, instantQuestsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantTab(String uid, AsyncValue<List<QuestModel>> instantQuestsAsync) {
    return instantQuestsAsync.when(
      loading: () => _buildEmptyState('Anlık görevler yükleniyor...'),
      error: (err, stack) => _buildEmptyState('Görevler yüklenemedi.'),
      data: (quests) {
        return RefreshIndicator(
          onRefresh: _onRefresh,
          color: const Color(0xFF00E5FF),
          backgroundColor: AppColors.cardBackground,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Instant Quest Bonus Banner Header
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANLIK GÖREVLER (1.3x EKSTRA XP)',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hemen tamamlayıp anında ekstra XP ve ganimet sandığı kazan!',
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (quests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: Color(0xFF00E5FF), size: 40),
                      const SizedBox(height: 12),
                      Text(
                        'Şu Anda Anlık Görev Yok',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ekstra hızlı XP ve sandık kazanmak için + butonundan anlık görev ekleyebilirsin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                ...quests.map((quest) => _buildQuestTile(uid, quest, accentColor: const Color(0xFF00E5FF))),
            ],
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

  Widget _buildQuestTile(String uid, QuestModel quest, {Color accentColor = const Color(0xFF10B981)}) {
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
            color: isDone ? AppColors.success.withValues(alpha: 0.3) : accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon (clean, matching weekly format directly)
                Icon(iconData, color: accentColor, size: 22),
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
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${quest.xpReward} XP',
                    style: GoogleFonts.inter(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (!isDone && quest.targetValue > 1 && _canManuallyIncrement(quest)) ...[
                  IconButton(
                    icon: Icon(Icons.add_circle_outline, color: accentColor, size: 26),
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
                // Checkbox toggle (exact circular toggle matching weekly)
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
                      valueColor: AlwaysStoppedAnimation<Color>(isDone ? AppColors.success : accentColor),
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

  Widget _buildWeeklyQuestCard(String uid, QuestModel quest) {
    return _buildQuestTile(uid, quest, accentColor: Colors.orangeAccent);
  }
}
