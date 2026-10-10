package id.jogoloyo.jogoloyo_les.alarm

import android.content.Context

// Simpan daftar alarm aktif di prefs agar bisa daftar ulang setelah boot.
// Tiap entri simpan trigger plus data bunyi. Tanpa ini alarm mati total saat reboot.
// Simpan 100 log terakhir untuk diagnosis.
object AlarmStore {
    private const val P = "jogoloyo_alarm_store";
    private const val K_NEED = "need_resync";

    data class Entry(
        val key: String,
        val off: Int,
        val triggerAt: Long,
        val title: String,
        val room: String,
        val sound: String,
        val level: Int,
        val vibrate: Boolean,
    )

    fun put(
        ctx: Context,
        key: String,
        off: Int,
        triggerAt: Long,
        title: String = "",
        room: String = "",
        sound: String = "suara1",
        level: Int = 200,
        vibrate: Boolean = true,
    ) {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val base = "t_${key}_$off"
        s.edit()
            .putLong(base, triggerAt)
            .putString("${base}_title", title)
            .putString("${base}_room", room)
            .putString("${base}_sound", sound)
            .putInt("${base}_level", level)
            .putBoolean("${base}_vib", vibrate)
            .apply()
        log(ctx, "scheduled $key H-$off at $triggerAt")
    }

    fun remove(ctx: Context, key: String) {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val e = s.edit()
        for (off in listOf(60, 30, 10, 0)) {
            val base = "t_${key}_$off"
            e.remove(base)
            e.remove("${base}_title")
            e.remove("${base}_room")
            e.remove("${base}_sound")
            e.remove("${base}_level")
            e.remove("${base}_vib")
        }
        e.apply()
        log(ctx, "cancelled $key")
    }

    fun markFired(ctx: Context, key: String, off: Int) {
        log(ctx, "fired $key H-$off at ${System.currentTimeMillis()}")
        // Satu tembakan: hapus agar tidak dobel bila dijadwalkan ulang.
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val base = "t_${key}_$off"
        s.edit()
            .remove(base)
            .remove("${base}_title")
            .remove("${base}_room")
            .remove("${base}_sound")
            .remove("${base}_level")
            .remove("${base}_vib")
            .apply()
    }

    fun entries(ctx: Context): List<Entry> {
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val out = mutableListOf<Entry>()
        for ((k, v) in s.all) {
            if (!k.startsWith("t_") || v !is Long) continue
            // Format kunci: t_{sessionKey}_{off}. Potong awalan dan angka akhir.
            val rest = k.removePrefix("t_")
            val off = rest.substringAfterLast("_", "").toIntOrNull() ?: continue
            val key = rest.substringBeforeLast("_")
            out.add(
                Entry(
                    key = key,
                    off = off,
                    triggerAt = v,
                    title = s.getString("${k}_title", "") ?: "",
                    room = s.getString("${k}_room", "") ?: "",
                    sound = s.getString("${k}_sound", "suara1") ?: "suara1",
                    level = s.getInt("${k}_level", 200),
                    vibrate = s.getBoolean("${k}_vib", true),
                )
            )
        }
        return out
    }

    fun all(ctx: Context): Map<String, Long> {
        return entries(ctx).associate { "t_${it.key}_${it.off}" to it.triggerAt }
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
