package id.jogoloyo.jogoloyo_les.alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

// Kanal dan gaya notifikasi. Nada sopan, tanpa suara mengejutkan.
// Full screen hanya untuk urgent dan jika izin diberikan.
object NotificationHelper {
    private const val CH_INFO = "jogoloyo_info"
    private const val CH_URGENT = "jogoloyo_urgent"

    fun ensure(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(CH_INFO, "Pengingat Les", NotificationManager.IMPORTANCE_DEFAULT)
        )
        nm.createNotificationChannel(
            NotificationChannel(CH_URGENT, "Alarm Masuk Kelas", NotificationManager.IMPORTANCE_HIGH)
        )
    }

    fun show(ctx: Context, key: String, offsetMin: Int, title: String, room: String, urgent: Boolean) {
        ensure(ctx)
        val text = when (offsetMin) {
            60 -> "60 menit lagi: $title di $room."
            30 -> "30 menit lagi: $title. Aktifkan suara HP."
            10 -> "10 menit lagi masuk kelas. Siapkan buku dan alat tulis."
            else -> "Saatnya masuk: $title di $room."
        }
        val n = NotificationCompat.Builder(ctx, if (urgent) CH_URGENT else CH_INFO)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(if (urgent) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(ctx).notify(key.hashCode(), n)
        } catch (e: SecurityException) {
            // Izin mati. Dart menampilkan label Mati dan kartu Buka Pengaturan.
        }
    }
}
