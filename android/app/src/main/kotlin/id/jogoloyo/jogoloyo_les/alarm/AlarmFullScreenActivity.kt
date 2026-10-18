package id.jogoloyo.jogoloyo_les.alarm

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// Layar alarm penuh bergaya panggilan masuk. Muncul saat jam alarm benar-benar
// tiba. Geser ke atas atau tekan tombol untuk menghentikan bunyi dan getar.
class AlarmFullScreenActivity : Activity() {
    private var key: String = ""
    private var offsetMin: Int = 0
    private var startY: Float = 0f
    private var handle: LinearLayout? = null

    private val deepGreen = Color.parseColor("#0B1F14")
    private val accent = Color.parseColor("#2E7D32")
    private val danger = Color.parseColor("#C62828")

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
        // Getar dan bunyi sudah dijalankan AlarmReceiver sebelum layar ini muncul.
        // Jangan getar ulang di sini supaya tidak getar dua kali.
    }

    private fun buildUi(title: String, room: String): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setBackgroundColor(deepGreen)
            setPadding(dp(28), dp(56), dp(28), dp(32))
        }

        // Status atas: pengingat live.
        val badge = TextView(this).apply {
            text = "ALARM MASUK KELAS"
            textSize = 13f
            setTextColor(Color.parseColor("#A5D6A7"))
            typeface = Typeface.DEFAULT_BOLD
            letterSpacing = 0.18f
        }
        root.addView(badge)

        root.addView(space(28))

        // Lingkaran avatar ala panggilan masuk.
        val initial = title.trim().take(1).uppercase().ifEmpty { "L" }
        val avatar = TextView(this).apply {
            text = initial
            textSize = 44f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(accent)
            }
        }
        root.addView(avatar, LinearLayout.LayoutParams(dp(112), dp(112)))

        root.addView(space(20))

        root.addView(TextView(this).apply {
            text = title
            textSize = 28f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })
        root.addView(space(8))
        root.addView(TextView(this).apply {
            text = if (room.isBlank()) "Les Jogoloyo" else room
            textSize = 15f
            setTextColor(Color.parseColor("#B0BEC5"))
            gravity = Gravity.CENTER
        })

        root.addView(space(6))
        val clock = SimpleDateFormat("EEEE, d MMMM yyyy . HH:mm", Locale("in", "ID")).format(Date())
        root.addView(TextView(this).apply {
            text = clock
            textSize = 13f
            setTextColor(Color.parseColor("#78909C"))
            gravity = Gravity.CENTER
        })

        // Pengingat 10 menit sebelumnya otomatis hilang begitu alarm menyala.
        if (offsetMin != 0) {
            NotificationHelper.cancelAll(this, key)
        }

        root.addView(View(this), LinearLayout.LayoutParams(1, 0, 1f))

        // Area geser ke atas.
        val swipeArea = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#10281A"))
        }
        val hint = TextView(this).apply {
            text = "Geser ke atas untuk hentikan alarm"
            textSize = 14f
            setTextColor(Color.parseColor("#CFD8DC"))
            gravity = Gravity.CENTER
        }
        swipeArea.addView(
            hint,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        )
        val handle = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(14), dp(24), dp(14))
            background = GradientDrawable().apply {
                cornerRadius = dp(28).toFloat()
                setColor(Color.parseColor("#1B5E20"))
            }
            addView(TextView(this@AlarmFullScreenActivity).apply {
                text = "STOP"
                textSize = 15f
                setTextColor(Color.WHITE)
                typeface = Typeface.DEFAULT_BOLD
            })
        }
        val lp = FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        lp.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        lp.bottomMargin = dp(16)
        swipeArea.addView(handle, lp)
        this.handle = handle

        root.addView(swipeArea, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(96)))

        root.addView(space(14))

        // Dua tombol ala panggilan: batal merah, selesai hijau.
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
        }
        row.addView(callButton("Tolak", danger) { stopAndFinish() }, weighted())
        row.addView(space(16))
        row.addView(callButton("Sudah Di Lokasi", accent) { stopAndFinish() }, weighted())
        root.addView(row)

        // Geser ke atas untuk hentikan.
        swipeArea.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> {
                    startY = ev.y
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val dy = startY - ev.y
                    if (dy > dp(70)) stopAndFinish()
                    true
                }
                else -> false
            }
        }

        // Ketuk tombol STOP juga menghentikan alarm.
        handle.setOnClickListener { stopAndFinish() }

        return root
    }

    private fun callButton(label: String, color: Int, onTap: () -> Unit): TextView {
        return TextView(this).apply {
            text = label
            textSize = 15f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            background = GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setColor(color)
            }
            setPadding(dp(8), dp(18), dp(8), dp(18))
            setOnClickListener { onTap() }
        }
    }

    private fun weighted(): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)

    private fun space(h: Int): View = SpaceWrapper(this, dp(h))

    private fun dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()

    private fun stopAndFinish() {
        AlarmSoundPlayer.stop(this)
        NotificationHelper.cancelAll(this, key)
        finish()
    }

    @Suppress("DEPRECATION")
    override fun onBackPressed() {
        // Back tidak menutup. Pengguna harus berhentikan alarm lewat tombol
        // atau geser ke atas supaya alarm tidak nyala terus tanpa kendali.
    }
}

private class SpaceWrapper(ctx: Context, private val height: Int) : View(ctx) {
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        setMeasuredDimension(
            View.MeasureSpec.getSize(widthMeasureSpec),
            height
        )
    }
}