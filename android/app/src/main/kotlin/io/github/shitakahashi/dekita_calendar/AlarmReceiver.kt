package io.github.shitakahashi.dekita_calendar

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.util.Log

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
        
        Log.d(TAG, "Habit: $habitTitle, ID: $habitId, Frequency: $frequency")
        
        // 通知を表示
        showNotification(context, habitId, habitTitle, frequency)
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
        
        // 日次の場合は次の日のアラームを設定（簡単な実装）
        if (frequency == "daily") {
            Log.d(TAG, "Daily habit notification completed, should reschedule for tomorrow")
            // 実際のプロダクションでは、ここで次の日のアラームを再設定する
        }
    }
}