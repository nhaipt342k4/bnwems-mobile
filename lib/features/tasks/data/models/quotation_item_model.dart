class QuotationItemInput {
  final String id;
  final String? itemId;
  final String name;
  final String category;
  final String unit;
  int quantity;
  double unitPrice;
  double discountPerItem;

  QuotationItemInput({
    required this.id,
    this.itemId,
    required this.name,
    required this.category,
    required this.unit,
    this.quantity = 1,
    required this.unitPrice,
    this.discountPerItem = 0.0,
  });

  double get subtotal => unitPrice * quantity;
  double get totalDiscount => discountPerItem * quantity;
  double get totalAmount {
    final effectivePrice = (unitPrice - discountPerItem);
    return (effectivePrice < 0 ? 0.0 : effectivePrice) * quantity;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'name': name,
      'category': category,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPerItem': discountPerItem,
    };
  }

  factory QuotationItemInput.fromJson(Map<String, dynamic> json) {
    return QuotationItemInput(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: json['itemId']?.toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Khác',
      unit: json['unit']?.toString() ?? 'Cái',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discountPerItem: (json['discountPerItem'] as num?)?.toDouble() ?? 0.0,
    );
  }

  QuotationItemInput copyWith({
    String? id,
    String? itemId,
    String? name,
    String? category,
    String? unit,
    int? quantity,
    double? unitPrice,
    double? discountPerItem,
  }) {
    return QuotationItemInput(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPerItem: discountPerItem ?? this.discountPerItem,
    );
  }
}

class CatalogItemPreset {
  final String? itemId;
  final String name;
  final String category;
  final String unit;
  final double defaultPrice;

  const CatalogItemPreset({
    this.itemId,
    required this.name,
    required this.category,
    required this.unit,
    required this.defaultPrice,
  });
}

/// Danh mục kho thiết bị sẵn có tham khảo từ hệ thống
const List<CatalogItemPreset> defaultEquipmentCatalog = [
  // Máy quay & Flycam
  CatalogItemPreset(itemId: 'EQ-001', name: 'Flycam DJI Mavic 3', category: 'Máy quay & Flycam', unit: 'Cái', defaultPrice: 3000000),
  CatalogItemPreset(itemId: 'EQ-002', name: 'Máy quay sự kiện Sony FX6', category: 'Máy quay & Flycam', unit: 'Cái', defaultPrice: 2500000),
  
  // Loa & Âm thanh
  CatalogItemPreset(itemId: 'EQ-003', name: 'Loa JBL 1000W', category: 'Loa', unit: 'Cái', defaultPrice: 500000),
  CatalogItemPreset(itemId: 'EQ-004', name: 'Loa Line Array sự kiện', category: 'Loa', unit: 'Bộ', defaultPrice: 1200000),
  CatalogItemPreset(itemId: 'EQ-005', name: 'Bàn Mixer Yamaha', category: 'Loa', unit: 'Cái', defaultPrice: 800000),
  
  // Đèn & Ánh sáng
  CatalogItemPreset(itemId: 'EQ-006', name: 'Đèn Par LED 54x3W', category: 'Đèn Par LED', unit: 'Cái', defaultPrice: 150000),
  CatalogItemPreset(itemId: 'EQ-007', name: 'Đèn Beam 230W', category: 'Đèn Par LED', unit: 'Cái', defaultPrice: 300000),
  
  // Thảm & Sân khấu
  CatalogItemPreset(itemId: 'EQ-008', name: 'Thảm đỏ sân khấu', category: 'Thảm sân khấu', unit: 'm²', defaultPrice: 50000),
  CatalogItemPreset(itemId: 'EQ-009', name: 'Khung sân khấu di động', category: 'Thảm sân khấu', unit: 'm²', defaultPrice: 200000),
  CatalogItemPreset(itemId: 'EQ-010', name: 'Cổng hoa sự kiện', category: 'Cổng hoa', unit: 'Bộ', defaultPrice: 1500000),
  
  // Bàn ghế & Dụng cụ
  CatalogItemPreset(itemId: 'EQ-011', name: 'Bàn chữ nhật 1.2m', category: 'Bàn chữ nhật', unit: 'Cái', defaultPrice: 100000),
  CatalogItemPreset(itemId: 'EQ-012', name: 'Bàn tiệc tròn', category: 'Bàn chữ nhật', unit: 'Cái', defaultPrice: 150000),
];
