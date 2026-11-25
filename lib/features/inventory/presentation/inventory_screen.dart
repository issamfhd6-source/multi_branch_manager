import 'package:flutter/material.dart';

import '../../../core/models/domain_models.dart';
import '../../../core/utils/dual_syp_formatter.dart';
import '../../../core/utils/safe_number_parser.dart';
import '../../users/domain/auth_models.dart';
import '../data/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  final InventoryService inventoryService;
  final AuthSession session;
  final String branchId;
  final ValueChanged<List<ProductModel>>? onProductsChanged;

  const InventoryScreen({
    super.key,
    required this.inventoryService,
    required this.session,
    required this.branchId,
    this.onProductsChanged,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _loading = false;
  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final list = await widget.inventoryService.getAllProducts();
      if (!mounted) return;
      setState(() => _products = list);
      widget.onProductsChanged?.call(list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل المخزون: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openProductDialog({ProductModel? existing}) async {
    final idCtrl = TextEditingController(
      text: existing?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
    );
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.unitPriceNewSyp.toString() : '',
    );
    final qtyCtrl = TextEditingController(
      text: existing != null ? existing.stockQty.toString() : '0',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'إضافة مادة' : 'تعديل مادة'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skuCtrl,
                decoration: const InputDecoration(labelText: 'رمز المادة (SKU)'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم المادة'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'السعر (ل.س جديدة)',
                ),
              ),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الكمية'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final sku = skuCtrl.text.trim();
    final name = nameCtrl.text.trim();
    if (sku.isEmpty || name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال رمز المادة واسمها.')),
      );
      return;
    }

    final priceNewSyp = SafeNumberParser.parseDouble(priceCtrl.text);
    final qty = SafeNumberParser.parseDouble(qtyCtrl.text);

    try {
      await widget.inventoryService.upsertProduct(
        session: widget.session,
        id: idCtrl.text.trim(),
        sku: sku,
        name: name,
        unitPriceNewSyp: priceNewSyp,
        stockQty: qty,
        branchId: widget.branchId,
      );
      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المادة بنجاح.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ المادة: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('مادة جديدة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text('لا توجد مواد في المخزون بعد.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 84),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          'SKU: ${item.sku} | الكمية: ${item.stockQty}\n'
                          'السعر: ${DualSypFormatter.formatDualFromNew(item.unitPriceNewSyp)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openProductDialog(existing: item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
