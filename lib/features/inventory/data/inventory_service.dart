import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/domain_models.dart';
import '../../exchange_rate/data/exchange_rate_service.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class InventoryService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;
  final AuditService _audit;
  final ExchangeRateService _rateService;

  InventoryService(
    this._db,
    this._permissions,
    this._audit,
    this._rateService,
  );

  Future<List<ProductModel>> getAllProducts() async {
    final rows = await _db.select(_db.products).get();
    return rows.map(_mapRowToProduct).toList();
  }

  Future<void> upsertProduct({
    required AuthSession session,
    required String id,
    required String sku,
    required String name,
    required double unitPriceNewSyp,
    required double stockQty,
    String? branchId,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'manage_inventory',
      entity: 'products',
    );

    final rate = await _rateService.getCurrentRate();
    final safeRate = rate <= 0 ? 1.0 : rate;
    final unitPriceUsd = unitPriceNewSyp / safeRate;

    await _db.into(_db.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: Value(id),
            sku: Value(sku.trim()),
            name: Value(name.trim()),
            unitPriceNewSyp: Value(unitPriceNewSyp),
            unitPriceUsd: Value(unitPriceUsd),
            stockQty: Value(stockQty),
            updatedAt: Value(DateTime.now()),
          ),
        );

    await _audit.log(
      actorId: session.user.id,
      action: 'upsert_product',
      entity: 'products',
      entityId: id,
      branchId: branchId ??
          (session.user.branchIds.isNotEmpty
              ? session.user.branchIds.first
              : 'branch_main'),
      details: 'SKU=${sku.trim()}, qty=$stockQty, newSyp=$unitPriceNewSyp',
    );
  }

  ProductModel _mapRowToProduct(Product row) {
    final dynamic r = row;
    final idVal = (r.id ?? '').toString();
    final skuVal = (r.sku ?? '').toString();
    final nameVal = (r.name ?? '').toString();
    final unitVal = (r.unit ?? 'قطعة').toString();
    final wholesaleVal = _toDouble(r.wholesale ?? r.wholesalePrice ?? r.unitPriceNewSyp);

    return ProductModel(
      id: idVal,
      sku: skuVal,
      name: nameVal,
      unit: unitVal,
      wholesale: wholesaleVal,
    );
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
