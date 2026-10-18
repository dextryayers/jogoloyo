package id.jogoloyo.jogoloyo_les.alarm

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Activity
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import java.util.Locale
import kotlin.math.min

// Layar alarm penuh bergaya panggilan masuk dengan logo asli Les Jogoloyo.
// Satu tombol STOP besar di tengah bawah, timer durasi berjalan, tombol
// bisukan di kanan atas. Bunyi dan getar jalan terus sampai dihentikan.
class AlarmFullScreenActivity : Activity() {
    private var key: String = ""
    private var offsetMin: Int = 0
    private var title: String = "Pengingat"
    private var room: String = ""
    private var startY: Float = 0f
    private var muted = false
    private var hintShown = false

    private var timerView: TextView? = null
    private var muteIcon: ImageView? = null
    private val pulses = mutableListOf<ObjectAnimator>()
    private val clockHandler = Handler(Looper.getMainLooper())
    private var startedAt: Long = System.currentTimeMillis()
    private var running = false

    private val deepGreen = Color.parseColor("#06110A")
    private val midGreen = Color.parseColor("#0D2617")
    private val accent = Color.parseColor("#2E7D32")
    private val danger = Color.parseColor("#D32F2F")
    private val textMuted = Color.parseColor("#9FB8A6")
    private val textFaint = Color.parseColor("#6E8C79")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        keepAwake()
        readExtras(intent)
        setContentView(buildUi())
    }

    override fun onNewIntent(intent: android.content.Intent?) {
        super.onNewIntent(intent)
        readExtras(intent)
        setContentView(buildUi())
    }

    private fun readExtras(i: android.content.Intent?) {
        key = i?.getStringExtra("sessionKey") ?: key
        offsetMin = i?.getIntExtra("offsetMin", 0) ?: offsetMin
        title = i?.getStringExtra("title") ?: title
        room = i?.getStringExtra("room") ?: room
    }

    private fun keepAwake() {
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onResume() {
        super.onResume()
        running = true
        for (p in pulses) p.resume()
        startTimer()
    }

    override fun onPause() {
        super.onPause()
        running = false
        for (p in pulses) p.pause()
        clockHandler.removeCallbacksAndMessages(null)
    }

    override fun onDestroy() {
        for (p in pulses) p.cancel()
        pulses.clear()
        clockHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun buildUi(): View {
        for (p in pulses) p.cancel()
        pulses.clear()
        timerView = null
        muteIcon = null
        startedAt = System.currentTimeMillis()

        val root = FrameLayout(this).apply { setBackgroundColor(deepGreen) }
        root.addView(
            View(this).apply {
                background = GradientDrawable(
                    GradientDrawable.Orientation.TOP_BOTTOM,
                    intArrayOf(midGreen, deepGreen)
                )
            },
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(28), dp(44), dp(28), dp(34))
        }
        root.addView(
            column,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        // Bar atas: nama aplikasi di kiri, tombol bisukan di kanan.
        column.addView(topBar(), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))

        column.addView(vGap(28))
        column.addView(
            TextView(this).apply {
                text = title
                textSize = 24f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setLineSpacing(dp(2).toFloat(), 1f)
            }
        )
        column.addView(vGap(6))
        column.addView(
            TextView(this).apply {
                text = if (room.isBlank()) "Les Jogoloyo" else room
                textSize = 14f
                setTextColor(textMuted)
                gravity = Gravity.CENTER
            }
        )

        column.addView(vGap(26))

        // Logo asli di dalam kartu putih membulat, denyut pelan.
        val logo = logoCard()
        column.addView(
            logo,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )
        startPulse(logo)

        column.addView(vGap(28))

        // Timer durasi alarm, berjalan tiap detik.
        column.addView(
            TextView(this).apply {
                text = "00:00:00"
                textSize = 34f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.05f
                gravity = Gravity.CENTER
            }.also { timerView = it }
        )
        column.addView(vGap(8))
        column.addView(
            TextView(this).apply {
                text = "Bunyi dan getar berjalan terus. Tekan STOP untuk diamkan."
                textSize = 12.5f
                setTextColor(textFaint)
                gravity = Gravity.CENTER
            }
        )

        // Jaga jarak fleksibel supaya rapi di layar pendek dan tinggi.
        column.addView(View(this), LinearLayout.LayoutParams(1, 0, 1f))

        // Satu tombol STOP besar, gaya tombol Akhiri Panggilan.
        column.addView(stopButton(), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        ))
        column.addView(vGap(12))
        column.addView(
            TextView(this).apply {
                text = "STOP"
                textSize = 13f
                setTextColor(textMuted)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.16f
                gravity = Gravity.CENTER
            }
        )

        NotificationHelper.cancelAll(this, key)
        return root
    }

    private fun topBar(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        row.addView(
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_VERTICAL
                addView(TextView(this@AlarmFullScreenActivity).apply {
                    text = "ALARM MASUK KELAS"
                    textSize = 11f
                    setTextColor(Color.parseColor("#A5D6A7"))
                    typeface = Typeface.DEFAULT_BOLD
                    letterSpacing = 0.18f
                })
                addView(TextView(this@AlarmFullScreenActivity).apply {
                    text = "Pengingat Les Jogoloyo"
                    textSize = 12f
                    setTextColor(textFaint)
                })
            },
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        )
        row.addView(muteButton())
        return row
    }

    private fun muteButton(): View {
        val icon = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_media_pause)
            setColorFilter(Color.WHITE)
        }
        muteIcon = icon
        val holder = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1B5E20"))
                setStroke(dp(1), Color.parseColor("#2E7D32"))
            }
            setPadding(dp(12), dp(12), dp(12), dp(12))
            contentDescription = "Bisukan getar"
            setOnClickListener { toggleMute() }
            addView(
                icon,
                FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            )
        }
        holder.layoutParams = LinearLayout.LayoutParams(dp(48), dp(48))
        return holder
    }

    private fun toggleMute() {
        muted = !muted
        if (muted) {
            AlarmSoundPlayer.cancelOnly(this)
            if (timerView != null) setMutedHint("Getar dan bunyi dibisukan sementara.")
        } else {
            AlarmSoundPlayer.vibrateLoop(this, strong = true)
            if (timerView != null) setMutedHint("Getar dan bunyi berjalan lagi.")
        }
        renderMuteState()
    }

    private fun setMutedHint(_msg: String) {
        Toast.makeText(this, _msg, Toast.LENGTH_SHORT).show()
    }

    private fun renderMuteState() {
        val icon = muteIcon ?: return
        icon.setColorFilter(if (muted) Color.parseColor("#FF8A80") else Color.WHITE)
        icon.alpha = if (muted) 0.6f else 1f
    }

    // Logo asli dipotong melingkar lalu diletakkan di kartu putih melengkung.
    private fun logoCard(): View {
        val card = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                cornerRadius = dp(96).toFloat()
                setColor(Color.WHITE)
            }
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        val logo = circularLogo()
        if (logo != null) {
            card.addView(
                ImageView(this).apply {
                    setImageBitmap(logo)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                },
                FrameLayout.LayoutParams(dp(96), dp(96), Gravity.CENTER)
            )
        } else {
            card.addView(
                TextView(this).apply {
                    text = "JOGOLOYO"
                    textSize = 14f
                    setTextColor(Color.parseColor("#1B5E20"))
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                },
                FrameLayout.LayoutParams(dp(96), dp(96), Gravity.CENTER)
            )
        }
        card.layoutParams = LinearLayout.LayoutParams(dp(144), dp(144))
        return card
    }

    private fun circularLogo(): Bitmap? {
        var src: Bitmap? = null
        try {
            src = BitmapFactory.decodeStream(
                applicationContext.assets.open("flutter_assets/assets/logo.png")
            )
        } catch (e: Exception) {
            return null
        }
        val bmp = src ?: return null
        return try {
            val size = min(bmp.width, bmp.height)
            val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(out)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG)
            val shader = BitmapShader(bmp, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            val scale = size.toFloat() / min(bmp.width, bmp.height).toFloat()
            val matrix = Matrix().apply {
                setScale(scale, scale)
                postTranslate((size - bmp.width * scale) / 2f, (size - bmp.height * scale) / 2f)
            }
            shader.setLocalMatrix(matrix)
            paint.shader = shader
            canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
            out
        } catch (e: Exception) {
            null
        } finally {
            try {
                bmp.recycle()
            } catch (e: Exception) {
            }
        }
    }

    private fun stopButton(): View {
        val btn = TextView(this).apply {
            text = "STOP"
            textSize = 17f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            letterSpacing = 0.08f
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(danger)
            }
            setPadding(dp(30), dp(30), dp(30), dp(30))
            contentDescription = "Hentikan alarm"
            setOnClickListener { stopAndFinish() }
        }
        btn.layoutParams = LinearLayout.LayoutParams(dp(88), dp(88))
        return btn
    }

    private fun startPulse(view: View) {
        for (axis in listOf("scaleX", "scaleY")) {
            ObjectAnimator.ofFloat(view, axis, 1f, 1.05f).apply {
                duration = 1100
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.REVERSE
                interpolator = AccelerateDecelerateInterpolator()
                start()
            }.also { pulses.add(it) }
        }
    }

    private fun startTimer() {
        clockHandler.removeCallbacksAndMessages(null)
        val tick = object : Runnable {
            override fun run() {
                timerView?.text = formatElapsed(System.currentTimeMillis() - startedAt)
                if (running) clockHandler.postDelayed(this, 1000)
            }
        }
        clockHandler.post(tick)
    }

    private fun formatElapsed(ms: Long): String {
        val total = (ms / 1000).coerceAtLeast(0)
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return String.format(Locale.US, "%02d:%02d:%02d", h, m, s)
    }

    private fun vGap(h: Int): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(h))
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun stopAndFinish() {
        AlarmSoundPlayer.stop(this)
        NotificationHelper.cancelAll(this, key)
        finish()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        if (!hintShown) {
            hintShown = true
            Toast.makeText(this, "Tekan tombol STOP merah untuk menghentikan alarm.", Toast.LENGTH_LONG).show()
        }
    }
}