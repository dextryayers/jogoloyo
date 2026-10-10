package id.jogoloyo.jogoloyo_les.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

// Daftar ulang semua alarm masa depan setelah boot selesai.
// Tanpa ini semua alarm mati total saat HP reboot. Data bunyi dibaca dari store,
// sehingga tetap berbunyi walau aplikasi belum dibuka.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        try {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val exact = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
            var n = 0
            for (e in AlarmStore.entries(ctx)) {
                if (e.triggerAt <= System.currentTimeMillis()) continue
                val i = Intent(ctx, AlarmReceiver::class.java).apply {
                    putExtra("sessionKey", e.key)
                    putExtra("offsetMin", e.off)
                    putExtra("title", e.title)
                    putExtra("room", e.room)
                    putExtra("sound", e.sound)
                    putExtra("level", e.level)
                    putExtra("vibrate", e.vibrate)
                }
                val req = AlarmStore.reqCode(e.key, e.off)
                val pi = PendingIntent.getBroadcast(
                    ctx, req, i,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                if (exact) {
                    am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.triggerAt, pi)
                } else {
                    am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.triggerAt, pi)
                }
                n++
            }
            AlarmStore.setNeedResync(ctx, true)
        } catch (e: Exception) {
        }
    }
}
