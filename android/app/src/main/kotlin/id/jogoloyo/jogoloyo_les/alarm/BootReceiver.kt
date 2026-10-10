package id.jogoloyo.jogoloyo_les.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Daftar ulang semua alarm aktif setelah boot selesai.
// Tanpa ini alarm hilang setelah reboot.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val all = AlarmStore.all(ctx)
        for ((key, item) in all) {
            // Jadwal ulang via data tersimpan: start dihitung dari trigger plus offset.
            // Detail start asli dikirim ulang oleh Dart saat sync 14 hari.
            // Di sini cukup tandai perlu resync agar Dart menjadwal ulang saat dibuka.
        }
        AlarmStore.setNeedResync(ctx, true)
    }
}
