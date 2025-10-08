package io.github.shitakahashi.dekita_calendar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "battery_optimization"
    private val ALARM_CHANNEL = "simple_alarm_test"
    private val NATIVE_ALARM_CHANNEL = "native_alarm_manager"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 既存のバッテリー最適化チャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    val isIgnoring = powerManager.isIgnoringBatteryOptimizations(packageName)
                    result.success(isIgnoring)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "testAlarmManager" -> {
                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, MainActivity::class.java)
                        val pendingIntent = PendingIntent.getActivity(
                            this, 
                            123, 
                            intent, 
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        val triggerTime = System.currentTimeMillis() + 30000 // 30秒後
                        
                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                triggerTime,
                                pendingIntent
                            )
                            result.success("AlarmManager test scheduled for 30 seconds")
                        } else {
                            result.success("Cannot schedule exact alarms")
                        }
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // ネイティブAlarmManagerチャンネル
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success("Native AlarmManager initialized")
                }
                "scheduleAlarm" -> {
                    try {
                        val alarmId = call.argument<Int>("alarmId") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "alarmId is required", null)
                        val triggerTimeMillis = call.argument<Long>("triggerTimeMillis") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "triggerTimeMillis is required", null)
                        val habitId = call.argument<String>("habitId") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "habitId is required", null)
                        val habitTitle = call.argument<String>("habitTitle") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "habitTitle is required", null)
                        val frequency = call.argument<String>("frequency") ?: "unknown"
                        val dayOfWeek = call.argument<Int>("dayOfWeek") ?: -1

                        // triggerTimeMillisから時刻を抽出
                        val calendar = java.util.Calendar.getInstance().apply {
                            timeInMillis = triggerTimeMillis
                        }
                        val alarmHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
                        val alarmMinute = calendar.get(java.util.Calendar.MINUTE)

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager

                        // BroadcastReceiverを使用したIntentを作成
                        val intent = Intent(this, AlarmReceiver::class.java).apply {
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
                            this,
                            alarmId,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )

                        if (alarmManager.canScheduleExactAlarms()) {
                            alarmManager.setExactAndAllowWhileIdle(
                                AlarmManager.RTC_WAKEUP,
                                triggerTimeMillis,
                                pendingIntent
                            )
                            result.success("Native alarm scheduled successfully")
                        } else {
                            result.error("NO_PERMISSION", "Cannot schedule exact alarms", null)
                        }
                    } catch (e: Exception) {
                        result.error("SCHEDULE_ERROR", e.message, null)
                    }
                }
                "cancelAlarm" -> {
                    try {
                        val alarmId = call.argument<Int>("alarmId") ?: return@setMethodCallHandler result.error("INVALID_ARGUMENT", "alarmId is required", null)
                        
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val intent = Intent(this, AlarmReceiver::class.java)
                        val pendingIntent = PendingIntent.getBroadcast(
                            this,
                            alarmId,
                            intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                        
                        alarmManager.cancel(pendingIntent)
                        pendingIntent.cancel()
                        
                        result.success("Native alarm canceled")
                    } catch (e: Exception) {
                        result.error("CANCEL_ERROR", e.message, null)
                    }
                }
                "cancelAllAlarms" -> {
                    result.success("Cancel all alarms - implement as needed")
                }
                "getStatus" -> {
                    try {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val canScheduleExact = alarmManager.canScheduleExactAlarms()
                        result.success("Can schedule exact alarms: $canScheduleExact")
                    } catch (e: Exception) {
                        result.error("STATUS_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
