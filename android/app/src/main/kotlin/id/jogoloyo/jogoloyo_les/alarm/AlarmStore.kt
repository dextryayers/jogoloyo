package id.jogoloyo.jogoloyo_les.alarm

import android.content.Context

// Simpan daftar alarm aktif di prefs agar bisa daftar ulang setelah boot.
// Simpan 100 log terakhir untuk diagnosis.
object AlarmStore {
    private const val P = "jogoloyo_alarm_store";
    private const val K_NEED = "need_resync";

    fun put(ctx: Context, key: String, off: Int, triggerAt: Long) {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        s.edit().putLong("t_${key}_$off", triggerAt).apply()
        log(ctx, "scheduled $key H-$off at $triggerAt")
    }

    fun remove(ctx: Context, key: String) {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val e = s.edit()
        for (off in listOf(60, 30, 10, 0)) e.remove("t_${key}_$off")
        e.apply()
        log(ctx, "cancelled $key")
    }

    fun markFired(ctx: Context, key: String, off: Int) {
        log(ctx, "fired $key H-$off at ${System.currentTimeMillis()}")
    }

    fun all(ctx: Context): Map<String, Long> {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        return s.all.filterValues { it is Long }.mapValues { it.value as Long }
            .filterKeys { it.startsWith("t_") }
    }

    fun setNeedResync(ctx: Context, v: Boolean) {
        ctx.getSharedPreferences(P, Context.MODE_PRIVATE).edit().putBoolean(K_NEED, v).apply()
    }

    fun needResync(ctx: Context): Boolean {
        return ctx.getSharedPreferences(P, Context.MODE_PRIVATE).getBoolean(K_NEED, false)
    }

    private fun log(ctx: Context, line: String) {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val old = s.getString("log", "") ?: ""
        val next = (old + "\n$line").split("\n").takeLast(100).joinToString("\n")
        s.edit().putString("log", next).apply()
    }
}
