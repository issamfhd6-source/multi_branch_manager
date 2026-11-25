import '../../../core/database/app_database.dart';
import '../data/audit_service.dart';
import 'auth_models.dart';

class PermissionMiddleware {
  final AppDatabase _db;
  final AuditService _audit;
  final Duration sessionTimeout;

  PermissionMiddleware(this._db, this._audit, this.sessionTimeout);

  Future<void> enforce({
    required AuthSession session,
    required String action,
    required String entity,
    String? targetBranchId,
  }) async {
    if (!session.user.isActive) {
      throw StateError('الحساب غير نشط.');
    }
    if (session.role.scope == 'global') {
      return;
    }
    final allowed = session.role.permissions[action] ?? false;
    if (!allowed) {
      throw StateError('لا تملك صلاحية تنفيذ العملية: $action على $entity.');
    }
    if (targetBranchId != null &&
        !session.user.branchIds.contains(targetBranchId)) {
      throw StateError('لا تملك صلاحية الوصول إلى هذا الفرع.');
    }
  }
}
