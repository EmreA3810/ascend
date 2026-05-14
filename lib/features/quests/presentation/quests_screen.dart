import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QuestsScreen extends StatefulWidget {
  const QuestsScreen({super.key});

  @override
  State<QuestsScreen> createState() => _QuestsScreenState();
}

class _QuestsScreenState extends State<QuestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> dailyQuests = [
    {'title': '1 Saat Ders Çalış', 'xp': 80, 'icon': Icons.school, 'done': false},
    {'title': 'Spor Yap (30 dk)', 'xp': 100, 'icon': Icons.fitness_center, 'done': true},
    {'title': 'Kitap Oku (20 sayfa)', 'xp': 50, 'icon': Icons.menu_book, 'done': false},
    {'title': '2 Pomodoro Tamamla', 'xp': 80, 'icon': Icons.timer, 'done': false},
    {'title': '2 Litre Su İç', 'xp': 30, 'icon': Icons.water_drop, 'done': true},
  ];

  final List<Map<String, dynamic>> weeklyQuests = [
    {'title': '10 Saat Çalışma Serisi', 'xp': 500, 'icon': Icons.star, 'progress': 0.6},
    {'title': 'Her Gün Spor (5/7)', 'xp': 300, 'icon': Icons.emoji_events, 'progress': 0.71},
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Görevler', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Günlük'), Tab(text: 'Haftalık')],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildDailyTab(), _buildWeeklyTab()],
      ),
    );
  }

  Widget _buildDailyTab() {
    final done = dailyQuests.where((q) => q['done'] == true).length;
    final total = dailyQuests.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.2),
                AppColors.secondary.withValues(alpha: 0.08),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done / $total Tamamlandı',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Bugünkü hedeflerin',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: done / total,
                        backgroundColor: AppColors.background,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                        strokeWidth: 5,
                      ),
                    ),
                    Text('${((done / total) * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dailyQuests.length,
              itemBuilder: (ctx, i) => _buildQuestTile(dailyQuests[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestTile(Map<String, dynamic> q, int index) {
    final isDone = q['done'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? AppColors.success.withValues(alpha: 0.35) : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDone ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(q['icon'] as IconData, color: isDone ? AppColors.success : AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q['title'],
                  style: TextStyle(
                    color: isDone ? AppColors.textSecondary : Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  )),
              Text('+${q['xp']} XP', style: const TextStyle(color: AppColors.success, fontSize: 12)),
            ]),
          ),
          GestureDetector(
            onTap: () => setState(() => dailyQuests[index]['done'] = !isDone),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isDone
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 28, key: ValueKey(true))
                  : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary, size: 28, key: ValueKey(false)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: weeklyQuests.map((q) {
          final progress = q['progress'] as double;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(q['icon'] as IconData, color: Colors.orangeAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(q['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('+${q['xp']} XP',
                          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.background,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text('${(progress * 100).toInt()}% tamamlandı',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
