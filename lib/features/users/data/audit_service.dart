import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class AuditService {
  final AppDatabase _db;

  AuditService(this._db);

  Future<void> record({
    required String userId,
    required String action,
    required String entity,
    String? entityId,
    String? branchId,
    String? details,
  }) async {
    try {
      final entry = AuditLogsCompanion.insert(
        id: 'aud_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        action: action,
        entity: entity,
        entityId: Value(entityId),
        branchId: Value(branchId),
        details: Value(details),
        ts: DateTime.now(),
      );
      await _db.into(_db.auditLogs).insert(entry);
    } catch (_) {
      // عدم إيقاف العملية الأساسية في حال تعذر تسجيل التدقيق
    }
  }
}
