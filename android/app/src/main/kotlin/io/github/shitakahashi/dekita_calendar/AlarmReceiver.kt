package io.github.shitakahashi.dekita_calendar

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log
import java.util.Calendar

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AlarmReceiver"
        private const val CHANNEL_ID = "native_habit_alarms"
        private const val CHANNEL_NAME = "習慣リマインダー（ネイティブ版）"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "AlarmReceiver triggered")

        val habitId = intent.getStringExtra("habitId") ?: "unknown"
        val habitTitle = intent.getStringExtra("habitTitle") ?: "習慣"
        val frequency = intent.getStringExtra("frequency") ?: "unknown"
        val dayOfWeek = intent.getIntExtra("dayOfWeek", -1)
        val alarmHour = intent.getIntExtra("alarmHour", 9)
        val alarmMinute = intent.getIntExtra("alarmMinute", 0)

        Log.d(TAG, "Habit: $habitTitle, ID: $habitId, Frequency: $frequency, DayOfWeek: $dayOfWeek, Time: $alarmHour:$alarmMinute")

        // 通知を表示
        showNotification(context, habitId, habitTitle, frequency)

        // 次のアラームを再設定
        rescheduleAlarm(context, habitId, habitTitle, frequency, dayOfWeek, alarmHour, alarmMinute)
    }
    
    private fun showNotification(context: Context, habitId: String, habitTitle: String, frequency: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Android 8.0以降では通知チャンネルが必要
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "ネイティブAlarmManagerを使用した習慣リマインダー"
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // アプリを開くためのIntent
        val appIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            habitId.hashCode(),
            appIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // 通知を作成
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("習慣のお時間です")
            .setContentText("${habitTitle}の時間になりました！")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 250, 250, 250))
            .setLights(0xFF0000FF.toInt(), 300, 1000)
            .setContentIntent(pendingIntent)
            .build()
        
        // 通知を表示
        val notificationId = habitId.hashCode()
        notificationManager.notify(notificationId, notification)
        
        Log.d(TAG, "Notification shown: $habitTitle (ID: $notificationId)")
    }

    private fun rescheduleAlarm(
        context: Context,
        habitId: String,
        habitTitle: String,
        frequency: String,
        dayOfWeek: Int,
        alarmHour: Int,
        alarmMinute: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        // 次のアラーム時刻を計算
        val calendar = Calendar.getInstance()

        when (frequency) {
            "daily" -> {
                // 毎日の場合：翌日の同じ時刻にアラームを設定
                calendar.add(Calendar.DAY_OF_YEAR, 1)
                calendar.set(Calendar.HOUR_OF_DAY, alarmHour)
                calendar.set(Calendar.MINUTE, alarmMinute)
                calendar.set(Calendar.SECOND, 0)
                calendar.set(Calendar.MILLISECOND, 0)

                val alarmId = habitId.hashCode()
                val nextTriggerTime = calendar.timeInMillis

                Log.d(TAG, "Rescheduling daily alarm for tomorrow at $alarmHour:$alarmMinute: $nextTriggerTime")

                scheduleNextAlarm(context, alarmManager, alarmId, nextTriggerTime, habitId, habitTitle, frequency, -1, alarmHour, alarmMinute)
            }
            "weekly" -> {
                // 週次の場合：翌週の同じ曜日・同じ時刻にアラームを設定
                if (dayOfWeek != -1) {
                    // 翌週の同じ曜日を計算
                    // Flutterのweekday (1=月曜, 7=日曜) をCalendarのDAY_OF_WEEK (1=日曜, 2=月曜, ..., 7=土曜) に変換
                    val calendarDayOfWeek = if (dayOfWeek == 7) Calendar.SUNDAY else dayOfWeek + 1

                    calendar.add(Calendar.WEEK_OF_YEAR, 1)
                    calendar.set(Calendar.DAY_OF_WEEK, calendarDayOfWeek)
                    calendar.set(Calendar.HOUR_OF_DAY, alarmHour)
                    calendar.set(Calendar.MINUTE, alarmMinute)
                    calendar.set(Calendar.SECOND, 0)
                    calendar.set(Calendar.MILLISECOND, 0)

                    val alarmId = "${habitId}_$dayOfWeek".hashCode()
                    val nextTriggerTime = calendar.timeInMillis

                    Log.d(TAG, "Rescheduling weekly alarm for next week (Flutter day $dayOfWeek = Calendar day $calendarDayOfWeek) at $alarmHour:$alarmMinute: $nextTriggerTime")

                    scheduleNextAlarm(context, alarmManager, alarmId, nextTriggerTime, habitId, habitTitle, frequency, dayOfWeek, alarmHour, alarmMinute)
                } else {
                    Log.e(TAG, "Weekly frequency but dayOfWeek is not set!")
                }
            }
            else -> {
                Log.d(TAG, "Frequency '$frequency' does not require rescheduling")
            }
        }
    }

    private fun scheduleNextAlarm(
        context: Context,
        alarmManager: AlarmManager,
        alarmId: Int,
        triggerTimeMillis: Long,
        habitId: String,
        habitTitle: String,
        frequency: String,
        dayOfWeek: Int,
        alarmHour: Int,
        alarmMinute: Int
    ) {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("habitId", habitId)
            putExtra("habitTitle", habitTitle)
            putExtra("frequency", frequency)
            putExtra("alarmHour", alarmHour)
            putExtra("alarmMinute", alarmMinute)
            if (dayOfWeek != -1) {
                putExtra("dayOfWeek", dayOfWeek)
            }
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
                Log.d(TAG, "Next alarm scheduled successfully (ID: $alarmId)")
            } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTimeMillis,
                    pendingIntent
                )
                Log.d(TAG, "Next alarm scheduled successfully (ID: $alarmId)")
            } else {
                Log.e(TAG, "Cannot schedule exact alarms - permission not granted")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling next alarm: ${e.message}")
        }
    }
}