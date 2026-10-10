package id.jogoloyo.jogoloyo_les.alarm

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

// Pemutar suara alarm: bunyi otomatis dari aset lokal plus getar HP.
// Mode Keras: paksa volume STREAM_ALARM ke maksimal saat bunyi, lalu kembalikan.
// Suara: suara1 sampai suara6 dari assets/music. Tanpa server, tanpa unduhan.
object AlarmSoundPlayer {
    private var player: MediaPlayer? = null
    private var prevVolume = -1

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
    fun play(ctx: Context, sound: String, loud: Boolean) {
        stop(ctx, restore = false)
        val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (loud) {
            try {
                prevVolume = am.getStreamVolume(AudioManager.STREAM_ALARM)
                val max = am.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                am.setStreamVolume(AudioManager.STREAM_ALARM, max, 0)
            } catch (e: Exception) {
                prevVolume = -1
            }
        }
        vibrate(ctx, strong = true)
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
                    restoreVolume(ctx)
                    release()
                    if (player === it) player = null
                }
                prepare()
                start()
            }
            player = mp
        } catch (e: Exception) {
            restoreVolume(ctx)
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
            if (restore) restoreVolume(ctx)
        }
        cancelVibrate(ctx)
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

    fun vibrate(ctx: Context, strong: Boolean) {
        try {
            val pattern = if (strong) {
                longArrayOf(0, 1000, 400, 1000, 400, 1500)
            } else {
                longArrayOf(0, 400, 200, 400)
            }
            if (Build.VERSION.SDK_INT >= 31) {
                val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val v = vm.defaultVibrator
                v.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                val v = ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= 26) {
                    v.vibrate(VibrationEffect.createWaveform(pattern, -1))
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
