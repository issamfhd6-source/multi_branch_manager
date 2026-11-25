import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class AppSettingsStore {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;

  AppSettingsStore(this._db, this._permissions);

  Future> loadSettings() async {
    final rows = await _db.select(_db.appSettings).get();
    final map = <String, dynamic>{
      'dark_mode': false,
      'dual_syp_ratio': 100,
    };
    for (final r in rows) {
      try {
        map[r.key] = jsonDecode(r.value);
      } catch (_) {
        map[r.key] = r.value;
      }
    }
    return map;
  }

  void saveSetting({
    required AuthSession session,
    required String key,
    required dynamic value,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'manage_settings',
      entity: 'app_settings',
    );

    await _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonEncode(value),
          ),
        );
  }
}
