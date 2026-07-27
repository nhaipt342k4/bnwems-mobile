class ManagerOrder {
  final String orderId;
  final String orderCode;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String eventType;
  final String? eventName;
  final String eventDate;
  final String location;
  final double totalAmount;
  final String paymentStatus; // 'UNPAID' | 'DEPOSITED' | 'PAID'
  final String orderStatus; // 'NEW' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  final String createdAt;

  ManagerOrder({
    required this.orderId,
    required this.orderCode,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.eventType,
    this.eventName,
    required this.eventDate,
    required this.location,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
  });

  factory ManagerOrder.fromJson(Map<String, dynamic> json) {
    return ManagerOrder(
      orderId: json['orderId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? '',
      eventName: json['eventName']?.toString(),
      eventDate: json['eventDate']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus']?.toString() ?? 'UNPAID',
      orderStatus: json['orderStatus']?.toString() ?? 'NEW',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderCode': orderCode,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'eventType': eventType,
      'eventName': eventName,
      'eventDate': eventDate,
      'location': location,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'createdAt': createdAt,
    };
  }
}
