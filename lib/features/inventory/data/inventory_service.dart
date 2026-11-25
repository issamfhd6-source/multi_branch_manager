import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/domain_models.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class InventoryService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;
  final AuditService _audit;

  InventoryService(this._db, this._permissions, this._audit);

  double _safeNonNegative(double v) {
    if (v.isNaN || v.isInfinite || v < 0) return 0.0;
    return v;
  }

  Future<void> createProduct({
    required AuthSession session,
    required ProductModel product,
    required String branchId,
    double initialStock = 0.0,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'manage_products',
      entity: 'products',
      targetBranchId: branchId,
    );

    final now = DateTime.now();
    final safeCost = _safeNonNegative(product.cost);
    final safePrice = _safeNonNegative(product.price);
    final safeWholesale = _safeNonNegative(product.wholesale);
    final safeMinStock = _safeNonNegative(product.minStock);
    final safeStock = _safeNonNegative(initialStock);

    await _db.transaction(() async {
      await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion.insert(
              id: product.id,
              name: product.name,
              sku: product.sku,
              barcode: Value(product.barcode),
              qr: Value(product.qr),
              categoryId: Value(product.categoryId),
              unit: Value(product.unit),
              cost: Value(safeCost),
              price: Value(safePrice),
              wholesale: Value(safeWholesale),
              minStock: Value(safeMinStock),
              expiry: Value(product.expiry),
              supplierId: Value(product.supplierId),
              notes: Value(product.notes),
            ),
          );

      final stockId = 'stk_${branchId}_${product.id}';
      await _db.into(_db.branchStocks).insertOnConflictUpdate(
            BranchStocksCompanion.insert(
              id: stockId,
              productId: product.id,
              branchId: branchId,
              qty: Value(safeStock),
            ),
          );

      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'sync_prd_${now.microsecondsSinceEpoch}',
              entity: 'products',
              entityId: product.id,
              operation: 'upsert',
              payload: jsonEncode({
                'id': product.id,
                'name': product.name,
                'sku': product.sku,
                'cost': safeCost,
                'price': safePrice,
                'branch_id': branchId,
                'initial_stock': safeStock,
              }),
              createdAt: now,
            ),
          );
    });

    await _audit.record(
      userId: session.user.id,
      action: 'create_product',
      entity: 'products',
      entityId: product.id,
      branchId: branchId,
      details: product.name,
    );
  }

  Future<void> updateProduct({
    required AuthSession session,
    required ProductModel product,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'manage_products',
      entity: 'products',
    );

    final now = DateTime.now();
    final safeCost = _safeNonNegative(product.cost);
    final safePrice = _safeNonNegative(product.price);
    final safeWholesale = _safeNonNegative(product.wholesale);
    final safeMinStock = _safeNonNegative(product.minStock);

    await _db.transaction(() async {
      await _db.into(_db.products).insertOnConflictUpdate(
            ProductsCompanion.insert(
              id: product.id,
              name: product.name,
              sku: product.sku,
              barcode: Value(product.barcode),
              qr: Value(product.qr),
              categoryId: Value(product.categoryId),
              unit: Value(product.unit),
              cost: Value(safeCost),
              price: Value(safePrice),
              wholesale: Value(safeWholesale),
              minStock: Value(safeMinStock),
              expiry: Value(product.expiry),
              supplierId: Value(product.supplierId),
              notes: Value(product.notes),
            ),
          );

      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'sync_upd_${now.microsecondsSinceEpoch}',
              entity: 'products',
              entityId: product.id,
              operation: 'update',
              payload: jsonEncode({
                'id': product.id,
                'name': product.name,
                'sku': product.sku,
                'cost': safeCost,
                'price': safePrice,
              }),
              createdAt: now,
            ),
          );
    });

    await _audit.record(
      userId: session.user.id,
      action: 'update_product',
      entity: 'products',
      entityId: product.id,
      details: product.name,
    );
  }

  Future<double> getBranchStockQty({
    required String productId,
    required String branchId,
  }) async {
    final rows = await (_db.select(_db.branchStocks)
          ..where(
            (t) => t.productId.equals(productId) & t.branchId.equals(branchId),
          ))
        .get();
    if (rows.isEmpty) return 0.0;
    return rows.first.qty;
  }
}
