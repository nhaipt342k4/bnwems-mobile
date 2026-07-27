class ManagerSchedulePlanAssignee {
  final String userId;
  final String fullName;
  final String role; // 'LEAD' | 'TECHNICAL'
  final String? phone;
  final String? checkInAt;
  final String? checkOutAt;

  ManagerSchedulePlanAssignee({
    required this.userId,
    required this.fullName,
    required this.role,
    this.phone,
    this.checkInAt,
    this.checkOutAt,
  });

  factory ManagerSchedulePlanAssignee.fromJson(Map<String, dynamic> json) {
    return ManagerSchedulePlanAssignee(
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'TECHNICAL',
      phone: json['phone']?.toString(),
      checkInAt: json['checkInAt']?.toString(),
      checkOutAt: json['checkOutAt']?.toString(),
    );
  }
}

class ManagerSchedulePlan {
  final String planId;
  final String planCode;
  final String orderId;
  final String taskId;
  final String startTime;
  final String? endTime;
  final String? location;
  final String status; // 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  final String? evidenceId;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final String? taskName;
  final List<ManagerSchedulePlanAssignee>? assignees;
  final String? orderCode;
  final String? customerName;
  final String? eventName;
  final String? eventDate;
  final String? orderLocation;

  ManagerSchedulePlan({
    required this.planId,
    required this.planCode,
    required this.orderId,
    required this.taskId,
    required this.startTime,
    this.endTime,
    this.location,
    required this.status,
    this.evidenceId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.taskName,
    this.assignees,
    this.orderCode,
    this.customerName,
    this.eventName,
    this.eventDate,
    this.orderLocation,
  });

  factory ManagerSchedulePlan.fromJson(Map<String, dynamic> json) {
    final assigneesList = (json['assignees'] as List<dynamic>?)
        ?.map((e) => ManagerSchedulePlanAssignee.fromJson(e as Map<String, dynamic>))
        .toList();

    return ManagerSchedulePlan(
      planId: json['planId']?.toString() ?? '',
      planCode: json['planCode']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      evidenceId: json['evidenceId']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      taskName: json['taskName']?.toString(),
      assignees: assigneesList,
      orderCode: json['orderCode']?.toString(),
      customerName: json['customerName']?.toString(),
      eventName: json['eventName']?.toString(),
      eventDate: json['eventDate']?.toString(),
      orderLocation: json['orderLocation']?.toString(),
    );
  }
}
