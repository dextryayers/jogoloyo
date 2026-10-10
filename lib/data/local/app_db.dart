// DB lokal Drift V.01.0 local. Tanpa server.
// Tabel inti: profiles, sessions, attendance, bills, audit.
// Semua waktu UTC ISO. File dan foto simpan path, bukan blob.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_db.g.dart';

class Profiles extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()();
  TextColumn get name => text()();
  TextColumn get pinHash => text()();
  TextColumn get salt => text()();
  TextColumn get gender => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class TeacherVerifs extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId => text().references(Profiles, #id)();
  TextColumn get photoPath => text()();
  TextColumn get idDocPath => text()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get reviewerId => text().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  TextColumn get teacherId => text().references(Profiles, #id)();
  DateTimeColumn get startUtc => dateTime()();
  DateTimeColumn get endUtc => dateTime()();
  TextColumn get room => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get status =>
      text().withDefault(const Constant('scheduled'))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Attendances extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get profileId => text().references(Profiles, #id)();
  TextColumn get status => text()();
  TextColumn get method => text().withDefault(const Constant('qr'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Profiles, TeacherVerifs, Sessions, Attendances])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  AppDb.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // Query audit cepat: 0 baris sebelum rilis.
  Future<List<Session>> activeSessionsWithUnverifiedFemaleTeacher() {
    final q = customSelect(
      'SELECT s.* FROM sessions s JOIN profiles p ON p.id = s.teacher_id '
      'LEFT JOIN teacher_verifs v ON v.teacher_id = p.id AND v.status = ? '
      'WHERE s.status IN (?, ?) AND p.role = ? AND p.gender = ? AND v.id IS NULL',
      variables: [
        Variable.withString('ACTIVE'),
        Variable.withString('scheduled'),
        Variable.withString('ongoing'),
        Variable.withString('GURU'),
        Variable.withString('P'),
      ],
      readsFrom: {sessions, profiles, teacherVerifs},
    );
    return q.asyncMap(sessions.mapFromRow).get();
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final d = await getApplicationDocumentsDirectory();
    final f = File(p.join(d.path, 'jogoloyo.db'));
    return NativeDatabase(f);
  });
}
