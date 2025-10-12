class JapaneseCalendarUtils {
  // Japanese weekday names (short form)
  static String getJapaneseDayOfWeek(DateTime date) {
    final dayNames = ['日', '月', '火', '水', '木', '金', '土'];
    // DateTime.weekday: Monday=1, Sunday=7
    // Array starts with Sunday (index 0)
    if (date.weekday == 7) {
      return dayNames[0]; // Sunday
    }
    return dayNames[date.weekday];
  }

  // Japanese weekday names (full form)
  static String getJapaneseDayOfWeekFull(DateTime date) {
    final dayNames = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
    if (date.weekday == 7) {
      return dayNames[0]; // Sunday
    }
    return dayNames[date.weekday];
  }
}