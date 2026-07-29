class Settlement {
  final String settlementId;
  final String orderId;
  final double additionalFee;
  final double compensation;
  final double discount;
  final double finalAmount;
  final String? paymentMethod;
  final String? paidAt;
  final String status; // 'UNPAID' | 'PAID' | 'CANCELLED'
  final String? notes;
  final String createdAt;
  final String updatedAt;

  // FE Pending extra fields
  final String? orderCode;
  final String? customerName;
  final String? eventName;

  Settlement({
    required this.settlementId,
    required this.orderId,
    required this.additionalFee,
    required this.compensation,
    required this.discount,
    required this.finalAmount,
    this.paymentMethod,
    this.paidAt,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.orderCode,
    this.customerName,
    this.eventName,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      settlementId: json['settlementId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      additionalFee: (json['additionalFee'] as num?)?.toDouble() ?? 0.0,
      compensation: (json['compensation'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString(),
      paidAt: json['paidAt']?.toString(),
      status: json['status']?.toString() ?? 'UNPAID',
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      orderCode: json['orderCode']?.toString(),
      customerName: json['customerName']?.toString(),
      eventName: json['eventName']?.toString(),
    );
  }

  Settlement copyWithPendingInfo({
    String? orderCode,
    String? customerName,
    String? eventName,
  }) {
    return Settlement(
      settlementId: settlementId,
      orderId: orderId,
      additionalFee: additionalFee,
      compensation: compensation,
      discount: discount,
      finalAmount: finalAmount,
      paymentMethod: paymentMethod,
      paidAt: paidAt,
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
