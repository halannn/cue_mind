import 'package:flutter/material.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static int toUtcMillis(DateTime localDateTime) {
    return localDateTime.toUtc().millisecondsSinceEpoch;
  }

  static DateTime fromUtcMillis(int millisSinceEpoch) {
    return DateTime.fromMillisecondsSinceEpoch(
      millisSinceEpoch,
      isUtc: true,
    ).toLocal();
  }

  static DateTime now() {
    return DateTime.now();
  }

  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  static DateTime toUtc(DateTime localDateTime) {
    return localDateTime.toUtc();
  }

  static DateTime toLocal(DateTime utcDateTime) {
    return utcDateTime.toLocal();
  }

  static DateTime startOfDayUtc(DateTime localDate) {
    final localStartOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      0,
      0,
      0,
    );
    return localStartOfDay.toUtc();
  }

  static DateTime endOfDayUtc(DateTime localDate) {
    final localEndOfDay = DateTime(
      localDate.year,
      localDate.month,
      localDate.day,
      23,
      59,
      59,
      999,
    );
    return localEndOfDay.toUtc();
  }

  static DateTime startOfMonthUtc(DateTime localDate) {
    final localStartOfMonth = DateTime(localDate.year, localDate.month, 1);
    return localStartOfMonth.toUtc();
  }

  static DateTime endOfMonthUtc(DateTime localDate) {
    final localEndOfMonth = DateTime(
      localDate.year,
      localDate.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));
    return localEndOfMonth.toUtc();
  }

  static DateTime combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static TimeOfDay timeOfDay(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  static int hoursFromNowUtcMillis(int hours) {
    return DateTime.now()
        .add(Duration(hours: hours))
        .toUtc()
        .millisecondsSinceEpoch;
  }
}
