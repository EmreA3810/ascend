import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _xpAnimController;
  late Animation<double> _xpAnimation;
  double _previousXpRatio = 0;

  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic),
    );
  }

  void _animateXp(double target) {
    _xpAnimation = Tween<double>(begin: _previousXpRatio, end: target).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic),
    );
    _xpAnimController
      ..reset()
      ..forward();
    _previousXpRatio = target;
  }

  @override
  void dispose() {
    _xpAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Hata: $e', style: const TextStyle(color: Colors.red))),
      ),
      data: (user) {
        final displayUser = user ?? const UserModel(
          uid: '',
          displayName: 'Savaşçı',
          email: '',
          level: 1,
          xp: 0,
          xpToNextLevel: 500,
          streak: 0,
          title: 'Acemi Savaşçı',
          stats: {'focus': 5, 'energy': 5, 'knowledge': 5, 'strength': 5},
        );
        final xpRatio = displayUser.xpToNextLevel > 0
            ? displayUser.xp / displayUser.xpToNextLevel
            : 0.0;
        if (_previousXpRatio != xpRatio) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _animateXp(xpRatio));
        }
        return _buildBody(context, displayUser);
      },
    );
  }

  Widget _buildBody(BuildContext context, UserModel user) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeroCard(user),
                const SizedBox(height: 20),
                _buildStatsRow(user),
                const SizedBox(height: 20),
                _buildSectionTitle('Günlük Görevler', Icons.local_fire_department),
                const SizedBox(height: 12),
                _buildQuestCard('1 Saat Kitap Oku', '+50 XP', Icons.menu_book, 0.7),
                _buildQuestCard('Spor Yap', '+100 XP', Icons.fitness_center, 0.0),
                _buildQuestCard('2 Pomodoro Tamamla', '+80 XP', Icons.timer, 1.0, done: true),
                const SizedBox(height: 20),
                _buildSectionTitle('Son Aktiviteler', Icons.history),
                const SizedBox(height: 12),
                _buildActivityCard('Ders Çalışma', '2 saat önce', '+120 XP', Icons.school),
                _buildActivityCard('Spor', 'Dün', '+100 XP', Icons.fitness_center),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: AppColors.background,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ).createShader(bounds),
        child: const Text(
          'ASCEND',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Colors.white),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text('${user.streak} Gün', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: const CircleAvatar(radius: 18, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 20)),
          color: AppColors.cardBackground,
          onSelected: (val) async {
            if (val == 'signout') {
              await ref.read(authRepositoryProvider).signOut();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'signout', child: Row(
              children: [Icon(Icons.logout, color: Colors.white70, size: 18), SizedBox(width: 8), Text('Çıkış Yap', style: TextStyle(color: Colors.white))],
            )),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.secondary.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 2)],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text('LVL ${user.level} · ${user.title}',
                          style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 6),
                    Text(user.displayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('XP', style: TextStyle(
                color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13,
                shadows: [Shadow(color: AppColors.success.withValues(alpha: 0.8), blurRadius: 6)],
              )),
              Text('${user.xp} / ${user.xpToNextLevel}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _xpAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  Container(height: 10, decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(
                    widthFactor: _xpAnimation.value.clamp(0.0, 1.0),
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.success, AppColors.secondary]),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 1)],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Text('${user.xpToNextLevel - user.xp} XP kaldı → Level ${user.level + 1}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserModel user) {
    final stats = user.stats;
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.psychology, 'Odak', '${stats['focus'] ?? 0}', AppColors.secondary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.bolt, 'Enerji', '${stats['energy'] ?? 0}', AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.auto_stories, 'Bilgi', '${stats['knowledge'] ?? 0}', Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildQuestCard(String title, String reward, IconData icon, double progress, {bool done = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done ? AppColors.success.withValues(alpha: 0.4) : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (done ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: done ? AppColors.success : AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      color: done ? AppColors.textSecondary : Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
                    const SizedBox(height: 2),
                    Text(reward, style: const TextStyle(color: AppColors.success, fontSize: 12)),
                  ],
                ),
              ),
              done
                  ? const Icon(Icons.check_circle, color: AppColors.success, size: 24)
                  : IconButton(icon: const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary), onPressed: () {}),
            ],
          ),
          if (!done && progress > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, String time, String xp, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(xp, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
