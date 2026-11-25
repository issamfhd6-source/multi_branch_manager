import '../../../core/database/app_database.dart';
import '../../../core/models/domain_models.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class ReportsService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;

  ReportsService(this._db, this._permissions);

  Future<SalesSummaryModel> buildSalesSummary({
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

    return SalesSummaryModel(
      branchId: branchId,
      invoicesCount: invoices.length,
      paidInvoicesCount: paidCount,
      totalNewSyp: totalNewSyp,
      totalOldSyp: totalNewSyp * 100,
      totalUsd: totalUsd,
    );
  }
}
