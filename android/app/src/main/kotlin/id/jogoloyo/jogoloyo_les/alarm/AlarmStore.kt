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
        val daily: Boolean = false,
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
        daily: Boolean = false,
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
            .putBoolean("${base}_daily", daily)
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
            e.remove("${base}_daily")
        }
        e.apply()
        log(ctx, "cancelled $key")
    }

    fun markFired(ctx: Context, key: String, off: Int, daily: Boolean = false) {
        log(ctx, "fired $key H-$off at ${System.currentTimeMillis()}")
        val s = ctx.getSharedPreferences(P, Context.MODE_PRIVATE)
        val base = "t_${key}_$off"
        val entry = entries(ctx).firstOrNull { it.key == key && it.off == off }
        val repeatNextDay = (daily || (entry?.daily == true)) && off == 0
        if (repeatNextDay) {
            // Harian: hanya alarm H-0 yang digeser ke besok. Pengingat H-10
            // dihapus karena akan dibuat ulang bersama alarm besok.
            val trigger = (entry?.triggerAt ?: System.currentTimeMillis()) + 24L * 60 * 60 * 1000
            val title = entry?.title ?: ""
            val room = entry?.room ?: ""
            val sound = entry?.sound ?: "suara1"
            val level = entry?.level ?: 200
            val vibrate = entry?.vibrate ?: true
            s.edit()
                .putLong(base, trigger)
                .putString("${base}_title", title)
                .putString("${base}_room", room)
                .putString("${base}_sound", sound)
                .putInt("${base}_level", level)
                .putBoolean("${base}_vib", vibrate)
                .putBoolean("${base}_daily", true)
                .apply()
            log(ctx, "rescheduled daily $key H-$off at $trigger")
        } else {
            s.edit()
                .remove(base)
                .remove("${base}_title")
                .remove("${base}_room")
                .remove("${base}_sound")
                .remove("${base}_level")
                .remove("${base}_vib")
                .remove("${base}_daily")
                .apply()
        }
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
                    daily = s.getBoolean("${k}_daily", false),
                )
            )
        }
        return out
    }

    fun all(ctx: Context): Map<String, Long> {
        return entries(ctx).associate { "t_${it.key}_${it.off}" to it.triggerAt }
    }

    // Kode request terpusat. Dipakai scheduler, boot, dan cek terpasang.
    // Rumus tidak boleh berubah agar alarm lama tetap bisa dibatalkan.
    fun reqCode(sessionKey: String, off: Int): Int {
        return (sessionKey.hashCode() * 31 + off).hashCode() and 0x7FFFFFFF % 1000000 + off
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
