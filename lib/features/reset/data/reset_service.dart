import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class ResetService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;
  final AuditService _audit;
  // ignore: unused_field
  final SupabaseClient? _supabase;

  ResetService(
    this._db,
    this._permissions,
    this._audit, {
    SupabaseClient? supabase,
  }) : _supabase = supabase;

  Future<void> resetLocalOperationalData({
    required AuthSession session,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'factory_reset',
      entity: 'system',
    );

    await _db.transaction(() async {
      await _db.delete(_db.invoiceItems).go();
      await _db.delete(_db.invoices).go();
      await _db.delete(_db.branchStocks).go();
      await _db.delete(_db.products).go();
      await _db.delete(_db.syncQueue).go();
    });

    await _audit.record(
      userId: session.user.id,
      action: 'reset_local_data',
      entity: 'system',
      details: 'cleared_operational_tables',
    );
  }
}
