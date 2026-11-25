import '../../../core/database/app_database.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class ReportsService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;

  ReportsService(this._db, this._permissions);

  Future> buildSalesSummary({
    required AuthSession session,
    required String branchId,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'view_reports',
      entity: 'invoices',
    );

    final invoices = await (_db.select(_db.invoices)
          ..where((t) => t.branchId.equals(branchId)))
        .get();

    double totalNewSyp = 0;
    double totalUsd = 0;
    int paidCount = 0;

    for (final inv in invoices) {
      totalNewSyp += inv.totalNewSyp;
      totalUsd += inv.totalUsd;
      if (inv.status == 'paid') {
        paidCount++;
      }
    }

    return {
      'branch_id': branchId,
      'invoices_count': invoices.length,
      'paid_invoices_count': paidCount,
      'total_new_syp': totalNewSyp,
      'total_old_syp': totalNewSyp * 100,
      'total_usd': totalUsd,
    };
  }
}
