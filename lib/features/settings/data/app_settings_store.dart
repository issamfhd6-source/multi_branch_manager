import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class AppSettingsStore {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;

  AppSettingsStore(this._db, this._permissions);

  Map<String, dynamic> loadSettings() {
    final rows = _db.select(_db.appSettings).get();
    final map = <String, dynamic>{
      'dark_mode': false,
      'dual_syp_ratio': 100,
    };
    rows.then((items) {
      for (final r in items) {
        try {
          map[r.key] = jsonDecode(r.value);
        } catch (_) {
          map[r.key] = r.value;
        }
      }
    });
    return map;
  }

  void saveSetting({
    required AuthSession session,
    required String key,
    required dynamic value,
  }) {
    _permissions.enforce(
      session: session,
      action: 'manage_settings',
      entity: 'app_settings',
    );

    _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: jsonEncode(value),
          ),
        );
  }
}
