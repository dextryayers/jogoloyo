package id.jogoloyo.jogoloyo_les.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.time.Instant

// Penjadwal alarm exact lokal. ID unik dari hash session plus profile plus offset.
// Semua waktu dalam UTC millis. Tidak ada server, tidak ada FCM.
object AlarmScheduler {
    fun schedule(
        ctx: Context,
        sessionKey: String,
        startUtcIso: String,
        offsetsMinutes: List<Int>,
        title: String,
        room: String,
        sound: String = "suara1",
        level: Int = 200,
        vibrate: Boolean = true
    ): Boolean {
        return try {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val start = Instant.parse(startUtcIso).toEpochMilli()
            for (off in offsetsMinutes) {
                val trigger = start - off * 60L * 1000L
                if (trigger <= System.currentTimeMillis()) continue
                val req = reqCode(sessionKey, off)
                val i = Intent(ctx, AlarmReceiver::class.java).apply {
                    putExtra("sessionKey", sessionKey)
                    putExtra("offsetMin", off)
                    putExtra("title", title)
                    putExtra("room", room)
                    putExtra("sound", sound)
                    putExtra("level", level)
                    putExtra("vibrate", vibrate)
                }
                val pi = PendingIntent.getBroadcast(
                    ctx, req, i,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                if (Build.VERSION.SDK_INT >= 31) {
                    if (am.canScheduleExactAlarms()) {
                        am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
                    } else {
                        am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
                    }
                } else {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pi)
                }
                AlarmStore.put(ctx, sessionKey, off, trigger, title, room, sound, level, vibrate)
            }
            true
        } catch (e: Exception) {
            false
        }
    }

    fun cancel(ctx: Context, sessionKey: String) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (off in listOf(60, 30, 10, 0)) {
            val req = reqCode(sessionKey, off)
            val i = Intent(ctx, AlarmReceiver::class.java)
            val pi = PendingIntent.getBroadcast(
                ctx, req, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            am.cancel(pi)
        }
        AlarmStore.remove(ctx, sessionKey)
    }

    private fun reqCode(sessionKey: String, off: Int): Int {
        return (sessionKey.hashCode() * 31 + off).hashCode() and 0x7FFFFFFF % 1000000 + off
    }
}
