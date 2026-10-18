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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.min

// Layar alarm penuh bergaya panggilan masuk memakai logo asli Les Jogoloyo.
// Muncul tepat saat jam alarm tiba. Bunyi dan getar berjalan terus sampai
// pengguna menekan tombol atau menggeser ke atas.
class AlarmFullScreenActivity : Activity() {
    private var key: String = ""
    private var offsetMin: Int = 0
    private var startY: Float = 0f
    private val pulses = mutableListOf<ObjectAnimator>()
    private var clockView: TextView? = null
    private var running = false
    private var hintShown = false

    private val clockHandler = Handler(Looper.getMainLooper())

    private val deepGreen = Color.parseColor("#06110A")
    private val midGreen = Color.parseColor("#0D2617")
    private val accent = Color.parseColor("#2E7D32")
    private val accentDark = Color.parseColor("#1B5E20")
    private val danger = Color.parseColor("#C62828")
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

    private fun readExtras(intent: android.content.Intent?) {
        key = intent?.getStringExtra("sessionKey") ?: key
        offsetMin = intent?.getIntExtra("offsetMin", 0) ?: offsetMin
        title = intent?.getStringExtra("title") ?: title
        room = intent?.getStringExtra("room") ?: room
    }

    private var title: String = "Pengingat"
    private var room: String = ""

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
        startClock()
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
        clockView = null

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
            setPadding(dp(24), dp(44), dp(24), dp(24))
        }
        root.addView(
            column,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        column.addView(badge())
        column.addView(vGap(20))

        val logoBlock = logoBlock()
        column.addView(
            logoBlock,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        )
        startPulse(logoBlock)

        column.addView(vGap(20))
        column.addView(
            TextView(this).apply {
                text = title
                textSize = 29f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                setLineSpacing(dp(2).toFloat(), 1f)
            }
        )
        column.addView(vGap(7))
        column.addView(
            TextView(this).apply {
                text = if (room.isBlank()) "Les Jogoloyo" else room
                textSize = 15f
                setTextColor(textMuted)
                gravity = Gravity.CENTER
            }
        )
        column.addView(vGap(14))
        column.addView(
            TextView(this).apply {
                textSize = 13f
                setTextColor(textFaint)
                gravity = Gravity.CENTER
            }.also { clockView = it }
        )

        // Jaga jarak fleksibel supaya rapi di layar pendek dan tinggi.
        column.addView(View(this), LinearLayout.LayoutParams(1, 0, 1f))

        column.addView(swipeArea(), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(104)
        ))

        column.addView(vGap(14))
        column.addView(callRow())
        column.addView(vGap(10))
        column.addView(
            TextView(this).apply {
                text = "Bunyi dan getar berjalan terus. Tekan tombol untuk berhenti."
                textSize = 11f
                setTextColor(textFaint)
                gravity = Gravity.CENTER
            }
        )

        // Alarm nyata menyala, pengingat 10 menit sebelumnya tidak perlu lagi.
        NotificationHelper.cancelAll(this, key)
        return root
    }

    private fun badge(): View {
        val text = TextView(this).apply {
            text = "ALARM MASUK KELAS"
            textSize = 11.5f
            setTextColor(Color.parseColor("#A5D6A7"))
            typeface = Typeface.DEFAULT_BOLD
            letterSpacing = 0.2f
            gravity = Gravity.CENTER
            setPadding(dp(18), dp(8), dp(18), dp(8))
            background = GradientDrawable().apply {
                cornerRadius = dp(20).toFloat()
                setColor(Color.parseColor("#14331F"))
                setStroke(dp(1), Color.parseColor("#1F5C31"))
            }
        }
        return FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            addView(text, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ))
        }
    }

    // Logo asli dipotong melingkar lalu diberi cincin putih agar rapi.
    private fun logoBlock(): View {
        val ring = dp(132)
        val inner = dp(116)
        val holder = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#12351E"))
                setStroke(dp(2), Color.parseColor("#2E7D32"))
            }
        }

        val logo = circularLogo()
        if (logo != null) {
            holder.addView(
                ImageView(this).apply {
                    setImageBitmap(logo)
                    scaleType = ImageView.ScaleType.FIT_CENTER
                },
                FrameLayout.LayoutParams(
                    inner,
                    inner,
                    Gravity.CENTER
                )
            )
        } else {
            holder.addView(
                TextView(this).apply {
                    text = "JOGOLOYO"
                    textSize = 15f
                    setTextColor(Color.WHITE)
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                },
                FrameLayout.LayoutParams(inner, inner, Gravity.CENTER)
            )
        }
        holder.layoutParams = LinearLayout.LayoutParams(ring, ring)
        return holder
    }

    // Jadikan logo asli bundling asset jadi lingkaran rapi.
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

    private fun swipeArea(): View {
        val area = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                cornerRadius = dp(20).toFloat()
                setColor(Color.parseColor("#0F2A19"))
                setStroke(dp(1), Color.parseColor("#1C4527"))
            }
        }
        area.addView(
            TextView(this).apply {
                text = "Geser ke atas untuk hentikan"
                textSize = 13.5f
                setTextColor(Color.parseColor("#B8CCC0"))
                gravity = Gravity.CENTER
            },
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )

        val pill = TextView(this).apply {
            text = "STOP"
            textSize = 14.5f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            letterSpacing = 0.12f
            gravity = Gravity.CENTER
            setPadding(dp(34), dp(12), dp(34), dp(12))
            background = GradientDrawable().apply {
                cornerRadius = dp(24).toFloat()
                setColor(accentDark)
            }
        }
        val lp = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        )
        lp.bottomMargin = dp(14)
        area.addView(pill, lp)

        area.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    startY = ev.y
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (startY - ev.y > dp(70)) stopAndFinish()
                    true
                }
                else -> false
            }
        }
        pill.setOnClickListener { stopAndFinish() }
        return area
    }

    private fun callRow(): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        row.addView(
            callButton("Tolak", danger),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        )
        row.addView(
            View(this),
            LinearLayout.LayoutParams(dp(14), 1)
        )
        row.addView(
            callButton("Sudah Di Lokasi", accent),
            LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
        )
        return row
    }

    private fun callButton(label: String, color: Int): TextView {
        return TextView(this).apply {
            text = label
            textSize = 15f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(10), dp(18), dp(10), dp(18))
            background = GradientDrawable().apply {
                cornerRadius = dp(16).toFloat()
                setColor(color)
            }
            setOnClickListener { stopAndFinish() }
        }
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

    private fun startClock() {
        clockHandler.removeCallbacksAndMessages(null)
        val fmt = SimpleDateFormat("EEEE, d MMMM yyyy . HH:mm:ss", Locale("in", "ID"))
        val tick = object : Runnable {
            override fun run() {
                clockView?.text = fmt.format(Date())
                if (running) clockHandler.postDelayed(this, 1000)
            }
        }
        clockHandler.post(tick)
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
        // Back tidak menutup agar alarm tidak nyala tanpa kendali.
        // Beri petunjuk jelas supaya pengguna tidak bingung.
        if (!hintShown) {
            hintShown = true
            Toast.makeText(
                this,
                "Tekan Tolak, Sudah Di Lokasi, STOP, atau geser ke atas.",
                Toast.LENGTH_LONG
            ).show()
        }
    }
}