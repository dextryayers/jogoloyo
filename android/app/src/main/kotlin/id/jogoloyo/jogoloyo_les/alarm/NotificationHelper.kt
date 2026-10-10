package id.jogoloyo.jogoloyo_les.alarm

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

// Kanal dan gaya notifikasi. Urgent dibunyikan via MediaPlayer plus getar kuat,
// sehingga notifikasinya silent agar tidak dobel. Info pakai suara dan getar sistem.
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

    // urgent: suara dari MediaPlayer, notifikasi tanpa suara tapi tetap getar
    // sebagai jalur cadangan. silent=true mematikan getar notif juga, jadi
    // tidak dipakai lagi. vibrate=false mematikan semua getar.
    fun show(ctx: Context, key: String, offsetMin: Int, title: String, room: String, urgent: Boolean, silent: Boolean = false, vibrate: Boolean = true) {
        ensure(ctx)
        val text = when (offsetMin) {
            60 -> "60 menit lagi: $title di $room."
            30 -> "30 menit lagi: $title. Aktifkan suara HP."
            10 -> "10 menit lagi masuk kelas. Siapkan buku dan alat tulis."
            else -> "Saatnya masuk: $title di $room."
        }
        val strongPattern = longArrayOf(0, 1200, 400, 1200, 400, 1500)
        val b = NotificationCompat.Builder(ctx, if (urgent) CH_URGENT else CH_INFO)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(text)
            .setPriority(if (urgent) NotificationCompat.PRIORITY_HIGH else NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
        if (urgent) {
            // Tanpa suara (MediaPlayer yang bunyi), tapi getar tetap jalan bila aktif.
            if (vibrate) b.setVibrate(strongPattern)
        } else if (silent) {
            b.setSilent(true)
        } else if (vibrate) {
            b.setDefaults(Notification.DEFAULT_ALL)
        } else {
            b.setDefaults(Notification.DEFAULT_SOUND)
        }
        val n = b.build()
        try {
            NotificationManagerCompat.from(ctx).notify(key.hashCode(), n)
        } catch (e: SecurityException) {
            // Izin mati. Dart menampilkan label Mati dan kartu Buka Pengaturan.
        }
    }
}
