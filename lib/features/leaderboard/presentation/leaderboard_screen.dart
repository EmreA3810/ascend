import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/sound_effects.dart';
import '../../user/providers/user_provider.dart';
import '../../user/data/user_model.dart';
import '../../clubs/data/club_model.dart';
import '../../clubs/providers/club_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _leagueTabController;
  late Timer _countdownTimer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _leagueTabController = TabController(length: 4, vsync: this);
    _calculateTimeLeft();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTimeLeft());
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _leagueTabController.dispose();
    _countdownTimer.cancel();
    super.dispose();
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    // Sunday 23:59:59 of this week
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final endOfWeek = DateTime(now.year, now.month, now.day + daysUntilSunday, 23, 59, 59);
    final diff = endOfWeek.difference(now);
    if (mounted) {
      setState(() {
        _timeLeft = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${days}g ${hours.toString().padLeft(2, '0')}s ${minutes.toString().padLeft(2, '0')}d ${seconds.toString().padLeft(2, '0')}sn';
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
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 24),
        title: Text(
          'LİG & KULÜPLER',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_rounded, size: 18), text: 'Genel Lig'),
            Tab(icon: Icon(Icons.shield_rounded, size: 18), text: 'Kulübüm & Arkadaşlar'),
          ],
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _mainTabController,
              children: [
                _buildLiveLeagueTab(user),
                _buildClubTab(user),
              ],
            ),
    );
  }

  // ===========================================================================
  // 1. CANLI GENEL LİG TAB (DEMO KİŞİLER YOK - TAMAMEN GERÇEK KULLANICILAR)
  // ===========================================================================
  Widget _buildLiveLeagueTab(UserModel currentUser) {
    final liveUsersAsync = ref.watch(liveAllUsersProvider);

    return Column(
      children: [
        _buildWeeklyCountdownBanner(),
        Container(
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _leagueTabController,
            indicator: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: '🥉 Bronz'),
              Tab(text: '🥈 Gümüş'),
              Tab(text: '🥇 Altın'),
              Tab(text: '💎 Elmas'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: liveUsersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Hata: $err', style: GoogleFonts.inter(color: Colors.redAccent))),
            data: (allUsers) {
              return TabBarView(
                controller: _leagueTabController,
                children: [
                  _buildTierLeagueView(allUsers, currentUser, 'bronz', const Color(0xFFCD7F32)),
                  _buildTierLeagueView(allUsers, currentUser, 'gumus', const Color(0xFFC0C0C0)),
                  _buildTierLeagueView(allUsers, currentUser, 'altin', const Color(0xFFFFD700)),
                  _buildTierLeagueView(allUsers, currentUser, 'elmas', const Color(0xFF67E8F9)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTierLeagueView(
    List<UserModel> allUsers,
    UserModel currentUser,
    String leagueTier,
    Color leagueColor,
  ) {
    // Sadece bu lige ait olan veya tüm gerçek kullanıcılar
    final tierUsers = allUsers.where((u) {
      final tier = u.leagueTier.toLowerCase();
      if (leagueTier == 'bronz') {
        return tier == 'bronz' || tier.isEmpty;
      }
      return tier == leagueTier;
    }).toList();

    // Haftalık XP'ye göre sırala
    tierUsers.sort((a, b) {
      final cmp = b.weeklyXp.compareTo(a.weeklyXp);
      if (cmp != 0) return cmp;
      return b.xp.compareTo(a.xp);
    });

    final userRankIndex = tierUsers.indexWhere((u) => u.uid == currentUser.uid);

    if (tierUsers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.military_tech_outlined, size: 54, color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'Bu ligde henüz yarışan savaşçı yok!',
                style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Görev yaparak veya arkadaşlarını davet ederek lige ilk adımı sen at!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🟢 İlk 3: Üst Lige Terfi & Altın Ödülü',
                style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                '⚡ Toplam: ${tierUsers.length} Savaşçı',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Dinamik Gerçek Kullanıcı Podyumu
        _buildDynamicRealPodium(tierUsers, currentUser),
        const SizedBox(height: 8),
        // Kalan gerçek kullanıcılar listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: tierUsers.length > 3 ? tierUsers.length - 3 : 0,
            itemBuilder: (context, index) {
              final rank = index + 4;
              final warrior = tierUsers[index + 3];
              final isCurrentUser = warrior.uid == currentUser.uid;

              return _buildRealUserRow(rank, warrior, isCurrentUser);
            },
          ),
        ),
        // Ekranın altına sabitlenen kullanıcı durum çubuğu
        if (userRankIndex != -1)
          _buildPinnedUserBar(userRankIndex + 1, tierUsers[userRankIndex]),
      ],
    );
  }

  Widget _buildDynamicRealPodium(List<UserModel> warriors, UserModel currentUser) {
    if (warriors.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Sıra (Varsa)
          if (warriors.length >= 2)
            _buildRealPodiumStep(warriors[1], 2, 75, const Color(0xFFC0C0C0), '🥈 300 🪙', currentUser)
          else
            const Expanded(child: SizedBox()),

          // 1. Sıra (Mutlaka var)
          _buildRealPodiumStep(warriors[0], 1, 100, const Color(0xFFFFD700), '👑 500 🪙', currentUser),

          // 3. Sıra (Varsa)
          if (warriors.length >= 3)
            _buildRealPodiumStep(warriors[2], 3, 60, const Color(0xFFCD7F32), '🥉 150 🪙', currentUser)
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildRealPodiumStep(
    UserModel warrior,
    int rank,
    double height,
    Color color,
    String reward,
    UserModel currentUser,
  ) {
    final isMe = warrior.uid == currentUser.uid;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: isMe ? 24 : 20,
                backgroundColor: color.withValues(alpha: 0.25),
                child: Text(
                  isMe ? '⭐' : (warrior.displayName.isNotEmpty ? warrior.displayName[0].toUpperCase() : '⚔️'),
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (rank == 1)
                const Positioned(
                  top: -16,
                  child: Text('👑', style: TextStyle(fontSize: 18)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isMe ? '${warrior.displayName} (Sen)' : warrior.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: isMe ? Colors.amberAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            '${warrior.weeklyXp} XP',
            style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$rank',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Text(
                  reward,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealUserRow(int rank, UserModel warrior, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.2)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentUser ? AppColors.primary : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white12,
            child: Text(
              isCurrentUser ? '⭐' : (warrior.displayName.isNotEmpty ? warrior.displayName[0].toUpperCase() : '⚔️'),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isCurrentUser ? '${warrior.displayName} (Sen)' : warrior.displayName,
                      style: GoogleFonts.inter(
                        color: isCurrentUser ? Colors.amberAccent : Colors.white,
                        fontWeight: isCurrentUser ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (warrior.clubTag != null && warrior.clubTag!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '[${warrior.clubTag}]',
                          style: GoogleFonts.inter(color: AppColors.secondary, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Sv. ${warrior.level} · ${warrior.title}',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${warrior.weeklyXp} XP',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedUserBar(int rank, UserModel warrior) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          top: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Senin Canlı Sıran', style: GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
                  Text(
                    rank <= 3 ? '🎉 Podyumdasın, devam et!' : 'Haftalık yarıştasın!',
                    style: GoogleFonts.inter(
                      color: rank <= 3 ? Colors.greenAccent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${warrior.weeklyXp} XP',
                style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCountdownBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Hafta Kapanışına:',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            _formatDuration(_timeLeft),
            style: GoogleFonts.inter(
              color: Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. KULÜBÜM & ARKADAŞLAR TAB (KULÜP SİSTEMİ & ARKADAŞ DAVET)
  // ===========================================================================
  Widget _buildClubTab(UserModel currentUser) {
    final clubAsync = ref.watch(userClubProvider);

    return clubAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Kulüp yüklenemedi: $err', style: GoogleFonts.inter(color: Colors.redAccent))),
      data: (club) {
        if (club == null) {
          return _buildNoClubView(currentUser);
        }
        return _buildActiveClubView(club, currentUser);
      },
    );
  }

  /// Henüz bir kulübü olmayan kullanıcı için Kulüp Kur & Katıl ekranı
  Widget _buildNoClubView(UserModel currentUser) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
            ),
            child: const Center(child: Text('🏰', style: TextStyle(fontSize: 44))),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Kulüp Kur veya Arkadaşlarına Katıl!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'Arkadaşlarınla birlikte kendi özel kulübünü oluştur, birbirinizi haftalık XP yarışına davet edin ve birlikte zirveye tırmanın!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          icon: const Icon(Icons.shield_outlined, size: 20),
          label: Text('Yeni Kulüp Oluştur', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _showCreateClubDialog(context, currentUser),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.vpn_key_rounded, size: 20, color: Colors.cyanAccent),
          label: Text('Davet Kodu ile Kulübe Katıl', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.cyanAccent)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.cyanAccent, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => _showJoinClubDialog(context, currentUser),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('💡 Kulüp Avantajları:', style: GoogleFonts.inter(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildPerkRow('👥 Arkadaşlarınla anlık puan kapışması ve özel sıralama'),
              _buildPerkRow('🏷️ Profilinde ve ligde parlayan özel kulüp etiketi [TAG]'),
              _buildPerkRow('📲 6 Haneli davet koduyla tek tıkla arkadaş çağırma'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerkRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Aktif kulübe sahip kullanıcı için Kulüp Ekranı
  Widget _buildActiveClubView(ClubModel club, UserModel currentUser) {
    final membersAsync = ref.watch(clubMembersProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (err, _) => Center(child: Text('Üyeler yüklenemedi: $err', style: GoogleFonts.inter(color: Colors.redAccent))),
      data: (members) {
        final totalWeeklyXp = members.fold<int>(0, (sum, m) => sum + m.weeklyXp);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kulüp Başlık Kartı
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.35),
                    AppColors.cardBackground,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white10,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(club.iconEmoji, style: const TextStyle(fontSize: 32)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        club.name,
                                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          '[${club.tag}]',
                                          style: GoogleFonts.inter(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (club.creatorUid == currentUser.uid)
                                  InkWell(
                                    onTap: () => _showEditClubDialog(context, club, currentUser),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white12,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.edit_rounded, color: Colors.amberAccent, size: 18),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              club.description.isNotEmpty ? club.description : 'Savaşçılar Kulübü',
                              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildClubStatItem('Üyeler', '${members.length}', Icons.people_alt_rounded, Colors.cyanAccent),
                      _buildClubStatItem('Toplam XP', '$totalWeeklyXp', Icons.flash_on_rounded, Colors.amber),
                      _buildClubStatItem('Kurucu', club.creatorName, Icons.workspace_premium_rounded, Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Arkadaş Davet Et Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: Text('Arkadaşını Davet Et (Kod: ${club.inviteCode})', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _showInviteDialog(context, club),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⚔️ Kulüp İçi Sıralama',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Haftalık XP',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...members.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final member = entry.value;
              final isMe = member.uid == currentUser.uid;

              return _buildRealUserRow(rank, member, isMe);
            }),
            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                label: Text('Kulüpten Ayrıl', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () => _showLeaveClubConfirmation(context, currentUser, club),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildClubStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  // ===========================================================================
  // DIALOGLAR: KULÜP KURMA, KATILMA, DAVET ETME, AYRILMA
  // ===========================================================================
  void _showCreateClubDialog(BuildContext context, UserModel currentUser) {
    final nameCtrl = TextEditingController();
    final tagCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedEmoji = '⚔️';
    final emojis = ['⚔️', '🛡️', '🐺', '⚡', '🔥', '👑', '🦅', '🏹'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.add_moderator_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Yeni Kulüp Kur', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kulüp İkonu:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: emojis.map((e) {
                        final isSel = e == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? AppColors.primary.withValues(alpha: 0.4) : Colors.white10,
                              border: Border.all(color: isSel ? AppColors.primary : Colors.transparent),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kulüp Adı',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        hintText: 'Örn: Gece Avcıları',
                        hintStyle: GoogleFonts.inter(color: Colors.white24),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagCtrl,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kulüp Etiketi (3-5 Harf)',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        hintText: 'Örn: NIGHT',
                        hintStyle: GoogleFonts.inter(color: Colors.white24),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        counterStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Açıklama / Manifesto',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        hintText: 'Birlikte zirveye tırmanıyoruz!',
                        hintStyle: GoogleFonts.inter(color: Colors.white24),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('İptal', style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final tag = tagCtrl.text.trim();
                    if (name.isEmpty || tag.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen kulüp adı ve etiketini girin!')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    try {
                      final created = await ref.read(clubRepositoryProvider).createClub(
                            uid: currentUser.uid,
                            userName: currentUser.displayName,
                            name: name,
                            tag: tag,
                            description: descCtrl.text.trim(),
                            iconEmoji: selectedEmoji,
                          );

                      ref.invalidate(currentUserProvider);
                      ref.invalidate(userClubProvider);
                      SoundEffects.playVictory();
                      if (!mounted) return;
                      _showInviteDialog(this.context, created);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(backgroundColor: Colors.redAccent, content: Text('Kulüp oluşturulamadı: $e')),
                      );
                    }
                  },
                  child: Text('Kulübü Kur', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditClubDialog(BuildContext context, ClubModel club, UserModel currentUser) {
    final nameCtrl = TextEditingController(text: club.name);
    final tagCtrl = TextEditingController(text: club.tag);
    final descCtrl = TextEditingController(text: club.description);
    String selectedEmoji = club.iconEmoji;
    final emojis = ['⚔️', '🛡️', '🐺', '⚡', '🔥', '👑', '🦅', '🏹', '🚀', '💎'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Kulüp Ayarlarını Düzenle', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kulüp İkonu:', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: emojis.take(5).map((e) {
                        final isSel = e == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? AppColors.primary.withValues(alpha: 0.4) : Colors.white10,
                              border: Border.all(color: isSel ? AppColors.primary : Colors.transparent),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: emojis.skip(5).map((e) {
                        final isSel = e == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedEmoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSel ? AppColors.primary.withValues(alpha: 0.4) : Colors.white10,
                              border: Border.all(color: isSel ? AppColors.primary : Colors.transparent),
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 20)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kulüp Adı',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagCtrl,
                      maxLength: 5,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kulüp Etiketi (3-5 Harf)',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        counterStyle: const TextStyle(color: Colors.white38),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Açıklama / Manifesto',
                        labelStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('İptal', style: GoogleFonts.inter(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final tag = tagCtrl.text.trim();
                    if (name.isEmpty || tag.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lütfen kulüp adı ve etiketini girin!')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await ref.read(clubRepositoryProvider).updateClubSettings(
                            clubId: club.id,
                            name: name,
                            tag: tag,
                            description: descCtrl.text.trim(),
                            iconEmoji: selectedEmoji,
                            currentUserId: currentUser.uid,
                          );

                      ref.invalidate(currentUserProvider);
                      ref.invalidate(userClubProvider);
                      SoundEffects.playStatUp();
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text('✨ Kulüp bilgileri başarıyla güncellendi!'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(backgroundColor: Colors.redAccent, content: Text('Kulüp güncellenemedi: $e')),
                      );
                    }
                  },
                  child: Text('Kaydet', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJoinClubDialog(BuildContext context, UserModel currentUser) {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Text('Kulübe Katıl', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Arkadaşının sana gönderdiği 6 haneli kulüp davet kodunu gir:',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inter(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Örn: ASC982',
                  hintStyle: GoogleFonts.inter(color: Colors.white24, letterSpacing: 1),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('İptal', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final code = codeCtrl.text.trim();
                if (code.isEmpty) return;

                Navigator.pop(ctx);
                try {
                  final club = await ref.read(clubRepositoryProvider).joinClubByCode(
                        uid: currentUser.uid,
                        inviteCode: code,
                      );

                  ref.invalidate(currentUserProvider);
                  ref.invalidate(userClubProvider);

                  if (!mounted) return;
                  if (club != null) {
                    SoundEffects.playVictory();
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Harika! "${club.name}" kulübüne katıldın 🎉', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.redAccent,
                        content: Text('Geçersiz davet kodu! Kulüp bulunamadı.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(backgroundColor: Colors.redAccent, content: Text('Hata: $e')),
                  );
                }
              },
              child: Text('Katıl', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context, ClubModel club) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Arkadaşını Davet Et', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Arkadaşına bu kodu vererek "${club.name}" kulübüne çağır:',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      club.inviteCode,
                      style: GoogleFonts.inter(
                        color: Colors.amber,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      tooltip: 'Kodu Kopyala',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: club.inviteCode));
                        SoundEffects.playStatUp();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.amber.shade800,
                            content: Text('Davet kodu panoya kopyalandı! 📋 (${club.inviteCode})', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Arkadaşın "Kulübe Katıl" butonuna bu kodu girdiğinde doğrudan kulübünün üyesi olacaktır.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tamam', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showLeaveClubConfirmation(BuildContext context, UserModel currentUser, ClubModel club) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Kulüpten Ayrıl?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(
            '"${club.name}" kulübünden ayrılmak istediğine emin misin?',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Vazgeç', style: GoogleFonts.inter(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(clubRepositoryProvider).leaveClub(
                        uid: currentUser.uid,
                        clubId: club.id,
                      );
                  ref.invalidate(currentUserProvider);
                  ref.invalidate(userClubProvider);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Kulüpten ayrıldın.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(backgroundColor: Colors.redAccent, content: Text('Hata: $e')),
                  );
                }
              },
              child: const Text('Ayrıl'),
            ),
          ],
        );
      },
    );
  }
}
