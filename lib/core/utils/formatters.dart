import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  /// Định dạng tiền tệ VNĐ: 1,000,000 đ
  static String formatCurrency(num amount) {
    return _currencyFormat.format(amount);
  }

  /// Lấy thời gian hiện tại theo chuẩn Múi giờ Việt Nam (GMT+7)
  static DateTime nowInVietnam() {
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  /// Chuẩn hóa và chuyển đổi chuỗi ngày giờ về chuẩn Múi giờ Việt Nam (GMT+7)
  static DateTime parseVietnamDateTime(String? isoString) {
    if (isoString == null || isoString.trim().isEmpty) return nowInVietnam();
    final cleanStr = isoString.trim();
    if (!cleanStr.contains('Z') && !cleanStr.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(cleanStr)) {
      return DateTime.parse(cleanStr);
    }
    final dt = DateTime.parse(cleanStr);
    final utc = dt.toUtc();
    return utc.add(const Duration(hours: 7));
  }

  /// Định dạng ngày: DD/MM/YYYY (ví dụ 26/07/2026)
  static String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dateTime = parseVietnamDateTime(isoString);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  /// Định dạng ngày chi tiết: Thứ X, DD/MM/YYYY
  static String formatFullDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dateTime = parseVietnamDateTime(isoString);
      final dayNames = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
      final dayName = dayNames[dateTime.weekday % 7];
      return '$dayName, ${DateFormat('dd/MM/yyyy').format(dateTime)}';
    } catch (_) {
      return isoString;
    }
  }

  /// Định dạng giờ: HH:mm (ví dụ 08:30)
  static String formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dateTime = parseVietnamDateTime(isoString);
      return DateFormat('HH:mm').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  /// Định dạng ngày giờ đầy đủ: HH:mm - DD/MM/YYYY
  static String formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dateTime = parseVietnamDateTime(isoString);
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (_) {
      return isoString;
    }
  }

  /// Chuỗi ngày tháng ISO YYYY-MM-DD
  static String toIsoDateOnly(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Lấy chữ cái đầu của Họ tên làm Avatar
  static String getInitial(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return '?';
    return fullName.trim().substring(0, 1).toUpperCase();
  }

  /// Dịch trạng thái công việc / đơn hàng sang Tiếng Việt
  static String formatStatus(String? status) {
    if (status == null || status.isEmpty) return '--';
    switch (status.toUpperCase()) {
      case 'NEW':
      case 'CREATE':
      case 'CREATED':
        return 'Đơn mới';
      case 'SUBMITTED':
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
      case 'ACCEPTED':
        return 'Đã xác nhận';
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return 'Đang thực hiện';
      case 'COMPLETED':
      case 'DONE':
      case 'FINISHED':
        return 'Hoàn thành';
      case 'CANCELLED':
      case 'CANCELED':
      case 'REJECTED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Dịch trạng thái thanh toán sang Tiếng Việt
  static String formatPaymentStatus(String? paymentStatus) {
    if (paymentStatus == null || paymentStatus.isEmpty) return '--';
    switch (paymentStatus.toUpperCase()) {
      case 'UNPAID':
        return 'Chưa thanh toán';
      case 'DEPOSITED':
        return 'Đã đặt cọc';
      case 'PAID':
        return 'Đã thanh toán';
      case 'REFUNDED':
        return 'Đã hoàn tiền';
      case 'PARTIALLY_REFUNDED':
        return 'Hoàn tiền một phần';
      case 'SUBMITTED':
      case 'PENDING':
        return 'Chờ xác nhận';
      default:
        return paymentStatus;
    }
  }

  /// Dịch trạng thái yêu cầu đổi thiết bị sang Tiếng Việt
  static String formatChangeRequestStatus(String? status) {
    if (status == null || status.isEmpty) return '--';
    switch (status.toLowerCase()) {
      case 'pending':
      case 'submitted':
        return 'Chờ duyệt';
      case 'approved':
      case 'confirmed':
        return 'Đã duyệt';
      case 'rejected':
      case 'cancelled':
        return 'Từ chối';
      default:
        return status;
    }
  }

  /// Dịch loại yêu cầu đổi thiết bị sang Tiếng Việt
  static String formatChangeType(String? type) {
    if (type == null || type.isEmpty) return '--';
    switch (type.toLowerCase()) {
      case 'equipment_change':
      case 'change':
        return 'Đổi thiết bị';
      case 'add':
        return 'Thêm thiết bị';
      case 'remove':
        return 'Bớt thiết bị';
      default:
        return type;
    }
  }

  /// Dịch trạng thái phiếu hoàn kho sang Tiếng Việt
  static String formatReturnStatus(String? status) {
    if (status == null || status.isEmpty) return '--';
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'PENDING':
      case 'NEW':
        return 'Chờ hoàn kho';
      case 'CONFIRMED':
      case 'APPROVED':
      case 'COMPLETED':
        return 'Đã hoàn kho';
      case 'REJECTED':
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  /// Dịch mã loại công việc sang Tiếng Việt
  static String formatTaskCode(String? code) {
    switch (code) {
      case 'SURVEY':
        return 'Khảo sát hiện trường';
      case 'SETUP':
        return 'Lắp đặt thiết bị';
      case 'COLLECT':
        return 'Thu hồi thiết bị';
      default:
        return code ?? '--';
    }
  }

  /// Dịch vai trò nhân sự sang Tiếng Việt
  static String formatRole(String? role) {
    if (role == null || role.isEmpty) return 'Quản lý';
    switch (role.toUpperCase()) {
      case 'MANAGER':
      case 'ADMIN':
        return 'Quản lý';
      case 'LEAD':
      case 'LEADER':
      case 'TRUONG_NHOM':
        return 'Trưởng nhóm';
      case 'TECHNICAL':
      case 'TECHNICIAN':
      case 'KY_THUAT_VIEN':
        return 'Kỹ thuật viên';
      default:
        return role;
    }
  }
}
