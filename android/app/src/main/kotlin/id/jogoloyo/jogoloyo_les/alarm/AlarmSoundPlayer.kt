package id.jogoloyo.jogoloyo_les.alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.audiofx.LoudnessEnhancer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

// Pemutar suara alarm: bunyi otomatis dari aset lokal plus getar opsional.
// Level 100 persen = pakai volume HP. 125 sampai 200 persen = paksa volume
// maksimal plus penguat gain agar jauh lebih keras. Volume dikembalikan selesai.
// Suara: suara1 sampai suara6 dari assets/music. Tanpa server, tanpa unduhan.
object AlarmSoundPlayer {
    private var player: MediaPlayer? = null
    private var enhancer: LoudnessEnhancer? = null
    private var prevVolume = -1
    private var looping = false
    private var loopToken = 0
    private val mainHandler = Handler(Looper.getMainLooper())
    private var loopStop: Runnable? = null
    private var vibrateRunnable: Runnable? = null

    // Level ke gain millibel: 125->194, 150->352, 175->486, 200->602.
    fun gainMb(level: Int): Int {
        if (level <= 100) return 0
        val db = 20.0 * kotlin.math.log10(level / 100.0)
        return (db * 100).toInt().coerceIn(0, 1000)
    }

    fun assetPath(sound: String): String = when (sound) {
        "suara1" -> "flutter_assets/assets/music/suara1.mp3"
        "suara2" -> "flutter_assets/assets/music/suara2.mp3"
        "suara3" -> "flutter_assets/assets/music/suara3.mp3"
        "suara4" -> "flutter_assets/assets/music/suara4.mp3"
        "suara5" -> "flutter_assets/assets/music/suara5.wav"
        "suara6" -> "flutter_assets/assets/music/suara6.wav"
        else -> "flutter_assets/assets/music/suara1.mp3"
    }

    @Synchronized
    fun play(ctx: Context, sound: String, level: Int, vibrate: Boolean, loop: Boolean = false) {
        stop(ctx, restore = false)
        looping = loop
        if (level > 100) {
            val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            try {
                prevVolume = am.getStreamVolume(AudioManager.STREAM_ALARM)
                val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                am.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
            } catch (e: Exception) {
                prevVolume = -1
            }
        }
        // Getar unstoppable selama alarm berbunyi, bukan tiga kali lalu diam.
        if (vibrate) {
            if (loop) vibrateLoop(ctx, strong = true) else vibrate(ctx, strong = true)
        }
        try {
            val fd = ctx.assets.openFd(assetPath(sound))
            val mp = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                fd.close()
                setOnCompletionListener {
                    if (looping) {
                        // Ulangi terus sampai pengguna menghentikan alarm.
                        try {
                            seekTo(0)
                            start()
                        } catch (e: Exception) {
                            releaseAll(ctx)
                            release()
                            if (player === it) player = null
                        }
                    } else {
                        releaseAll(ctx)
                        release()
                        if (player === it) player = null
                    }
                }
                prepare()
                try {
                    val g = gainMb(level)
                    if (g > 0) {
                        enhancer = LoudnessEnhancer(audioSessionId).apply { setTargetGain(g) }
                    }
                } catch (e: Exception) {
                }
                start()
            }
            player = mp
        } catch (e: Exception) {
            releaseAll(ctx)
        }
    }

    @Synchronized
    fun stop(ctx: Context, restore: Boolean = true) {
        looping = false
        cancelVibrateRunnable()
        loopStop?.let { mainHandler.removeCallbacks(it) }
        loopStop = null
        try {
            player?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (e: Exception) {
        } finally {
            player = null
            releaseAll(ctx)
            if (restore) restoreVolume(ctx)
        }
        cancelVibrate(ctx)
    }

    private fun releaseAll(ctx: Context) {
        try {
            enhancer?.release()
        } catch (e: Exception) {
        } finally {
            enhancer = null
            restoreVolume(ctx)
        }
    }

    private fun restoreVolume(ctx: Context) {
        if (prevVolume < 0) return
        try {
            val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.setStreamVolume(AudioManager.STREAM_ALARM, prevVolume, 0)
        } catch (e: Exception) {
        } finally {
            prevVolume = -1
        }
    }

    fun hasVibrator(ctx: Context): Boolean {
        return try {
            val v = vibratorOf(ctx)
            v != null && v.hasVibrator()
        } catch (e: Exception) {
            false
        }
    }

    // Ambil vibrator dengan fallback. Beberapa OEM tidak menyediakan
    // VibratorManager padahal motor getar ada, jadi coba service lama.
    private fun vibratorOf(ctx: Context): Vibrator? {
        return try {
            if (Build.VERSION.SDK_INT >= 31) {
                try {
                    val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                    vm.defaultVibrator
                } catch (e: Exception) {
                    @Suppress("DEPRECATION")
                    ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                }
            } else {
                @Suppress("DEPRECATION")
                ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
        } catch (e: Exception) {
            null
        }
    }

    // Attributes USAGE_ALARM supaya tidak dibungkam mode sunyi atau kanal bisu.
    private fun alarmAttrs(): AudioAttributes {
        return AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
    }

    // Getar tunggal untuk pengingat biasa. Tidak berulang.
    fun vibrate(ctx: Context, strong: Boolean) {
        fireOnce(ctx, strong)
    }

    // Matikan getar saja, bunyi tetap jalan. Dipakai tombol bisukan.
    fun cancelOnly(ctx: Context) {
        loopToken++
        cancelVibrateRunnable()
        cancelVibrate(ctx)
    }

    // Getar berulang penuh selama alarm berbunyi.
    // Beberapa ROM mengabaikan repeat pada vibrate lawas, jadi pakai Runnable
    // yang menjadwal ulang dirinya sendiri tiap satu siklus.
    // Getar 1500 ms lalu jeda 1500 ms, jadi rata 3 detik getar 3 detik jeda.
    fun vibrateLoop(ctx: Context, strong: Boolean) {
        loopToken++
        val token = loopToken
        cancelVibrateRunnable()
        val cycle = if (strong) 1500L else 900L
        val runnable = object : Runnable {
            override fun run() {
                if (token != loopToken) return
                fireOnce(ctx, strong)
                mainHandler.postDelayed(this, cycle)
            }
        }
        vibrateRunnable = runnable
        mainHandler.post(runnable)
        scheduleGuard(ctx, 300000, token)
    }

    // Tes getar: berulang selama durasi tertentu lalu berhenti sendiri.
    fun vibrateTimed(ctx: Context, strong: Boolean, ms: Long) {
        loopToken++
        val token = loopToken
        cancelVibrateRunnable()
        val cycle = if (strong) 1500L else 900L
        val runnable = object : Runnable {
            override fun run() {
                if (token != loopToken) return
                fireOnce(ctx, strong)
                mainHandler.postDelayed(this, cycle)
            }
        }
        vibrateRunnable = runnable
        mainHandler.post(runnable)
        scheduleGuard(ctx, ms, token)
    }

    // Satu kali getar. Getar 1500 ms lalu jeda 1500 ms. Selalu pakai
    // AudioAttributes USAGE_ALARM supaya tidak dibungkam mode sunyi.
    private fun fireOnce(ctx: Context, strong: Boolean) {
        val v = vibratorOf(ctx) ?: return
        val ms = (if (strong) 1500L else 900L)
        try {
            if (Build.VERSION.SDK_INT >= 26) {
                val effect = VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE)
                try {
                    v.vibrate(effect, alarmAttrs())
                } catch (e: Exception) {
                    v.vibrate(effect)
                }
            } else {
                @Suppress("DEPRECATION")
                v.vibrate(ms)
            }
        } catch (e: Exception) {
        }
    }

    // Pengaman: getar tidak boleh jalan lebih lama dari durasi yang diminta.
    private fun scheduleGuard(ctx: Context, ms: Long, token: Int) {
        loopStop?.let { mainHandler.removeCallbacks(it) }
        val guard = Runnable {
            if (token == loopToken) {
                cancelVibrateRunnable()
                cancelVibrate(ctx)
            }
        }
        loopStop = guard
        mainHandler.postDelayed(guard, ms)
    }

    private fun cancelVibrateRunnable() {
        vibrateRunnable?.let { mainHandler.removeCallbacks(it) }
        vibrateRunnable = null
    }

    private fun cancelVibrate(ctx: Context) {
        try {
            vibratorOf(ctx)?.cancel()
        } catch (e: Exception) {
        }
    }
}
