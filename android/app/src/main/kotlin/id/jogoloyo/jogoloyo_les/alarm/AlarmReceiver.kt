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
        // Hanya H-0 yang alarm sungguhan: bunyi keras plus getar kuat dan layar penuh.
        // Offset 10 menit hanya pengingat biasa tanpa bunyi.
        val urgent = off == 0
        if (urgent) {
            AlarmSoundPlayer.play(ctx, sound, level, vibrate, loop = true)
            NotificationHelper.show(ctx, key, off, title, room, urgent = true, silent = false, vibrate = vibrate, sound = sound, level = level)
        } else {
            if (vibrate) AlarmSoundPlayer.vibrate(ctx, strong = false)
            NotificationHelper.show(ctx, key, off, title, room, urgent = false, silent = true, vibrate = vibrate, sound = sound, level = level)
        }
        AlarmStore.markFired(ctx, key, off, daily)
        if (daily && off == 0) {
            // Alarm harian: daftar ulang pengingat 10 menit dan alarm untuk besok.
            val entry = AlarmStore.entries(ctx).firstOrNull { it.key == key && it.off == 0 }
            val nextStartMillis = entry?.triggerAt
                ?: (System.currentTimeMillis() + 24L * 60 * 60 * 1000L)
            AlarmScheduler.schedule(
                ctx, key, Instant.ofEpochMilli(nextStartMillis).toString(), listOf(10, 0),
                title, room, sound, level, vibrate, true
            )
        }
    }
}
