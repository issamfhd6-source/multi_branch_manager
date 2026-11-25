import 'package:drift/drift.dart';

class DbMigrationHelper {
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
