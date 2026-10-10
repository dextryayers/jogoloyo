// Profil aktif HP bersama: simpan id di SharedPreferences.
// Dibaca Beranda dan Saya agar nama dan foto selalu sinkron.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/app_db.dart';
import '../../data/local/les_store.dart';

const kActiveProfileId = 'active_profile_id';

final activeProfileProvider = FutureProvider<Profile?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString(kActiveProfileId);
  if (id == null) return null;
  final db = ref.watch(appDbProvider);
  return (db.select(db.profiles)..where((t) => t.id.equals(id))).getSingleOrNull();
});

Future<void> setActiveProfile(String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kActiveProfileId, id);
}
