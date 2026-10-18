package id.jogoloyo.jogoloyo_les.alarm

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Activity
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Layar alarm penuh bergaya panggilan masuk dengan logo asli Les Jogoloyo.
// Muncul tepat saat jam alarm tiba. Bunyi dan getar berjalan terus sampai
// pengguna menekan tombol atau menggeser ke atas.
class AlarmFullScreenActivity : Activity() {
    private var key: String = ""
    private var offsetMin: Int = 0
    private var startY: Float = 0f
    private var handle: LinearLayout? = null
    private var pulse: ObjectAnimator? = null
    private val clockHandler = Handler(Looper.getMainLooper())
    private var clockView: TextView? = null
    private var running = false

    private val deepGreen = Color.parseColor("#07130C")
    private val midGreen = Color.parseColor("#0E2A17")
    private val accent = Color.parseColor("#2E7D32")
    private val accentDark = Color.parseColor("#1B5E20")
    private val danger = Color.parseColor("#C62828")
    private val textMuted = Color.parseColor("#9FB8A6")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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

        key = intent.getStringExtra("sessionKey") ?: ""
        offsetMin = intent.getIntExtra("offsetMin", 0)
        val title = intent.getStringExtra("title") ?: "Pengingat"
        val room = intent.getStringExtra("room") ?: ""

        setContentView(buildUi(title, room))
        startClock()
    }

    override fun onResume() {
        super.onResume()
        running = true
        pulse?.resume()
        startClock()
    }

    override fun onPause() {
        super.onPause()
        running = false
        pulse?.pause()
        clockHandler.removeCallbacksAndMessages(null)
    }

    override fun onDestroy() {
        pulse?.cancel()
        pulse = null
        clockHandler.removeCallbacksAndMessages(null)
        super.onDestroy()
    }

    private fun buildUi(title: String, room: String): View {
        val root = FrameLayout(this).apply {
            setBackgroundColor(deepGreen)
        }

        // Latar gradien halus supaya tidak terasa polos.
        val bg = View(this).apply {
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(midGreen, deepGreen)
            )
        }
        root.addView(bg, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(24), dp(48), dp(24), dp(28))
        }
        root.addView(column, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))

        // Badge pengenal.
        column.addView(badge())

        // Logo asli di dalam lingkaran, denyut pelan seperti panggilan hidup.
        val logoWrap = FrameLayout(this).apply {
            setPadding(dp(10), dp(10), dp(10), dp(10))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#12351E"))
            }
        }
        val logo = loadLogo()
        if (logo != null) {
            logoWrap.addView(ImageView(this).apply {
                setImageBitmap(logo)
                scaleType = ImageView.ScaleType.FIT_CENTER
                setBackgroundColor(Color.WHITE)
                clipToOutline = true
            }, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ))
        } else {
            logoWrap.addView(TextView(this).apply {
                text = "JOGOLOYO"
                textSize = 13f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            ))
        }
        val logoSize = dp(128)
        column.addView(logoWrap, LinearLayout.LayoutParams(logoSize, logoSize))
        startPulse(logoWrap)

        column.addView(space(22))

        column.addView(TextView(this).apply {
            text = title
            textSize = 30f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setLineSpacing(dp(2).toFloat(), 1f)
        })
        column.addView(space(8))
        column.addView(TextView(this).apply {
            text = if (room.isBlank()) "Les Jogoloyo" else room
            textSize = 15f
            setTextColor(textMuted)
            gravity = Gravity.CENTER
        })

        column.addView(space(18))
        val clock = TextView(this).apply {
            textSize = 13.5f
            setTextColor(Color.parseColor("#7E9C89"))
            gravity = Gravity.CENTER
        }
        clockView = clock
        column.addView(clock)

        column.addView(View(this), LinearLayout.LayoutParams(1, 0, 1f))

        // Area geser ke atas ala panggilan.
        val swipe = swipeArea()
        column.addView(swipe, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(104)
        ))

        column.addView(space(14))
        column.addView(callRow())
        column.addView(space(2))
        column.addView(TextView(this).apply {
            text = "Bunyi dan getar berjalan terus. Hentikan lewat tombol di atas."
            textSize = 11f
            setTextColor(Color.parseColor("#5F7A69"))
            gravity = Gravity.CENTER
        })

        // Alarm baru menyala, pengingat 10 menit sebelumnya tidak perlu lagi.
        if (offsetMin != 0) {
            NotificationHelper.cancelAll(this, key)
        }

        return root
    }

    private fun badge(): View {
        val b = TextView(this).apply {
            text = "ALARM MASUK KELAS"
            textSize = 12f
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
        val holder = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            addView(b, FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            ))
        }
        return holder
    }

    private fun swipeArea(): View {
        val area = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                cornerRadius = dp(20).toFloat()
                setColor(Color.parseColor("#0F2A19"))
                setStroke(dp(1), Color.parseColor("#1C4527"))
            }
        }
        area.addView(TextView(this).apply {
            text = "Geser ke atas untuk hentikan"
            textSize = 13.5f
            setTextColor(Color.parseColor("#B8CCC0"))
            gravity = Gravity.CENTER
        }, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ))

        val pill = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(26), dp(12), dp(26), dp(12))
            background = GradientDrawable().apply {
                cornerRadius = dp(24).toFloat()
                setColor(accentDark)
            }
            addView(TextView(this@AlarmFullScreenActivity).apply {
                text = "STOP"
                textSize = 14.5f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
                letterSpacing = 0.12f
            })
        }
        val lp = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        )
        lp.bottomMargin = dp(14)
        area.addView(pill, lp)
        handle = pill

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
        row.addView(space(14))
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

    private fun loadLogo(): android.graphics.Bitmap? {
        return try {
            BitmapFactory.decodeStream(
                applicationContext.assets.open("flutter_assets/assets/logo.png")
            )
        } catch (e: Exception) {
            null
        }
    }

    private fun startPulse(view: View) {
        pulse = ObjectAnimator.ofFloat(view, "scaleX", 1f, 1.045f).apply {
            duration = 1100
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            interpolator = AccelerateDecelerateInterpolator()
            start()
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

    private fun space(h: Int): View = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            dp(h)
        )
    }

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun stopAndFinish() {
        AlarmSoundPlayer.stop(this)
        NotificationHelper.cancelAll(this, key)
        finish()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Back tidak menutup supaya alarm tidak nyala tanpa kendali.
        // Pengguna harus menekan tombol atau menggeser ke atas.
    }
}