// Penyimpanan lokal inti: DB Drift plus secure storage untuk kunci les.
// Kunci les 32 byte dibuat sekali saat setup owner.
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../core/security/pin_hash.dart';
import 'app_db.dart';

final appDbProvider = Provider<AppDb>((ref) => AppDb());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

class LesStore {
  final AppDb db;
  final FlutterSecureStorage secure;
  LesStore(this.db, this.secure);

  static const kLesKey = 'les_key_b64';
  static const kActiveProfile = 'active_profile_id';

  Future<String> ensureLesKey() async {
    var v = await secure.read(key: kLesKey);
    if (v != null) return v;
    final r = Random.secure();
    final b = List<int>.generate(32, (_) => r.nextInt(256));
    v = base64Url.encode(b);
    await secure.write(key: kLesKey, value: v);
    return v;
  }

  Future<String> createOwner({required String name, required String pin}) async {
    if (!PinHash.isPinValid(pin)) throw Exception('PIN harus 6 digit.');
    await ensureLesKey();
    final id = const Uuid().v4();
    final salt = PinHash.makeSalt();
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            role: 'OWNER',
            name: name.trim(),
            pinHash: PinHash.hash(pin, salt),
            salt: salt,
          ),
        );
    return id;
  }

  Future<String> createAccount({
    required String role,
    required String name,
    required String pin,
    String? gender,
    String? subject,
  }) async {
    if (!PinHash.isPinValid(pin)) throw Exception('PIN harus 6 digit.');
    const allowed = {'ADMIN', 'GURU', 'SISWA', 'ORTU'};
    if (!allowed.contains(role)) throw Exception('Peran tidak dikenal.');
    final id = const Uuid().v4();
    final salt = PinHash.makeSalt();
    await db.into(db.profiles).insert(
          ProfilesCompanion.insert(
            id: id,
            role: role,
            name: name.trim(),
            pinHash: PinHash.hash(pin, salt),
            salt: salt,
            gender: Value(gender),
            subject: Value(subject),
          ),
        );
    return id;
  }

  Future<Profile> verifyPin(String profileId, String pin) async {
    final p = await (db.select(db.profiles)..where((t) => t.id.equals(profileId)))
        .getSingleOrNull();
    if (p == null) throw Exception('Profil tidak ditemukan.');
    if (!PinHash.verify(pin, p.salt, p.pinHash)) {
      throw Exception('PIN salah. Cek lagi.');
    }
    return p;
  }

  Stream<List<Profile>> watchProfiles() =>
      (db.select(db.profiles)..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
          .watch();
}

final lesStoreProvider = Provider<LesStore>((ref) {
  return LesStore(ref.watch(appDbProvider), ref.watch(secureStorageProvider));
});
