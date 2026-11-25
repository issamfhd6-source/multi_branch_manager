class ProductModel {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? qr;
  final String categoryId;
  final String unit;
  final List<String> images;
  final double cost;
  final double price;
  final double wholesale;
  final double minStock;
  final DateTime? expiry;
  final String? supplierId;
  final String? notes;

  const ProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.qr,
    required this.categoryId,
    required this.unit,
    this.images = const [],
    required this.cost,
    required this.price,
    required this.wholesale,
    required this.minStock,
    this.expiry,
    this.supplierId,
    this.notes,
  });
}
