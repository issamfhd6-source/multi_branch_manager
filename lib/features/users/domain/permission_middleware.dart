import '../../../core/database/app_database.dart';
import '../data/audit_service.dart';
import 'auth_models.dart';

class PermissionMiddleware {
  final AppDatabase _db;
  final AuditService _audit;

  PermissionMiddleware(this._db, this._audit);

  bool _checkPermissionsContainer(dynamic perms, String action, String entity) {
    if (perms == null) return false;
    if (perms is Iterable) {
      return perms.contains(action) || perms.contains('$entity.$action');
    }
    if (perms is Map) {
      final keyMatch = perms[action] == true || perms['$entity.$action'] == true;
      final valMatch = perms.values.any(
        (v) => v == true || v?.toString() == action || v?.toString() == '$entity.$action',
      );
      return keyMatch || valMatch;
    }
    return false;
  }

  Future<bool> hasPermission({
    required AuthSession session,
    required String action,
    required String entity,
  }) async {
    final dynamic s = session;
    try {
      if (s.user == null) return false;
    } catch (_) {
      return false;
    }

    final dynamic role = s.role;
    final roleName = (role?.name ?? '').toString().toLowerCase();
    if (roleName == 'admin' ||
        roleName == 'manager' ||
        roleName == 'owner') {
      return true;
    }

    return _checkPermissionsContainer(role?.permissions, action, entity);
  }

  Future<void> enforce({
    required AuthSession session,
    required String action,
    required String entity,
    String? entityId,
    String? branchId,
  }) async {
    final _ = _db.schemaVersion;
    final allowed = await hasPermission(
      session: session,
      action: action,
      entity: entity,
    );

    final dynamic s = session;
    final actorId = (s.user?.id ?? 'unknown').toString();
    final branches = s.user?.branchIds;
    final defaultBranch = (branches is Iterable && branches.isNotEmpty)
        ? branches.first.toString()
        : 'branch_main';

    final dynamic auditDyn = _audit;
    try {
      await auditDyn.log(
        actorId: actorId,
        action: allowed ? 'permission_granted' : 'permission_denied',
        entity: entity,
        entityId: entityId ?? action,
        branchId: branchId ?? defaultBranch,
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
