package id.jogoloyo.jogoloyo_les

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import id.jogoloyo.jogoloyo_les.alarm.AlarmScheduler
import id.jogoloyo.jogoloyo_les.alarm.AlarmSoundPlayer
import id.jogoloyo.jogoloyo_les.alarm.AlarmStore
import id.jogoloyo.jogoloyo_les.alarm.NotificationHelper

class MainActivity : FlutterActivity() {
    private val CH = "jogoloyo/alarm/v1"

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        NotificationHelper.ensure(this)
        MethodChannel(engine.dartExecutor.binaryMessenger, CH).setMethodCallHandler { call, res ->
            when (call.method) {
                "scheduleSessionAlarm" -> {
                    val key = call.argument<String>("sessionId") ?: ""
                    val iso = call.argument<String>("startUtcIso") ?: ""
                    val off = (call.argument<List<Int>>("offsetsMinutes") ?: listOf(30, 10))
                    val title = call.argument<String>("title") ?: "Jadwal les"
                    val room = call.argument<String>("room") ?: ""
                    val sound = call.argument<String>("sound") ?: "suara1"
                    val loud = call.argument<Boolean>("loud") ?: true
                    val ok = AlarmScheduler.schedule(this, key, iso, off, title, room, sound, loud)
                    if (ok) res.success(true) else res.error("SCHEDULER_BUSY", "Gagal menjadwalkan. Coba lagi.", null)
                }
                "cancelSessionAlarm" -> {
                    val key = call.argument<String>("sessionId") ?: ""
                    AlarmScheduler.cancel(this, key)
                    res.success(true)
                }
                "cancelAllAlarms" -> {
                    for ((k, _) in AlarmStore.all(this)) AlarmScheduler.cancel(this, k)
                    res.success(true)
                }
                "testAlarm" -> {
                    val kind = call.argument<String>("kind") ?: "info"
                    val sound = call.argument<String>("sound") ?: "suara1"
                    val loud = call.argument<Boolean>("loud") ?: true
                    if (kind == "urgent") {
                        AlarmSoundPlayer.play(this, sound, loud)
                        NotificationHelper.show(this, "test", 10, "Tes Alarm", "Ruang A", urgent = true, silent = true)
                    } else {
                        NotificationHelper.show(this, "test", 30, "Tes Alarm", "Ruang A", urgent = false, silent = false)
                    }
                    res.success(true)
                }
                "openExactAlarmSettings" -> {
                    try {
                        val i = if (Build.VERSION.SDK_INT >= 31) {
                            Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                        } else {
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        }
                        startActivity(i)
                        res.success(true)
                    } catch (e: Exception) {
                        res.error("PERMISSION_DENIED", "Tidak bisa membuka pengaturan.", null)
                    }
                }
                "arePermissionsGranted" -> {
                    val am = getSystemService(ALARM_SERVICE) as android.app.AlarmManager
                    val exact = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
                    res.success(mapOf("exactAlarm" to exact, "notifications" to true, "fullScreenIntent" to true))
                }
                else -> res.notImplemented()
            }
        }
    }
}
