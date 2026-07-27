class Deposit {
  final String depositId;
  final String depositCode;
  final String orderId;
  final double amount;
  final String? dueDate;
  final String? paymentDate;
  final String? paymentMethod;
  final String status; // 'UNPAID' | 'PAID' | 'CANCELLED'
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // FE Pending extra fields
  final String? orderCode;
  final String? customerName;
  final String? eventName;

  Deposit({
    required this.depositId,
    required this.depositCode,
    required this.orderId,
    required this.amount,
    this.dueDate,
    this.paymentDate,
    this.paymentMethod,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.orderCode,
    this.customerName,
    this.eventName,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      depositId: json['depositId']?.toString() ?? '',
      depositCode: json['depositCode']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: json['dueDate']?.toString(),
      paymentDate: json['paymentDate']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      status: json['status']?.toString() ?? 'UNPAID',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      orderCode: json['orderCode']?.toString(),
      customerName: json['customerName']?.toString(),
      eventName: json['eventName']?.toString(),
    );
  }

  Deposit copyWithPendingInfo({
    String? orderCode,
    String? customerName,
    String? eventName,
  }) {
    return Deposit(
      depositId: depositId,
      depositCode: depositCode,
      orderId: orderId,
      amount: amount,
      dueDate: dueDate,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      status: status,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      eventName: eventName ?? this.eventName,
    );
  }
}
