import 'package:flutter/material.dart';

import '../../../core/models/domain_models.dart';
import '../../../core/utils/dual_syp_formatter.dart';
import '../../../core/utils/safe_number_parser.dart';
import '../../users/domain/auth_models.dart';
import '../data/pos_service.dart';

class PosScreen extends StatefulWidget {
  final PosService posService;
  final AuthSession session;
  final String branchId;
  final List<ProductModel> availableProducts;

  const PosScreen({
    super.key,
    required this.posService,
    required this.session,
    required this.branchId,
    required this.availableProducts,
  });

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final Map<String, PosCartLine> _cart = {};
  final _discountCtrl = TextEditingController(text: '0');
  bool _submitting = false;

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  void _addProduct(ProductModel p) {
    setState(() {
      final existing = _cart[p.id];
      final nextQty = (existing?.qty ?? 0.0) + 1.0;
      _cart[p.id] = PosCartLine(
        product: p,
        qty: nextQty,
        discountNewSyp: existing?.discountNewSyp ?? 0.0,
      );
    });
  }

  void _removeOne(String productId) {
    setState(() {
      final existing = _cart[productId];
      if (existing == null) return;
      if (existing.qty <= 1.0) {
        _cart.remove(productId);
      } else {
        _cart[productId] = PosCartLine(
          product: existing.product,
          qty: existing.qty - 1.0,
          discountNewSyp: existing.discountNewSyp,
        );
      }
    });
  }

  double get _subtotalNew {
    double sum = 0.0;
    for (final line in _cart.values) {
      sum += line.lineTotalNewSyp;
    }
    return sum;
  }

  double get _totalAfterDiscountNew {
    final disc = SafeNumberParser.parseDouble(_discountCtrl.text, fallback: 0);
    final safeDisc = disc < 0 ? 0.0 : disc;
    final net = _subtotalNew - safeDisc;
    return net < 0 ? 0.0 : net;
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty || _submitting) return;
    setState(() => _submitting = true);

    try {
      final disc =
          SafeNumberParser.parseDouble(_discountCtrl.text, fallback: 0);
      final invId = await widget.posService.checkoutSale(
        session: widget.session,
        branchId: widget.branchId,
        lines: _cart.values.toList(),
        invoiceDiscountNewSyp: disc < 0 ? 0.0 : disc,
      );
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _discountCtrl.text = '0';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الفاتورة أوفلاين بنجاح ($invId)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إتمام الفاتورة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.availableProducts;
    final cartLines = _cart.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع (POS)'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: products.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد منتجات متاحة بعد. أضف منتجات من تبويب المخزون.',
                    ),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (ctx, i) {
                      final p = products[i];
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text(
                          DualSypFormatter.formatDualFromNew(p.price),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => _addProduct(p),
                          child: const Text('إضافة'),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'عناصر السلة (${cartLines.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: cartLines.isEmpty
                        ? const Center(child: Text('السلة فارغة'))
                        : ListView.builder(
                            itemCount: cartLines.length,
                            itemBuilder: (ctx, i) {
                              final line = cartLines[i];
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${line.product.name} × ${line.qty.toStringAsFixed(0)}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DualSypFormatter.formatDualFromNew(
                                      line.lineTotalNewSyp,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () =>
                                        _removeOne(line.product.id),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'خصم الفاتورة (ل.س جديدة)',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'الإجمالي: ${DualSypFormatter.formatDualFromNew(_totalAfterDiscountNew)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed:
                        (_cart.isEmpty || _submitting) ? null : _completeSale,
                    child: Text(
                      _submitting ? 'جاري الحفظ...' : 'إتمام الفاتورة',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
