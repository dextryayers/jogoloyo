package id.jogoloyo.jogoloyo_les.alarm

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

// Kanal dan gaya notifikasi. Urgent dibunyikan via MediaPlayer plus getar kuat,
// sehingga notifikasinya silent agar tidak dobel. Info pakai suara dan getar sistem.
object NotificationHelper {
    private const val CH_INFO = "jogoloyo_info"
    private const val CH_URGENT = "jogoloyo_urgent"

    // Pola getar. Panjang harus genap: jeda, getar, jeda, getar.
    private val STRONG_PATTERN = longArrayOf(0, 1000, 300, 1000, 300, 1200)
    private val SOFT_PATTERN = longArrayOf(0, 300, 200, 300)

    fun ensure(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val info = NotificationChannel(CH_INFO, "Pengingat Les", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Pengingat 10 menit sebelum jam alarm."
            enableVibration(true)
            vibrationPattern = SOFT_PATTERN
            enableLights(true)
            setShowBadge(true)
        }
        val urgent = NotificationChannel(CH_URGENT, "Alarm Masuk Kelas", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Alarm bunyi dan getar saat jam sudah masuk."
            enableVibration(true)
            vibrationPattern = STRONG_PATTERN
            enableLights(true)
            lightColor = Color.parseColor("#1B5E20")
            setBypassDnd(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(info)
        nm.createNotificationChannel(urgent)
    }

    // ID berbeda supaya pengingat H-10 dan alarm H-0 tidak saling menimpa.
    private fun notifId(key: String, offsetMin: Int): Int = (key.hashCode() * 31 + offsetMin) and 0x7FFFFFFF

    // urgent: suara dari MediaPlayer, notifikasi tanpa suara tapi tetap getar
    // sebagai jalur cadangan. silent=true mematikan getar notif juga, jadi
    // tidak dipakai lagi. vibrate=false mematikan semua getar.
    fun show(
        ctx: Context,
        key: String,
        offsetMin: Int,
        title: String,
        room: String,
        urgent: Boolean,
        silent: Boolean = false,
        vibrate: Boolean = true,
        sound: String = "suara1",
        level: Int = 200,
    ) {
        ensure(ctx)
        val text = when (offsetMin) {
            60 -> "60 menit lagi: $title di $room."
            30 -> "30 menit lagi: $title. Aktifkan suara HP."
            10 -> "10 menit lagi masuk kelas. Siapkan buku dan alat tulis."
            else -> "Saatnya masuk: $title di $room."
        }
        val b = NotificationCompat.Builder(ctx, if (urgent) CH_URGENT else CH_INFO)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(if (urgent) title else "Pengingat 10 menit")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setColor(if (urgent) Color.parseColor("#C62828") else Color.parseColor("#1B5E20"))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(if (urgent) NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(urgent)
            .setAutoCancel(!urgent)
        if (urgent) {
            // Layar penuh seperti panggilan masuk. Usap ke atas untuk hentikan.
            val fsIntent = Intent(ctx, AlarmFullScreenActivity::class.java).apply {
                putExtra("sessionKey", key)
                putExtra("offsetMin", offsetMin)
                putExtra("title", title)
                putExtra("room", room)
                putExtra("sound", sound)
                putExtra("level", level)
                putExtra("vibrate", vibrate)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val fsPi = PendingIntent.getActivity(
                ctx, key.hashCode() + 777, fsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            b.setFullScreenIntent(fsPi, true)
            // Tanpa suara (MediaPlayer yang bunyi), tapi getar tetap jalan bila aktif.
            if (vibrate) b.setVibrate(STRONG_PATTERN)
        } else if (silent || !vibrate) {
            // Pengingat H-10 tidak perlu bunyi. Getar ringan mengikuti kanal.
            b.setVibrate(SOFT_PATTERN)
        } else {
            b.setVibrate(SOFT_PATTERN)
        }
        val n = b.build()
        try {
            NotificationManagerCompat.from(ctx).notify(notifId(key, offsetMin), n)
        } catch (e: SecurityException) {
            // Izin mati. Dart menampilkan label Mati dan kartu Buka Pengaturan.
        }
    }

    // Dipanggil layar penuh saat pengguna menghentikan alarm.
    fun cancel(ctx: Context, key: String, offsetMin: Int = 0) {
        try {
            NotificationManagerCompat.from(ctx).cancel(notifId(key, offsetMin))
        } catch (e: Exception) {
        }
    }

    fun cancelAll(ctx: Context, key: String) {
        try {
            val nm = NotificationManagerCompat.from(ctx)
            for (o in listOf(0, 10, 30, 60)) nm.cancel(notifId(key, o))
        } catch (e: Exception) {
        }
    }
}
