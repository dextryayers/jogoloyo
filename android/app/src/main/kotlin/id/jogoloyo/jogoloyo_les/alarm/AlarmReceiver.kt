package id.jogoloyo.jogoloyo_les.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.time.Instant

// Menerima trigger alarm: bunyikan suara otomatis plus getar opsional, lalu notifikasi.
// H-10 dan H-0 pakai suara pilihan plus level kekerasan. Selain itu notifikasi biasa.
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val key = intent.getStringExtra("sessionKey") ?: return
        val off = intent.getIntExtra("offsetMin", 30)
        val title = intent.getStringExtra("title") ?: "Jadwal les"
        val room = intent.getStringExtra("room") ?: ""
        val sound = intent.getStringExtra("sound") ?: "suara1"
        val level = intent.getIntExtra("level", 200)
        val vibrate = intent.getBooleanExtra("vibrate", true)
        val daily = intent.getBooleanExtra("daily", false)
        val urgent = off <= 10
        if (urgent) {
            AlarmSoundPlayer.play(ctx, sound, level, vibrate)
            NotificationHelper.show(ctx, key, off, title, room, urgent = true, silent = false, vibrate = vibrate)
        } else {
            if (vibrate) AlarmSoundPlayer.vibrate(ctx, strong = false)
            NotificationHelper.show(ctx, key, off, title, room, urgent = false, silent = false, vibrate = vibrate)
        }
        AlarmStore.markFired(ctx, key, off, daily)
        if (daily) {
            val entry = AlarmStore.entries(ctx).firstOrNull { it.key == key && it.off == off }
            val nextStartMillis = (entry?.triggerAt ?: System.currentTimeMillis()) + off * 60L * 1000L + 24L * 60 * 60 * 1000L
            AlarmScheduler.schedule(
                ctx, key, Instant.ofEpochMilli(nextStartMillis).toString(), listOf(off),
                title, room, sound, level, vibrate, true
            )
        }
    }
}
