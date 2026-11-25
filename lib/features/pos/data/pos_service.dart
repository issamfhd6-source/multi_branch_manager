import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/domain_models.dart';
import '../../exchange_rate/data/exchange_rate_service.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class PosCartLine {
  final ProductModel product;
  final double qty;
  final double discountNewSyp;

  const PosCartLine({
    required this.product,
    required this.qty,
    this.discountNewSyp = 0.0,
  });

  double get lineSubtotalNewSyp {
    final safeQty = qty.isNaN || qty.isInfinite || qty < 0 ? 0.0 : qty;
    final safePrice =
        product.price.isNaN || product.price.isInfinite || product.price < 0
            ? 0.0
            : product.price;
    return safeQty * safePrice;
  }

  double get lineTotalNewSyp {
    final safeDisc =
        discountNewSyp.isNaN || discountNewSyp.isInfinite || discountNewSyp < 0
            ? 0.0
            : discountNewSyp;
    final net = lineSubtotalNewSyp - safeDisc;
    return net < 0 ? 0.0 : net;
  }
}

class PosService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;
  final AuditService _audit;
  final ExchangeRateService _rateService;

  PosService(
    this._db,
    this._permissions,
    this._audit,
    this._rateService,
  );

  Future<String> checkoutSale({
    required AuthSession session,
    required String branchId,
    required List<PosCartLine> lines,
    double invoiceDiscountNewSyp = 0.0,
    String paymentMethod = 'cash',
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'create_sale',
      entity: 'invoices',
      targetBranchId: branchId,
    );

    final validLines = lines.where((l) => l.qty > 0).toList();
    if (validLines.isEmpty) {
      throw StateError(
        'السلة فارغة؛ أضف منتجًا واحدًا على الأقل لإتمام الفاتورة.',
      );
    }

    final now = DateTime.now();
    final invoiceId = 'inv_${now.microsecondsSinceEpoch}';
    final rateRow = await _rateService.getEffectiveRate(now);
    final usdRate =
        (rateRow != null && rateRow.usdToSyp > 0) ? rateRow.usdToSyp : null;

    double itemsTotal = 0.0;
    for (final line in validLines) {
      itemsTotal += line.lineTotalNewSyp;
    }

    final safeInvDisc = invoiceDiscountNewSyp.isNaN ||
            invoiceDiscountNewSyp.isInfinite ||
            invoiceDiscountNewSyp < 0
        ? 0.0
        : invoiceDiscountNewSyp;
    final finalTotalNew =
        (itemsTotal - safeInvDisc) < 0 ? 0.0 : (itemsTotal - safeInvDisc);
    final usdEquivalent = usdRate != null ? (finalTotalNew / usdRate) : 0.0;

    await _db.transaction(() async {
      await _db.into(_db.invoices).insert(
            InvoicesCompanion.insert(
              id: invoiceId,
              branchId: branchId,
              type: const Value('sale'),
              status: const Value('completed'),
              total: Value(finalTotalNew),
              usdTotal: Value(usdEquivalent),
              discount: Value(safeInvDisc),
              paymentMethod: Value(paymentMethod),
              ts: now,
              createdBy: Value(session.user.id),
            ),
          );

      for (var i = 0; i < validLines.length; i++) {
        final line = validLines[i];
        await _db.into(_db.invoiceItems).insert(
              InvoiceItemsCompanion.insert(
                id: 'itm_${invoiceId}_$i',
                invoiceId: invoiceId,
                productId: line.product.id,
                qty: Value(line.qty),
                price: Value(line.product.price),
                cost: Value(line.product.cost),
                discount: Value(line.discountNewSyp),
              ),
            );

        final stockRows = await (_db.select(_db.branchStocks)
              ..where(
                (t) =>
                    t.productId.equals(line.product.id) &
                    t.branchId.equals(branchId),
              ))
            .get();
        if (stockRows.isNotEmpty) {
          final currentStock = stockRows.first;
          final nextQty = (currentStock.qty - line.qty) < 0
              ? 0.0
              : (currentStock.qty - line.qty);
          await _db
              .into(_db.branchStocks)
              .insertOnConflictUpdate(currentStock.copyWith(qty: nextQty));
        }
      }

      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'sync_$invoiceId',
              entity: 'invoices',
              entityId: invoiceId,
              operation: 'create',
              payload: jsonEncode({
                'id': invoiceId,
                'branch_id': branchId,
                'total_new_syp': finalTotalNew,
                'items_count': validLines.length,
              }),
              createdAt: now,
            ),
          );
    });

    await _audit.record(
      userId: session.user.id,
      action: 'checkout_sale',
      entity: 'invoices',
      entityId: invoiceId,
      branchId: branchId,
      details: 'total_new=$finalTotalNew',
    );

    return invoiceId;
  }
}
