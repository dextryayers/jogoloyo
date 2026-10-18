package id.jogoloyo.jogoloyo_les.alarm

import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

// Layar penuh seperti panggilan masuk. Muncul saat alarm mulai.
// Usap ke atas atau tekan Hentikan untuk mematikan bunyi dan getar.
class AlarmFullScreenActivity : Activity() {
    private var key: String = ""
    private var startY: Float = 0f

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= 27) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        key = intent.getStringExtra("sessionKey") ?: ""
        val title = intent.getStringExtra("title") ?: "Pengingat"
        val room = intent.getStringExtra("room") ?: ""

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#0B1F14"))
            setPadding(48, 80, 48, 80)
        }

        val status = TextView(this).apply {
            text = "ALARM MASUK KELAS"
            textSize = 14f
            setTextColor(Color.parseColor("#9CCC65"))
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        }
        val titleView = TextView(this).apply {
            text = title
            textSize = 34f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 8)
        }
        val roomView = TextView(this).apply {
            text = if (room.isBlank()) "Saatnya masuk kelas" else room
            textSize = 16f
            setTextColor(Color.parseColor("#B0BEC5"))
            gravity = Gravity.CENTER
        }
        val hint = TextView(this).apply {
            text = "Usap ke atas untuk hentikan"
            textSize = 15f
            setTextColor(Color.parseColor("#CFD8DC"))
            gravity = Gravity.CENTER
            setPadding(0, 64, 0, 24)
        }
        val stopBtn = Button(this).apply {
            text = "HENTIKAN"
            textSize = 16f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#C62828"))
            setPadding(48, 24, 48, 24)
            setOnClickListener { stopAndFinish() }
        }

        root.addView(status)
        root.addView(titleView)
        root.addView(roomView)
        root.addView(hint)
        root.addView(stopBtn)

        root.setOnTouchListener { _, ev ->
            when (ev.action) {
                MotionEvent.ACTION_DOWN -> { startY = ev.y; true }
                MotionEvent.ACTION_UP -> {
                    if (startY - ev.y > 150f) {
                        stopAndFinish()
                        true
                    } else false
                }
                else -> false
            }
        }

        setContentView(root)
    }

    private fun stopAndFinish() {
        AlarmSoundPlayer.stop(this)
        try {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.cancel(key.hashCode())
        } catch (e: Exception) {
        }
        finish()
    }

    override fun onBackPressed() {
        // Jangan biarkan back menutup tanpa hentikan bunyi.
    }
}