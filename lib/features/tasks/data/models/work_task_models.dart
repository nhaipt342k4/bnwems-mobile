typedef SchedulePlanStatus = String; // 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
typedef WorkTaskCode = String; // 'SURVEY' | 'SETUP' | 'COLLECT'
typedef PlanAssigneeRole = String; // 'LEAD' | 'TECHNICAL'

class SchedulePlanAssignee {
  final String assigneeId;
  final String planId;
  final String userId;
  final String fullName;
  final PlanAssigneeRole role;
  final String? phone;
  final String? checkInAt;
  final String? checkOutAt;
  final String? checkInEvidenceId;

  SchedulePlanAssignee({
    required this.assigneeId,
    required this.planId,
    required this.userId,
    required this.fullName,
    required this.role,
    this.phone,
    this.checkInAt,
    this.checkOutAt,
    this.checkInEvidenceId,
  });

  bool get isCheckedIn => checkInAt != null && checkInAt!.isNotEmpty;
  bool get isCheckedOut => checkOutAt != null && checkOutAt!.isNotEmpty;

  factory SchedulePlanAssignee.fromJson(String planId, Map<String, dynamic> json) {
    final userId = json['userId']?.toString() ?? '';
    return SchedulePlanAssignee(
      assigneeId: '$planId:$userId',
      planId: planId,
      userId: userId,
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'TECHNICAL',
      phone: json['phone']?.toString(),
      checkInAt: json['checkInAt']?.toString(),
      checkOutAt: json['checkOutAt']?.toString(),
      checkInEvidenceId: json['checkInEvidenceId']?.toString(),
    );
  }
}

class WorkTaskItem {
  final String itemId;
  final String name;
  final String unit;
  final int quantity;
  final int? quantityAvailable;
  final String? source; // 'INTERNAL' | 'SUPPLIER'
  final double rentalPrice;

  WorkTaskItem({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.quantity,
    this.quantityAvailable,
    this.source,
    this.rentalPrice = 0.0,
  });

  factory WorkTaskItem.fromJson(Map<String, dynamic> json) {
    return WorkTaskItem(
      itemId: json['itemId']?.toString() ?? '',
      name: json['itemName']?.toString() ?? json['name']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      quantity: (json['quantityOrdered'] ?? json['quantity'] ?? 0) as int,
      quantityAvailable: (json['quantityAvailable'] as num?)?.toInt(),
      source: json['source']?.toString(),
      rentalPrice: (json['rentalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Parse mảng evidenceId (BE trả `evidenceIds: string[]`) thành `List<String>` an toàn.
List<String> parseEvidenceIds(dynamic v) {
  if (v is List) {
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  return const [];
}

class SchedulePlan {
  final String planId;
  final String planCode;
  final String orderId;
  final String orderCode;
  final String? eventName;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String taskId;
  final WorkTaskCode taskCode;
  final String taskName;
  final String startTime;
  final String? endTime;
  final String? location;
  final SchedulePlanStatus status;
  final List<String> evidenceIds;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final List<SchedulePlanAssignee> assignees;
  final List<WorkTaskItem> items;
  final List<SupplierTransaction> supplierTransactions;
  final String? createdAt;

  SchedulePlan({
    required this.planId,
    required this.planCode,
    required this.orderId,
    required this.orderCode,
    this.eventName,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.taskId,
    required this.taskCode,
    required this.taskName,
    required this.startTime,
    this.endTime,
    this.location,
    this.latitude,
    this.longitude,
    required this.status,
    this.evidenceIds = const [],
    this.notes,
    required this.assignees,
    this.items = const [],
    this.supplierTransactions = const [],
    this.createdAt,
  });

  SchedulePlan copyWith({
    SchedulePlanStatus? status,
    List<String>? evidenceIds,
    List<SchedulePlanAssignee>? assignees,
    List<WorkTaskItem>? items,
    List<SupplierTransaction>? supplierTransactions,
    String? createdAt,
  }) {
    return SchedulePlan(
      planId: planId,
      planCode: planCode,
      orderId: orderId,
      orderCode: orderCode,
      eventName: eventName,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      taskId: taskId,
      taskCode: taskCode,
      taskName: taskName,
      startTime: startTime,
      endTime: endTime,
      location: location,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      notes: notes,
      assignees: assignees ?? this.assignees,
      items: items ?? this.items,
      supplierTransactions: supplierTransactions ?? this.supplierTransactions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SchedulePlan.fromDtoJson(Map<String, dynamic> json) {
    final planId = json['planId']?.toString() ?? '';
    final assigneesRaw = (json['assignees'] as List<dynamic>?) ?? [];
    final assignees = assigneesRaw
        .map((a) => SchedulePlanAssignee.fromJson(planId, a as Map<String, dynamic>))
        .toList();

    return SchedulePlan(
      planId: planId,
      planCode: json['planCode']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      eventName: json['eventName']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      taskCode: json['taskCode']?.toString() ?? 'SETUP',
      taskName: json['taskName']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString(),
      location: json['location']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['event']?['latitude'] as num?)?.toDouble() ??
          (json['order']?['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['event']?['longitude'] as num?)?.toDouble() ??
          (json['order']?['longitude'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'PENDING',
      evidenceIds: parseEvidenceIds(json['evidenceIds']),
      notes: json['notes']?.toString(),
      assignees: assignees,
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }
}

class SurveyReport {
  final String submittedAt;
  final double area;
  final double length;
  final double width;
  final String entrance;
  final String? siteConstraints;
  final String? proposedItems;
  final List<String> evidencePhotoUrls;
  final String? notes;

  SurveyReport({
    required this.submittedAt,
    required this.area,
    required this.length,
    required this.width,
    required this.entrance,
    this.siteConstraints,
    this.proposedItems,
    this.evidencePhotoUrls = const [],
    this.notes,
  });

  /// Ảnh đầu tiên (giữ để tương thích code cũ chỉ hiển thị 1 ảnh).
  String get evidencePhotoUrl => evidencePhotoUrls.isEmpty ? '' : evidencePhotoUrls.first;

  factory SurveyReport.fromJson(Map<String, dynamic> json, {List<String> evidencePhotoUrls = const []}) {
    return SurveyReport(
      submittedAt: json['createdAt']?.toString() ?? json['surveyDate']?.toString() ?? '',
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      entrance: json['entrance']?.toString() ?? '',
      siteConstraints: json['siteConstraints']?.toString(),
      proposedItems: json['proposedItems']?.toString(),
      evidencePhotoUrls: evidencePhotoUrls,
      notes: json['notes']?.toString(),
    );
  }
}

class FieldPaymentRecord {
  final String submittedAt;
  final String method; // 'cash' | 'bank_transfer'
  final num amount;
  final String? note;
  final String? evidencePhotoUrl;

  FieldPaymentRecord({
    required this.submittedAt,
    required this.method,
    required this.amount,
    this.note,
    this.evidencePhotoUrl,
  });

  factory FieldPaymentRecord.fromJson(Map<String, dynamic> json, {String? evidencePhotoUrl}) {
    num parseNum(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      if (val is String) return num.tryParse(val) ?? 0;
      return 0;
    }

    return FieldPaymentRecord(
      submittedAt: json['createdAt']?.toString() ?? '',
      method: json['paymentMethod']?.toString() ?? 'cash',
      amount: parseNum(json['amount']),
      note: json['notes']?.toString(),
      evidencePhotoUrl: evidencePhotoUrl,
    );
  }
}

class CollectedEquipmentReportItem {
  final String itemId;
  final String name;
  final String unit;
  final int expectedQuantity;
  final int goodQuantity;
  final int damagedQuantity;
  final int lostQuantity;
  final String? notes;

  CollectedEquipmentReportItem({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.expectedQuantity,
    required this.goodQuantity,
    required this.damagedQuantity,
    required this.lostQuantity,
    this.notes,
  });

  factory CollectedEquipmentReportItem.fromJson(Map<String, dynamic> json) {
    final good = (json['goodQuantity'] as num?)?.toInt() ?? 0;
    final damaged = (json['damagedQuantity'] as num?)?.toInt() ?? 0;
    final lost = (json['lostQuantity'] as num?)?.toInt() ?? 0;
    return CollectedEquipmentReportItem(
      itemId: json['itemId']?.toString() ?? '',
      name: json['itemName']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      expectedQuantity: (json['expectedQuantity'] as num?)?.toInt() ?? (good + damaged + lost),
      goodQuantity: good,
      damagedQuantity: damaged,
      lostQuantity: lost,
      notes: json['notes']?.toString(),
    );
  }
}

class CollectedEquipmentReport {
  final String reportId;
  final String reportType; // 'INTERNAL' | 'SUPPLIER'
  final String? transactionId;
  final String status;
  final String? notes;
  final String submittedAt;
  final String? confirmedAt;
  final List<CollectedEquipmentReportItem> items;
  final List<String> evidenceIds;

  CollectedEquipmentReport({
    required this.reportId,
    required this.reportType,
    this.transactionId,
    required this.status,
    this.notes,
    required this.submittedAt,
    this.confirmedAt,
    required this.items,
    this.evidenceIds = const [],
  });

  factory CollectedEquipmentReport.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    return CollectedEquipmentReport(
      reportId: json['reportId']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? 'INTERNAL',
      transactionId: json['transactionId']?.toString(),
      status: json['status']?.toString() ?? 'SUBMITTED',
      notes: json['notes']?.toString(),
      submittedAt: json['createdAt']?.toString() ?? '',
      confirmedAt: json['confirmedAt']?.toString(),
      items: rawItems
          .map((i) => CollectedEquipmentReportItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      evidenceIds: parseEvidenceIds(json['evidenceIds']),
    );
  }
}

class Settlement {
  final String settlementId;
  final num additionalFee;
  final num compensation;
  final num discount;
  final num finalAmount;
  final String? paymentMethod;
  final String? qrCodeUrl;
  final String? paidAt;
  final String? evidencePhotoUrl;
  final List<String> evidenceIds;
  final String status; // 'DRAFT' | 'PENDING_APPROVAL' | 'APPROVED' | 'REJECTED' | 'PAID'
  final String? requestedAt;
  final String? notes;

  Settlement({
    required this.settlementId,
    required this.additionalFee,
    required this.compensation,
    required this.discount,
    required this.finalAmount,
    this.paymentMethod,
    this.qrCodeUrl,
    this.paidAt,
    this.evidencePhotoUrl,
    this.evidenceIds = const [],
    required this.status,
    this.requestedAt,
    this.notes,
  });

  factory Settlement.fromJson(Map<String, dynamic> json, {String? evidencePhotoUrl}) {
    num parseNum(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val;
      if (val is String) return num.tryParse(val) ?? 0;
      return 0;
    }

    return Settlement(
      settlementId: json['settlementId']?.toString() ?? '',
      additionalFee: parseNum(json['additionalFee']),
      compensation: parseNum(json['compensation']),
      discount: parseNum(json['discount']),
      finalAmount: parseNum(json['finalAmount']),
      paymentMethod: json['paymentMethod']?.toString(),
      qrCodeUrl: json['qrCodeUrl']?.toString(),
      paidAt: json['paidAt']?.toString(),
      evidencePhotoUrl: evidencePhotoUrl,
      evidenceIds: parseEvidenceIds(json['evidenceIds']),
      status: json['status']?.toString() ?? 'DRAFT',
      requestedAt: json['requestedAt']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class SupplierTransactionItem {
  final String stItemId;
  final String itemId;
  final String itemName;
  final int quantity;
  final num unitCost;
  final int receivedQuantity;
  final String? notes;

  SupplierTransactionItem({
    required this.stItemId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitCost,
    required this.receivedQuantity,
    this.notes,
  });

  factory SupplierTransactionItem.fromJson(Map<String, dynamic> json) {
    return SupplierTransactionItem(
      stItemId: json['stItemId']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitCost: (json['unitCost'] as num?) ?? 0,
      receivedQuantity: (json['receivedQuantity'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
    );
  }
}

class SupplierTransaction {
  final String transactionId;
  final String transactionCode;
  final String supplierName;
  final String transactionType;
  final String serviceTitle;
  final num estimatedCost;
  final num depositAmount;
  final String status;
  final List<SupplierTransactionItem> items;

  SupplierTransaction({
    required this.transactionId,
    required this.transactionCode,
    required this.supplierName,
    required this.transactionType,
    required this.serviceTitle,
    required this.estimatedCost,
    required this.depositAmount,
    required this.status,
    required this.items,
  });

  factory SupplierTransaction.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? [];
    return SupplierTransaction(
      transactionId: json['transactionId']?.toString() ?? '',
      transactionCode: json['transactionCode']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
      transactionType: json['transactionType']?.toString() ?? '',
      serviceTitle: json['serviceTitle']?.toString() ?? '',
      estimatedCost: (json['estimatedCost'] as num?) ?? 0,
      depositAmount: (json['depositAmount'] as num?) ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      items: rawItems
          .map((i) => SupplierTransactionItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserNotification {
  final String notificationId;
  final String userId;
  final String title;
  final String? content;
  final String? type;
  final bool isRead;
  final String createdAt;

  UserNotification({
    required this.notificationId,
    required this.userId,
    required this.title,
    this.content,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      notificationId: json['notificationId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString(),
      type: json['type']?.toString(),
      isRead: json['isRead'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
