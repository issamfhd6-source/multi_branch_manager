import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class ExchangeRateService {
  final AppDatabase _db;
  final PermissionMiddleware _permissions;
  final AuditService _audit;

  ExchangeRateService(this._db, this._permissions, this._audit);

  Future<ExchangeRate?> getEffectiveRate(DateTime at) async {
    final rows = await (_db.select(_db.exchangeRates)
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)]))
        .get();
    if (rows.isEmpty) return null;

    for (final r in rows) {
      if (!r.effectiveFrom.isAfter(at)) {
        return r;
      }
    }
    return rows.last;
  }

  Future<void> setRate({
    required AuthSession session,
    required double usdToSyp,
    DateTime? effectiveFrom,
  }) async {
    await _permissions.enforce(
      session: session,
      action: 'manage_settings',
      entity: 'exchange_rates',
    );

    if (usdToSyp.isNaN || usdToSyp.isInfinite || usdToSyp <= 0) {
      throw ArgumentError('سعر الصرف يجب أن يكون رقمًا موجبًا صالحًا.');
    }

    final now = DateTime.now();
    final id = 'fx_${now.millisecondsSinceEpoch}';
    final effective = effectiveFrom ?? now;

    await _db.into(_db.exchangeRates).insert(
          ExchangeRatesCompanion.insert(
            id: id,
            usdToSyp: usdToSyp,
            effectiveFrom: effective,
            createdAt: now,
          ),
        );

    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            id: 'sync_$id',
            entity: 'exchange_rates',
            entityId: id,
            operation: 'upsert',
            payload: jsonEncode({
              'id': id,
              'usd_to_syp': usdToSyp,
              'effective_from': effective.toIso8601String(),
            }),
            createdAt: now,
          ),
        );

    await _audit.record(
      userId: session.user.id,
      action: 'set_exchange_rate',
      entity: 'exchange_rates',
      entityId: id,
      details: 'rate=$usdToSyp',
    );
  }
}
