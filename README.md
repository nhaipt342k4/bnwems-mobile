# 📱 BNWEMS Mobile Application (Staff & Manager)

Ứng dụng di động đa vai trò dành cho Hệ thống Quản lý Thiết bị & Sự kiện **BNWEMS**, được phát triển trên nền tảng **Flutter**.

---

## 🚀 Tính năng nổi bật theo Vai trò

### 👔 1. Vai trò Quản lý (Manager)
* **Trang chủ Dashboard**:
  * Thống kê KPI thời gian thực: Đơn hàng sắp diễn ra, Công việc hôm nay, Đang thực hiện, Mục chờ xử lý.
  * Lịch trình làm việc trong ngày và shortcut xử lý nhanh.
* **Quản lý Đơn hàng (Order Management)**:
  * Tra cứu, tìm kiếm và lọc đơn hàng theo nhiều tiêu chí (Mới, Đã xác nhận, Đang thực hiện, Hoàn thành, Đã hủy, Trạng thái thanh toán).
  * Chi tiết đơn hàng, thông tin khách hàng, xem danh sách lịch trình công việc liên quan.
  * Chức năng **Hủy đơn hàng** kèm nhập lý do hủy.
* **Cổng thanh toán & VietQR (Deposit & Settlement)**:
  * **Đặt cọc**: Tạo yêu cầu cọc (gợi ý 30% giá trị đơn), đặt hạn thanh toán cọc và xác nhận đã thu cọc.
  * **Quyết toán**: Lập hồ sơ quyết toán cuối kỳ (tính thêm phụ phí, tiền đền bù hỏng/mất, giảm giá), tự động tính số tiền cần thu cuối và chuyển đơn hàng sang trạng thái *Hoàn thành*.
  * **Mã VietQR động**: Render mã QR chuyển khoản chính xác theo ngân hàng, tích hợp nút **Tải hình ảnh QR** (lưu trực tiếp vào Thư viện ảnh/Photos của điện thoại) và nút **Sao chép nội dung**.
* **Phê duyệt Đổi thiết bị (Change Requests)**:
  * Xét duyệt các yêu cầu thêm/bớt/thay thế thiết bị phát sinh từ kỹ thuật viên tại hiện trường.
  * Chi tiết số tiền ảnh hưởng đến hóa đơn thanh toán trước khi bấm *Duyệt* hoặc *Từ chối*.
* **Mục chờ xử lý (Pending Summary)**:
  * Gom cụm toàn bộ danh sách chờ xử lý: Phiếu hoàn kho, Đặt cọc chờ xác nhận, Quyết toán chờ xác nhận, Yêu cầu đổi thiết bị.
* **Lịch trình theo tuần (Schedule Calendar)**:
  * Xem lịch trình làm việc theo tuần, chấm tròn báo kế hoạch từng ngày, mốc thời gian và danh sách nhân sự được phân công.
* **Xác nhận Hoàn kho (Return Reports)**:
  * Kiểm tra các phiếu thu hồi thiết bị do kỹ thuật viên nộp.
  * Xem chi tiết từng loại thiết bị (Nguyên vẹn, Hỏng, Mất), đối chiếu tồn kho trước/sau hoàn và bấm **Xác nhận hoàn kho**.

---

### 👷 2. Vai trò Trưởng nhóm & Kỹ thuật viên (Lead & Technical Staff)
* **Quản lý Công việc (Task List)**: Danh sách công việc hiện trường (Khảo sát, Lắp đặt, Thu hồi).
* **Chi tiết Công việc (Task Detail)**: Check-in địa điểm sự kiện, xem danh sách thiết bị, nhập báo cáo khảo sát/lắp đặt/thu hồi.
* **Gửi Yêu cầu Đổi thiết bị**: Gửi đề xuất đổi thiết bị hiện trường cho Manager phê duyệt.
* **Thông báo Push (Notifications)**: Nhận thông báo Firebase thời gian thực khi có công việc mới hoặc cập nhật trạng thái.

---

## 🛠️ Công nghệ sử dụng

* **Core Framework**: [Flutter SDK](https://flutter.dev) (Dart)
* **State Management**: [Provider](https://pub.dev/packages/provider) (`MultiProvider`, `ChangeNotifier`)
* **Navigation & Routing**: [GoRouter](https://pub.dev/packages/go_router) với Role-based Authentication Guard
* **HTTP & Network**: `Dio`, `ApiClient` tự động giải bọc Response Envelope `{ success, data }`
* **Lưu trữ hình ảnh**: [Gal](https://pub.dev/packages/gal) (lưu trực tiếp ảnh QR vào Thư viện ảnh Photos trên điện thoại)
* **Notification**: `firebase_messaging`, `flutter_local_notifications`
* **Icons & UI Design**: `lucide_icons`, thiết kế giao diện Tiếng Việt 100% chuẩn hóa Typography.

---

## 📁 Cấu trúc Thư mục Dự án

```text
lib/
├── core/                       # Thành phần dùng chung toàn hệ thống
│   ├── network/                # ApiClient, HTTP Interceptors
│   ├── services/               # FCM Service, Notification Services
│   ├── theme/                  # AppColors, AppTheme
│   ├── utils/                  # Formatters (Tiền tệ, Ngày tháng, Dịch Tiếng Việt)
│   └── widgets/                # AppHeader, Loading, Error Widgets
│
├── features/                   # Tính năng theo Domain/Module
│   ├── authentication/         # Đăng nhập, AuthProvider, AuthUser
│   ├── manager/                # Module dành riêng cho vai trò Manager
│   │   ├── data/
│   │   │   ├── models/         # Order, Deposit, Settlement, ChangeRequest, ReturnReport...
│   │   │   └── services/       # Manager Order/Deposit/Settlement/Inventory API Services
│   │   └── presentation/
│   │       ├── pages/          # 11 Màn hình Flutter Manager
│   │       ├── providers/      # 10 Providers quản lý state
│   │       └── widgets/        # VietQrWidget, ManagerBottomNav, ManagerLayout
│   ├── tasks/                  # Task hiện trường dành cho Staff/Lead
│   ├── schedule/               # Lịch trình công việc
│   ├── notifications/          # Thông báo ứng dụng
│   ├── attendance/             # Điểm danh & Lịch sử
│   └── profile/                # Trang cá nhân & Đăng xuất
│
├── routes/                     # Cấu hình đường dẫn điều hướng app_router.dart
└── main.dart                   # Điểm khởi chạy ứng dụng & đệm Providers
```

---

## 💻 Hướng dẫn Cài đặt & Chạy ứng dụng

### 1. Yêu cầu môi trường
* **Flutter SDK**: `>=3.11.0`
* **Dart SDK**: `>=3.0.0`
* **Android Studio** / **VS Code** có cài Extension Flutter & Dart.

### 2. Các bước chạy dự án

1. **Di chuyển vào thư mục ứng dụng**:
   ```bash
   cd flutter_app
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Chạy ứng dụng trên Emulator hoặc Thiết bị thật**:
   ```bash
   flutter run
   ```

---

