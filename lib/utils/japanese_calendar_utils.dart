class JapaneseCalendarUtils {
  // Japanese weekday names (short form)
  static String getJapaneseDayOfWeek(DateTime date) {
    final dayNames = ['月', '火', '水', '木', '金', '土', '日'];
    // DateTime.weekday: Monday=1, Sunday=7
    // Array starts with Monday, but Sunday is placed at the end
    if (date.weekday == 7) {
      return dayNames[6]; // Sunday
    }
    return dayNames[date.weekday - 1];
  }

  // Japanese weekday names (full form)
  static String getJapaneseDayOfWeekFull(DateTime date) {
    final dayNames = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    if (date.weekday == 7) {
      return dayNames[6]; // Sunday
    }
    return dayNames[date.weekday - 1];
  }
}