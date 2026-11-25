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
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _costNewCtrl = TextEditingController();
  final _priceNewCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '10');

  List<ProductModel> _products = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _costNewCtrl.dispose();
    _priceNewCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final list = await widget.inventoryService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
      widget.onProductsChanged?.call(list);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addProduct() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final cost =
          SafeNumberParser.parseDouble(_costNewCtrl.text, fallback: 0);
      final price =
          SafeNumberParser.parseDouble(_priceNewCtrl.text, fallback: 0);
      final qty = SafeNumberParser.parseDouble(_qtyCtrl.text, fallback: 0);

      await widget.inventoryService.upsertProduct(
        session: widget.session,
        name: name,
        sku: _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        costNewSyp: cost,
        priceNewSyp: price,
        initialBranchId: widget.branchId,
        initialQty: qty,
      );

      _nameCtrl.clear();
      _skuCtrl.clear();
      _costNewCtrl.clear();
      _priceNewCtrl.clear();
      _qtyCtrl.text = '10';

      await _loadProducts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ المنتج وتحديث المخزون.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ المنتج: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المخزون'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'إضافة / تحديث منتج (بالليرة الجديدة)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _costNewCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'التكلفة (ل.س جديدة)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _priceNewCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'سعر البيع (ل.س جديدة)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'الكمية الأولية',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _skuCtrl,
                          decoration: const InputDecoration(
                            labelText: 'رمز SKU (اختياري)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _saving ? null : _addProduct,
                    child: Text(_saving ? 'جاري الحفظ...' : 'حفظ المنتج'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'قائمة المنتجات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_products.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('لا توجد منتجات مضافة بعد.'),
              ),
            )
          else
            ..._products.map(
              (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    'البيع: ${DualSypFormatter.formatDualFromNew(p.price)}\n'
                    'التكلفة: ${DualSypFormatter.formatDualFromNew(p.cost)}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
