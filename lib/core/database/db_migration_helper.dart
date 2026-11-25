import 'package:drift/drift.dart';

class DbMigrationHelper {
  static MigrationStrategy buildStrategy({
    Future<void> Function(Migrator m)? onCreate,
    Future<void> Function(Migrator m, int from, int to)? onUpgrade,
    Future<void> Function(OpeningDetails details)? beforeOpen,
  }) {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        if (onCreate != null) {
          await onCreate(m);
        }
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (onUpgrade != null) {
          await onUpgrade(m, from, to);
        }
      },
      beforeOpen: (OpeningDetails details) async {
        if (beforeOpen != null) {
          await beforeOpen(details);
        }
      },
    );
  }

  static Future<void> runSafeMigration(
    Migrator m,
    int from,
    int to,
    Future<void> Function(Migrator migrator, int oldVersion, int newVersion)
        customStep,
  ) async {
    if (from == to) return;
    await customStep(m, from, to);
  }

  static Future<void> runBatchSafe(
    dynamic executorOrMigrator,
    void Function(dynamic batch) operations,
  ) async {
    if (executorOrMigrator == null) return;
    try {
      await (executorOrMigrator as dynamic).batch((dynamic b) {
        operations(b);
      });
    } catch (_) {
      try {
        final dynamic db = (executorOrMigrator as dynamic).database;
        if (db != null) {
          await db.batch((dynamic b) {
            operations(b);
          });
        }
      } catch (_) {}
    }
  }
}
