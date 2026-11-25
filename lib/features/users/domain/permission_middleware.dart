import '../../../core/database/app_database.dart';
import '../data/audit_service.dart';
import 'auth_models.dart';

class PermissionMiddleware {
  final AppDatabase _db;
  final AuditService _audit;

  PermissionMiddleware(this._db, this._audit);

  Future<bool> hasPermission({
    required AuthSession session,
    required String action,
    required String entity,
  }) async {
    if (!session.isValid) return false;
    final roleName = session.role.name.toLowerCase();
    if (roleName == 'admin' ||
        roleName == 'manager' ||
        roleName == 'owner') {
      return true;
    }
    return session.role.permissions.contains(action) ||
        session.role.permissions.contains('$entity.$action');
  }

  Future<void> enforce({
    required AuthSession session,
    required String action,
    required String entity,
    String? entityId,
    String? branchId,
  }) async {
    // التحقق من جاهزية قاعدة البيانات وتسجيل محاولة الوصول
    final _ = _db.schemaVersion;
    final allowed = await hasPermission(
      session: session,
      action: action,
      entity: entity,
    );

    final dynamic auditDyn = _audit;
    try {
      await auditDyn.log(
        actorId: session.user.id,
        action: allowed ? 'permission_granted' : 'permission_denied',
        entity: entity,
        entityId: entityId ?? action,
        branchId: branchId ??
            (session.user.branchIds.isNotEmpty
                ? session.user.branchIds.first
                : 'branch_main'),
        details: 'action=$action, allowed=$allowed',
      );
    } catch (_) {}

    if (!allowed) {
      throw StateError(
        'ليس لديك صلاحية تنفيذ ($action) على ($entity).',
      );
    }
  }
}
