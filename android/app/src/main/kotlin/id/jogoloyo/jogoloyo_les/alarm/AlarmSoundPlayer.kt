package id.jogoloyo.jogoloyo_les.alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.audiofx.LoudnessEnhancer
import android.os.Build
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
    fun play(ctx: Context, sound: String, level: Int, vibrate: Boolean) {
        stop(ctx, restore = false)
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
        if (vibrate) vibrate(ctx, strong = true)
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
                    releaseAll(ctx)
                    release()
                    if (player === it) player = null
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
            if (Build.VERSION.SDK_INT >= 31) {
                val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.hasVibrator()
            } else {
                @Suppress("DEPRECATION")
                (ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).hasVibrator()
            }
        } catch (e: Exception) {
            false
        }
    }

    fun vibrate(ctx: Context, strong: Boolean) {
        try {
            val pattern = if (strong) {
                longArrayOf(0, 1200, 400, 1200, 400, 1500)
            } else {
                longArrayOf(0, 400, 200, 400)
            }
            // Amplitudo 255 = paling kuat. Default sistem sering terlalu lemah.
            val amps = IntArray(pattern.size) { i -> if (i % 2 == 1) 255 else 0 }
            if (Build.VERSION.SDK_INT >= 31) {
                val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val v = vm.defaultVibrator
                if (!v.hasVibrator()) return
                v.vibrate(VibrationEffect.createWaveform(pattern, amps, -1))
            } else {
                @Suppress("DEPRECATION")
                val v = ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (!v.hasVibrator()) return
                if (Build.VERSION.SDK_INT >= 26) {
                    v.vibrate(VibrationEffect.createWaveform(pattern, amps, -1))
                } else {
                    @Suppress("DEPRECATION")
                    v.vibrate(pattern, -1)
                }
            }
        } catch (e: Exception) {
        }
    }

    private fun cancelVibrate(ctx: Context) {
        try {
            if (Build.VERSION.SDK_INT >= 31) {
                val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vm.defaultVibrator.cancel()
            } else {
                @Suppress("DEPRECATION")
                (ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).cancel()
            }
        } catch (e: Exception) {
        }
    }
}
