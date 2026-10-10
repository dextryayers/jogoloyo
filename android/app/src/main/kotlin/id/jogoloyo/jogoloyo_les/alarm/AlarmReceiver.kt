package id.jogoloyo.jogoloyo_les.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Menerima trigger alarm dan membangun notifikasi lokal.
// H-10 dan H-0 pakai prioritas tinggi. Selain itu biasa.
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val key = intent.getStringExtra("sessionKey") ?: return
        val off = intent.getIntExtra("offsetMin", 30)
        val title = intent.getStringExtra("title") ?: "Jadwal les"
        val room = intent.getStringExtra("room") ?: ""
        val urgent = off <= 10
        NotificationHelper.show(ctx, key, off, title, room, urgent)
        AlarmStore.markFired(ctx, key, off)
    }
}
