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
  TextColumn get subject => text().nullable()();
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

class VerifAudits extends Table {
  TextColumn get id => text()();
  TextColumn get verifId => text().references(TeacherVerifs, #id)();
  TextColumn get actorId => text()();
  TextColumn get fromStatus => text().nullable()();
  TextColumn get toStatus => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Checkins extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().references(Sessions, #id)();
  TextColumn get teacherId => text().references(Profiles, #id)();
  BoolColumn get compliance => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Materials extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  TextColumn get title => text()();
  TextColumn get kind => text().withDefault(const Constant('pdf'))();
  TextColumn get pathOrUrl => text()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  BoolColumn get important => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Assignments extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  TextColumn get title => text()();
  TextColumn get desc => text().withDefault(const Constant(''))();
  DateTimeColumn get dueUtc => dateTime()();
  IntColumn get maxScore => integer().withDefault(const Constant(100))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Submissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get assignmentId => text().references(Assignments, #id)();
  TextColumn get studentId => text().references(Profiles, #id)();
  TextColumn get filePath => text()();
  IntColumn get score => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('terkumpul'))();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
}

class Quizzes extends Table {
  TextColumn get id => text()();
  TextColumn get subject => text()();
  TextColumn get title => text()();
  IntColumn get durationMin => integer().withDefault(const Constant(15))();
  @override
  Set<Column> get primaryKey => {id};
}

class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get quizId => text().references(Quizzes, #id)();
  TextColumn get questionText => text()();
  TextColumn get optionsJson => text()();
  IntColumn get answerIdx => integer()();
  TextColumn get explain => text().withDefault(const Constant(''))();
  @override
  Set<Column> get primaryKey => {id};
}

class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get quizId => text().references(Quizzes, #id)();
  TextColumn get studentId => text().references(Profiles, #id)();
  IntColumn get score => integer()();
  TextColumn get answersJson => text()();
  TextColumn get kind => text().withDefault(const Constant('resmi'))();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
}

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get studentId => text().references(Profiles, #id)();
  TextColumn get period => text()();
  IntColumn get amountInt => integer()();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get proofPath => text().nullable()();
  TextColumn get reviewerNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Announcements extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get target => text().withDefault(const Constant('semua'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Profiles,
  TeacherVerifs,
  Sessions,
  Attendances,
  VerifAudits,
  Checkins,
  Materials,
  Assignments,
  Submissions,
  Quizzes,
  Questions,
  Attempts,
  Bills,
  Announcements
])
class AppDb extends _$AppDb {
  AppDb() : super(_open());

  AppDb.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from == 1) {
            await m.addColumn(profiles, profiles.subject);
            await m.createTable(verifAudits);
            await m.createTable(checkins);
          }
          if (from <= 2) {
            await m.createTable(materials);
            await m.createTable(assignments);
            await m.createTable(submissions);
            await m.createTable(quizzes);
            await m.createTable(questions);
            await m.createTable(attempts);
            await m.createTable(bills);
            await m.createTable(announcements);
          }
        },
      );

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
