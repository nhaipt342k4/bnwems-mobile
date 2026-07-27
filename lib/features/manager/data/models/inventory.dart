class InventoryRow {
  final String itemId;
  final int quantityTotal;
  final int quantityDamaged;
  final int quantityReserved;
  final int quantityAvailable;
  final String? itemName;
  final String? unit;
  final String updatedAt;

  InventoryRow({
    required this.itemId,
    required this.quantityTotal,
    required this.quantityDamaged,
    required this.quantityReserved,
    required this.quantityAvailable,
    this.itemName,
    this.unit,
    required this.updatedAt,
  });

  factory InventoryRow.fromJson(Map<String, dynamic> json) {
    return InventoryRow(
      itemId: json['itemId']?.toString() ?? '',
      quantityTotal: (json['quantityTotal'] as num?)?.toInt() ?? 0,
      quantityDamaged: (json['quantityDamaged'] as num?)?.toInt() ?? 0,
      quantityReserved: (json['quantityReserved'] as num?)?.toInt() ?? 0,
      quantityAvailable: (json['quantityAvailable'] as num?)?.toInt() ?? 0,
      itemName: json['itemName']?.toString(),
      unit: json['unit']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
