import '../../../core/database/app_database.dart';
import '../../../core/utils/dual_syp_formatter.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class BranchRaceEntry {
  final int rank;
  final String branchId;
  final double salesNewSyp;
  final double salesOldSyp;
  final double costNewSyp;
  final double costOldSyp;
  final double profitNewSyp;
  final double profitOldSyp;
  final int invoiceCount;

  const BranchRaceEntry({
    required this.rank,
    required this.branchId,
    required this.salesNewSyp,
    required this.salesOldSyp,
    required this.costNewSyp,
    required this.costOldSyp,
    required this.profitNewSyp,
    required this.profitOldSyp,
    required this.invoiceCount,
  });
}

class ReportsService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;

  ReportsService(this._db, this._permissions);

  Future<List<BranchRaceEntry>> getBranchRace({
    required AuthSession session,
    DateTime? fromDate,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'view_all_reports',
      entity: 'reports',
    );

    final cutoff = fromDate ?? DateTime.now().subtract(const Duration(days: 30));
    final invoices = await _db.select(_db.invoices).get();
    final items = await _db.select(_db.invoiceItems).get();

    final costByInvoice = <String, double>{};
    for (final it in items) {
      costByInvoice[it.invoiceId] =
          (costByInvoice[it.invoiceId] ?? 0.0) + (it.cost * it.qty);
    }

    final salesByBranch = <String, double>{};
    final costByBranch = <String, double>{};
    final countByBranch = <String, int>{};

    for (final inv in invoices) {
      if (inv.type != 'sale' || inv.status == 'cancelled') continue;
      if (inv.ts.toLocal().isBefore(cutoff)) continue;

      final bId = inv.branchId;
      salesByBranch[bId] = (salesByBranch[bId] ?? 0.0) + inv.total;
      costByBranch[bId] =
          (costByBranch[bId] ?? 0.0) + (costByInvoice[inv.id] ?? 0.0);
      countByBranch[bId] = (countByBranch[bId] ?? 0) + 1;
    }

    final entries = salesByBranch.keys.map((bId) {
      final salesNew = salesByBranch[bId] ?? 0.0;
      final costNew = costByBranch[bId] ?? 0.0;
      final profitNew = salesNew - costNew;
      return BranchRaceEntry(
        rank: 0,
        branchId: bId,
        salesNewSyp: salesNew,
        salesOldSyp: DualSypFormatter.newToOld(salesNew),
        costNewSyp: costNew,
        costOldSyp: DualSypFormatter.newToOld(costNew),
        profitNewSyp: profitNew,
        profitOldSyp: DualSypFormatter.newToOld(profitNew),
        invoiceCount: countByBranch[bId] ?? 0,
      );
    }).toList();

    entries.sort((a, b) => b.profitNewSyp.compareTo(a.profitNewSyp));

    final ranked = <BranchRaceEntry>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      ranked.add(
        BranchRaceEntry(
          rank: i + 1,
          branchId: e.branchId,
          salesNewSyp: e.salesNewSyp,
          salesOldSyp: e.salesOldSyp,
          costNewSyp: e.costNewSyp,
          costOldSyp: e.costOldSyp,
          profitNewSyp: e.profitNewSyp,
          profitOldSyp: e.profitOldSyp,
          invoiceCount: e.invoiceCount,
        ),
      );
    }

    return ranked;
  }

  String exportBranchRaceCsv(List<BranchRaceEntry> race) {
    final sb = StringBuffer();
    sb.writeln(
      'Rank,Branch,Invoices,Sales_New_SYP,Sales_Old_SYP,Profit_New_SYP,Profit_Old_SYP',
    );
    for (final e in race) {
      sb.writeln(
        '${e.rank},${e.branchId},${e.invoiceCount},${e.salesNewSyp.toStringAsFixed(2)},${e.salesOldSyp.toStringAsFixed(0)},${e.profitNewSyp.toStringAsFixed(2)},${e.profitOldSyp.toStringAsFixed(0)}',
      );
    }
    return sb.toString();
  }
}
