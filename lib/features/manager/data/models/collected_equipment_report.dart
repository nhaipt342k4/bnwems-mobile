class CollectedEquipmentReportItem {
  final String cerItemId;
  final String itemId;
  final String itemName;
  final String unit;
  final int goodQuantity;
  final int damagedQuantity;
  final int lostQuantity;
  final String? notes;

  CollectedEquipmentReportItem({
    required this.cerItemId,
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.goodQuantity,
    required this.damagedQuantity,
    required this.lostQuantity,
    this.notes,
  });

  factory CollectedEquipmentReportItem.fromJson(Map<String, dynamic> json) {
    return CollectedEquipmentReportItem(
      cerItemId: json['cerItemId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'Cái',
      goodQuantity: (json['goodQuantity'] as num?)?.toInt() ?? 0,
      damagedQuantity: (json['damagedQuantity'] as num?)?.toInt() ?? 0,
      lostQuantity: (json['lostQuantity'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
    );
  }
}

class CollectedEquipmentReportActor {
  final String userId;
  final String fullName;

  CollectedEquipmentReportActor({
    required this.userId,
    required this.fullName,
  });

  factory CollectedEquipmentReportActor.fromJson(Map<String, dynamic> json) {
    return CollectedEquipmentReportActor(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }
}

class CollectedEquipmentReport {
  final String reportId;
  final String orderId;
  final String orderCode;
  final String reportType; // 'INTERNAL' | 'SUPPLIER'
  final String status; // 'SUBMITTED' | 'CONFIRMED'
  final CollectedEquipmentReportActor reportedBy;
  final CollectedEquipmentReportActor? confirmedBy;
  final String? confirmedAt;
  final String? notes;
  final String createdAt;
  final List<CollectedEquipmentReportItem> items;
  final String? eventName;

  CollectedEquipmentReport({
    required this.reportId,
    required this.orderId,
    required this.orderCode,
    required this.reportType,
    required this.status,
    required this.reportedBy,
    this.confirmedBy,
    this.confirmedAt,
    this.notes,
    required this.createdAt,
    required this.items,
    this.eventName,
  });

  factory CollectedEquipmentReport.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => CollectedEquipmentReportItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return CollectedEquipmentReport(
      reportId: json['reportId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? 'INTERNAL',
      status: json['status']?.toString() ?? 'SUBMITTED',
      reportedBy: CollectedEquipmentReportActor.fromJson(
        (json['reportedBy'] as Map<String, dynamic>?) ?? {},
      ),
      confirmedBy: json['confirmedBy'] != null
          ? CollectedEquipmentReportActor.fromJson(json['confirmedBy'] as Map<String, dynamic>)
          : null,
      confirmedAt: json['confirmedAt']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      items: itemsList,
      eventName: json['eventName']?.toString(),
    );
  }
}
