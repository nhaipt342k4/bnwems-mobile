class ChangeRequestItem {
  final String changeRequestItemId;
  final String catalogItemId;
  final String itemName;
  final int quantity;
  final String action; // 'add' | 'remove'
  final double rentalPrice;

  ChangeRequestItem({
    required this.changeRequestItemId,
    required this.catalogItemId,
    required this.itemName,
    required this.quantity,
    required this.action,
    required this.rentalPrice,
  });

  factory ChangeRequestItem.fromJson(Map<String, dynamic> json) {
    return ChangeRequestItem(
      changeRequestItemId: json['changeRequestItemId']?.toString() ?? '',
      catalogItemId: json['catalogItemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      action: json['action']?.toString() ?? 'add',
      rentalPrice: (json['rentalPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChangeRequest {
  final String changeRequestId;
  final String orderId;
  final String orderCode;
  final String? eventName;
  final String customerName;
  final String customerPhone;
  final String type; // 'add' | 'remove' | 'replace'
  final String status; // 'pending' | 'approved' | 'rejected'
  final double amount;
  final String createdAt;
  final List<ChangeRequestItem> items;

  ChangeRequest({
    required this.changeRequestId,
    required this.orderId,
    required this.orderCode,
    this.eventName,
    required this.customerName,
    required this.customerPhone,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.items,
  });

  factory ChangeRequest.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => ChangeRequestItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ChangeRequest(
      changeRequestId: json['changeRequestId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      eventName: json['eventName']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      type: json['type']?.toString() ?? 'add',
      status: json['status']?.toString() ?? 'pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString() ?? '',
      items: itemsList,
    );
  }
}
