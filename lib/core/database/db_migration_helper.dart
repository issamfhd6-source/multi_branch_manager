import 'package:drift/drift.dart';

import 'app_database.dart';

class DbMigrationHelper {
  DbMigrationHelper._();

  static MigrationStrategy buildStrategy() {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        for (var version = from; version < to; version++) {
          switch (version) {
            case 1:
              break;
            default:
              break;
          }
        }
      },
      beforeOpen: (OpeningDetails details) async {
        await details.batch((batch) {});
      },
    );
  }
}
