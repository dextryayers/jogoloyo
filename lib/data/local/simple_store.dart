// Store simpel V.02: profil, pengingat, catatan, setting. Semua di SharedPreferences.
// Tanpa database server. Tanpa tabel rumit. Format JSON list.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/alarm/alarm_service.dart';

const appSlots = ['Pagi', 'Siang', 'Sore', 'Malam'];

Map<String, String> defaultSlotTimes() => {
      'Pagi': '06:00',
      'Siang': '12:00',
      'Sore': '15:30',
      'Malam': '19:00',
    };

class Reminder {
  final String id;
  final String title;
  final DateTime whenUtc;
  final String sound;
  final int level;
  final bool vibrate;
  final bool enabled;
  final bool daily;
  const Reminder({
    required this.id,
    required this.title,
    required this.whenUtc,
    this.sound = 'suara1',
    this.level = 200,
    this.vibrate = true,
    this.enabled = true,
    this.daily = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iso': whenUtc.toIso8601String(),
        'sound': sound,
        'level': level,
        'vibrate': vibrate,
        'enabled': enabled,
        'daily': daily,
      };

  static Reminder fromJson(Map<String, dynamic> m) {
    var level = 200;
    final lv = m['level'];
    if (lv is int && [100, 125, 150, 175, 200].contains(lv)) {
      level = lv;
    } else if (m['loud'] == false) {
      level = 100;
    }
    return Reminder(
      id: m['id'] as String,
      title: m['title'] as String? ?? '',
      whenUtc: DateTime.parse(m['iso'] as String),
      sound: m['sound'] as String? ?? 'suara1',
      level: level,
      vibrate: m['vibrate'] as bool? ?? true,
      enabled: m['enabled'] as bool? ?? true,
      daily: m['daily'] as bool? ?? false,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool pinned;
  const Note(
      {required this.id,
      required this.title,
      required this.body,
      required this.updatedAt,
      this.pinned = false});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updated': updatedAt.toIso8601String(),
        'pinned': pinned,
      };

  static Note fromJson(Map<String, dynamic> m) => Note(
        id: m['id'] as String,
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        updatedAt: DateTime.tryParse(m['updated'] as String? ?? '') ?? DateTime.now().toUtc(),
        pinned: m['pinned'] as bool? ?? false,
      );
}

class SimpleStore {
  static const kReminders = 'reminders_v1';
  static const kNotes = 'notes_v1';

  Future<List<Reminder>> loadReminders() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kReminders);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Reminder.fromJson).toList();
  }

  Future<void> saveReminders(List<Reminder> items) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(kReminders, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<Reminder> upsertReminder(Reminder r) async {
    final all = await loadReminders();
    final i = all.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      all[i] = r;
    } else {
      all.add(r);
    }
    all.sort((a, b) => a.whenUtc.compareTo(b.whenUtc));
    await saveReminders(all);
    return r;
  }

  Future<void> deleteReminder(String id) async {
    final all = await loadReminders();
    all.removeWhere((e) => e.id == id);
    await saveReminders(all);
    await AlarmService().cancel(id, 'me');
  }

  Future<String> slotTime(String slot) async {
    final p = await SharedPreferences.getInstance();
    return p.getString('slot_$slot') ?? (defaultSlotTimes()[slot] ?? '06:00');
  }

  Future<void> setSlotTime(String slot, String hm) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('slot_$slot', hm);
  }

  Future<String> defaultSound() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('default_sound') ?? 'suara1';
  }

  Future<int> defaultLevel() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('default_level');
    if (v != null && [100, 125, 150, 175, 200].contains(v)) return v;
    if (p.getBool('default_loud') == false) return 100;
    return 200;
  }

  Future<bool> defaultVibrate() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('default_vibrate') ?? true;
  }

  // WIB HH:mm ke DateTime UTC hari ini.
  DateTime todayWibToUtc(String hm) {
    final parts = hm.split(':');
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final wib = DateTime.utc(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
    return wib.subtract(const Duration(hours: 7));
  }

  // Jadwalkan ulang semua yang aktif. Harian yang lewat digeser ke hari berikut.
  // Satu tembakan per pengingat dengan offset 0: bunyi tepat waktu plus getar.
  Future<({int scheduled, int cancelled})> rescheduleAll() async {
    final alarm = AlarmService();
    final all = await loadReminders();
    final now = DateTime.now().toUtc();
    var sch = 0;
    var can = 0;
    var changed = false;
    for (var r in all) {
      var when = r.whenUtc;
      if (r.daily) {
        var guard = 0;
        while (!when.isAfter(now) && guard < 400) {
          when = when.add(const Duration(days: 1));
          guard++;
        }
        if (when != r.whenUtc) {
          r = Reminder(
              id: r.id,
              title: r.title,
              whenUtc: when,
              sound: r.sound,
              level: r.level,
              vibrate: r.vibrate,
              enabled: r.enabled,
              daily: true);
          changed = true;
        }
      }
      if (!r.enabled || (!r.daily && !when.isAfter(now))) {
        await alarm.cancel(r.id, 'me');
        can++;
        continue;
      }
       final ok = await alarm.schedule(
         sessionId: r.id,
         profileId: 'me',
         startUtc: when,
         offsets: const [0],
         title: r.title.isEmpty ? 'Pengingat' : r.title,
         room: '',
         sound: r.sound,
         level: r.level,
         vibrate: r.vibrate,
         daily: r.daily,
       );
      if (ok) sch++;
    }
    if (changed) await saveReminders(all);
    return (scheduled: sch, cancelled: can);
  }

  Future<List<Note>> loadNotes() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(kNotes);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final notes = list.map(Note.fromJson).toList();
    notes.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Future<void> togglePin(String id) async {
    final all = await loadNotes();
    final i = all.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final n = all[i];
    all[i] = Note(
        id: n.id, title: n.title, body: n.body, updatedAt: n.updatedAt, pinned: !n.pinned);
    final p = await SharedPreferences.getInstance();
    await p.setString(kNotes, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> saveNote({String? id, required String title, required String body}) async {
    final all = await loadNotes();
    final nid = id ?? const Uuid().v4();
    final i = all.indexWhere((e) => e.id == nid);
    final pinned = i >= 0 ? all[i].pinned : false;
    final n = Note(
        id: nid,
        title: title.trim(),
        body: body,
        updatedAt: DateTime.now().toUtc(),
        pinned: pinned);
    if (i >= 0) {
      all[i] = n;
    } else {
      all.add(n);
    }
    final p = await SharedPreferences.getInstance();
    await p.setString(kNotes, jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> deleteNote(String id) async {
    final all = await loadNotes();
    all.removeWhere((e) => e.id == id);
    final p = await SharedPreferences.getInstance();
    await p.setString(kNotes, jsonEncode(all.map((e) => e.toJson()).toList()));
  }
}

final simpleStoreProvider = Provider((ref) => SimpleStore());
final remindersProvider = FutureProvider<List<Reminder>>((ref) async {
  return ref.watch(simpleStoreProvider).loadReminders();
});
final notesProvider = FutureProvider<List<Note>>((ref) async {
  return ref.watch(simpleStoreProvider).loadNotes();
});

String wibHm(DateTime utc) {
  final w = utc.toUtc().add(const Duration(hours: 7));
  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}

String wibDay(DateTime utc) {
  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  final w = utc.toUtc().add(const Duration(hours: 7));
  return '${days[w.weekday - 1]}, ${w.day}/${w.month}';
}

TimeOfDay parseHm(String hm) {
  final p = hm.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}
