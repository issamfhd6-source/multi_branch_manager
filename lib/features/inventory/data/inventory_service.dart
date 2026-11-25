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

  Future<double> _resolveRate() async {
    final dynamic svc = _rateService;
    try {
      final res = await svc.getCurrentRate();
      return _toDouble(res);
    } catch (_) {
      try {
        final res = await svc.getLatestRate();
        return _toDouble(res);
      } catch (_) {
        return 100.0;
      }
    }
  }

  Future<void> _writeAudit({
    required String actorId,
    required String action,
    required String entity,
    required String entityId,
    required String branchId,
    required String details,
  }) async {
    final dynamic audit = _audit;
    try {
      await audit.log(
        actorId: actorId,
        action: action,
        entity: entity,
        entityId: entityId,
        branchId: branchId,
        details: details,
      );
      return;
    } catch (_) {}

    try {
      await audit.record(
        actorId: actorId,
        action: action,
        entity: entity,
        entityId: entityId,
        branchId: branchId,
        details: details,
      );
    } catch (_) {}
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

    final rate = await _resolveRate();
    final safeRate = rate <= 0 ? 1.0 : rate;
    final unitPriceUsd = unitPriceNewSyp / safeRate;

    final dynamic ctor = ProductsCompanion.new;
    ProductsCompanion companion;
    try {
      companion = ctor(
        id: Value(id),
        categoryId: const Value('general'),
        sku: Value(sku.trim()),
        name: Value(name.trim()),
        unit: const Value('قطعة'),
        price: Value(unitPriceNewSyp),
        wholesale: Value(unitPriceNewSyp),
        cost: Value(unitPriceUsd),
        minStock: const Value(0.0),
      );
    } catch (_) {
      companion = ProductsCompanion(
        id: Value(id),
        sku: Value(sku.trim()),
        name: Value(name.trim()),
      );
    }

    await _db.into(_db.products).insertOnConflictUpdate(companion);

    await _writeAudit(
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
    final categoryIdVal =
        (r.categoryId ?? r.category_id ?? 'general').toString();
    final unitVal = (r.unit ?? 'قطعة').toString();
    final wholesaleVal =
        _toDouble(r.wholesale ?? r.wholesalePrice ?? r.unitPriceNewSyp);
    final minStockVal = _toDouble(r.minStock ?? r.min_stock ?? 0);
    final priceVal =
        _toDouble(r.price ?? r.unitPriceNewSyp ?? r.unit_price_new_syp ?? 0);
    final costVal =
        _toDouble(r.cost ?? r.costPrice ?? r.wholesale ?? priceVal);

    return ProductModel(
      id: idVal,
      categoryId: categoryIdVal,
      sku: skuVal,
      name: nameVal,
      unit: unitVal,
      wholesale: wholesaleVal,
      minStock: minStockVal,
      price: priceVal,
      cost: costVal,
    );
  }

  double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
