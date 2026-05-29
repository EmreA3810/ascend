class AchievementDefinitions {
  AchievementDefinitions._();

  static const List<Map<String, dynamic>> all = [
    // Streak
    {'id': 'streak_3', 'title': 'İlk Seri', 'description': '3 gün üst üste çalış', 'icon': '🔥', 'requiredValue': 3, 'xpReward': 50, 'category': 'streak'},
    {'id': 'streak_7', 'title': 'Ateş Savaşçısı', 'description': '7 gün streak', 'icon': '🔥', 'requiredValue': 7, 'xpReward': 100, 'category': 'streak'},
    {'id': 'streak_30', 'title': 'Durdurulamaz', 'description': '30 gün streak', 'icon': '🔥', 'requiredValue': 30, 'xpReward': 500, 'category': 'streak'},

    // Pomodoro
    {'id': 'pomo_10', 'title': 'Odak Ustası', 'description': '10 pomodoro tamamla', 'icon': '⏱️', 'requiredValue': 10, 'xpReward': 100, 'category': 'pomodoro'},
    {'id': 'pomo_50', 'title': 'Pomodoro Kralı', 'description': '50 pomodoro tamamla', 'icon': '⏱️', 'requiredValue': 50, 'xpReward': 300, 'category': 'pomodoro'},
    {'id': 'pomo_100', 'title': 'Zaman Bükücü', 'description': '100 pomodoro tamamla', 'icon': '⏱️', 'requiredValue': 100, 'xpReward': 500, 'category': 'pomodoro'},

    // Quest
    {'id': 'quest_1', 'title': 'İlk Görev', 'description': '1 görev tamamla', 'icon': '⚔️', 'requiredValue': 1, 'xpReward': 25, 'category': 'quest'},
    {'id': 'quest_25', 'title': 'Görev Avcısı', 'description': '25 görev tamamla', 'icon': '⚔️', 'requiredValue': 25, 'xpReward': 200, 'category': 'quest'},
    {'id': 'quest_100', 'title': 'Efsanevi Kahraman', 'description': '100 görev tamamla', 'icon': '⚔️', 'requiredValue': 100, 'xpReward': 500, 'category': 'quest'},

    // Level
    {'id': 'level_5', 'title': 'Yükselen Güç', 'description': 'Level 5 ulaş', 'icon': '📈', 'requiredValue': 5, 'xpReward': 100, 'category': 'level'},
    {'id': 'level_10', 'title': 'Deneyimli', 'description': 'Level 10 ulaş', 'icon': '📈', 'requiredValue': 10, 'xpReward': 200, 'category': 'level'},
    {'id': 'level_20', 'title': 'Usta', 'description': 'Level 20 ulaş', 'icon': '📈', 'requiredValue': 20, 'xpReward': 500, 'category': 'level'},
    {'id': 'level_50', 'title': 'Efsane', 'description': 'Level 50 ulaş', 'icon': '📈', 'requiredValue': 50, 'xpReward': 1000, 'category': 'level'},

    // Stat
    {'id': 'stat_10', 'title': 'Çok Yönlü', 'description': 'Her stat 10+', 'icon': '💪', 'requiredValue': 10, 'xpReward': 200, 'category': 'stat'},
    {'id': 'stat_25', 'title': 'Dengeli Güç', 'description': 'Her stat 25+', 'icon': '💪', 'requiredValue': 25, 'xpReward': 500, 'category': 'stat'},
  ];
}
