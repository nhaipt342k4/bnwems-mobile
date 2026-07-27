# WEB TO MOBILE MAPPING — BNWEMS Staff

Tài liệu đối chiếu 100% màn hình, luồng điều hướng, component và tính năng từ Web sang Flutter Mobile.

---

## 1. Bảng đối chiếu Màn hình (Screen Mapping)

| STT | Role | Web route | Màn hình/chức năng Web | Component liên quan | API hoặc nguồn dữ liệu | Màn hình Flutter tương ứng | Trạng thái |
| --- | ---- | --------- | ---------------------- | ------------------- | ---------------------- | -------------------------- | ---------- |
| 1 | Tất cả | `/auth/login` | Trang đăng nhập (Username, Password, validation, thông báo lỗi) | `LoginPage`, `Button`, `AuthContext` | `POST /auth/login` | `lib/features/authentication/presentation/pages/login_screen.dart` | Đang thực hiện |
| 2 | LEAD, TECH | `/staff/dashboard` | Trang chủ Staff (Header chào hỏi, QuickAttendanceButton với GPS + ảnh, 2 Thẻ thống kê TaskStatisticGrid, Kế hoạch hôm nay) | `StaffDashboardPage`, `QuickAttendanceButton`, `TaskStatisticGrid`, `CurrentTaskCard` | `GET /schedule-plans`, `GET /auth/profile` | `lib/features/dashboard/presentation/pages/dashboard_screen.dart` | Đang thực hiện |
| 3 | LEAD, TECH | `/staff/tasks` | Danh sách nhiệm vụ (Search bar, 5 Status filters: ALL/PENDING/CONFIRMED/IN_PROGRESS/COMPLETED/CANCELLED, UpcomingEventAlert, Card list) | `StaffTasksPage`, `CurrentTaskCard`, `UpcomingEventAlert`, `Search` | `GET /schedule-plans` | `lib/features/tasks/presentation/pages/task_list_screen.dart` | Đang thực hiện |
| 4 | LEAD, TECH | `/staff/tasks/[id]` (Tab Overview) | Chi tiết kế hoạch - Tab Tổng quan (Header, Nút Xác nhận PENDING cho Lead, Check-in/out, Upload ảnh tiến độ SETUP/COLLECT, SurveyReportSection, FieldPaymentSection, HandoverSection, WarehouseMovementSection, EquipmentTable, SupplierTransactionSection, CollectedEquipmentReportSection, SettlementSection) | `StaffTaskDetailPage`, `SurveyReportSection`, `FieldPaymentSection`, `HandoverSection`, `WarehouseMovementSection`, `EquipmentTable`, `SupplierTransactionSection`, `CollectedEquipmentReportSection`, `SettlementSection` | `GET /schedule-plans/:id`, `PATCH /schedule-plans/:id/status`, `PATCH /schedule-plans/:id/evidence`, `GET /inventory/picklist/:id`, `GET /supplier-transactions?orderId=`, `GET /survey-reports?planId=`, `GET /orders/:id/deposits`, `GET /inventory/collected-equipment-reports?orderId=`, `GET /orders/:id/settlement` | `lib/features/tasks/presentation/pages/task_detail_screen.dart` (Tab Overview) | Đang thực hiện |
| 5 | LEAD, TECH | `/staff/tasks/[id]` (Tab Assignees) | Chi tiết kế hoạch - Tab Thành viên (Danh sách thành viên phân công, vai trò Lead/Tech, SĐT, thời gian check-in/out, ảnh check-in) | `StaffTaskDetailPage` | `GET /schedule-plans/:id` | `lib/features/tasks/presentation/pages/task_detail_screen.dart` (Tab Assignees) | Đang thực hiện |
| 6 | LEAD, TECH | `/staff/tasks/[id]` (Tab Attendance) | Chi tiết kế hoạch - Tab Chấm công cá nhân (Trạng thái điểm danh, nút Check-in GPS + ảnh, nút Check-out) | `StaffTaskDetailPage`, `CheckInModal` | `POST /schedule-plans/:id/assignees/:userId/check-in`, `POST /schedule-plans/:id/assignees/:userId/check-out`, `POST /evidence/upload` | `lib/features/tasks/presentation/pages/task_detail_screen.dart` (Tab Attendance) | Đang thực hiện |
| 7 | LEAD, TECH | `/staff/attendance` | Lịch trình chấm công (Timeline chấm công chỉ đọc theo kế hoạch, trạng thái, timestamp, ảnh check-in) | `StaffAttendancePage`, `Badge` | `GET /schedule-plans`, `GET /evidence/:id` | `lib/features/attendance/presentation/pages/attendance_history_screen.dart` | Đang thực hiện |
| 8 | LEAD, TECH | `/staff/schedule` | Lịch trình làm việc (Calendar tuần T2-CN, chọn ngày, chuyển tuần trước/sau, Hôm nay, timeline công việc theo ngày) | `StaffSchedulePage` | `GET /schedule-plans` | `lib/features/schedule/presentation/pages/schedule_calendar_screen.dart` | Đang thực hiện |
| 9 | LEAD, TECH | `/staff/profile` | Hồ sơ cá nhân (Avatar, Họ tên, RoleBadge, SĐT, Nút Đăng xuất, Link "Nhóm của tôi", Kế hoạch đảm nhận Trưởng nhóm) | `StaffProfilePage`, `RoleBadge`, `Button` | `GET /auth/profile`, `GET /schedule-plans` | `lib/features/profile/presentation/pages/profile_screen.dart` | Đang thực hiện |
| 10 | LEAD | `/staff/team` | Nhóm của tôi (Tổng quan số KTV, tiến độ kế hoạch, danh sách thành viên và các kế hoạch được giao) | `StaffTeamPage` | `GET /schedule-plans` | `lib/features/team/presentation/pages/team_roster_screen.dart` | Đang thực hiện |
| 11 | LEAD, TECH | `/staff/notifications` | Thông báo (Firebase prompt, danh sách thông báo read/unread, Kế hoạch cần xác nhận cho Lead) | `StaffNotificationsPage`, `Button` | `GET /notifications`, `PATCH /notifications/:id/read`, `PATCH /schedule-plans/:id/status` | `lib/features/notifications/presentation/pages/notifications_screen.dart` | Đang thực hiện |
| 12 | LEAD, TECH | `/staff/notifications/[id]` | Chi tiết thông báo (Xem nội dung, tự động đánh dấu đã đọc, điều hướng tới kế hoạch) | `notificationApiService.markAsRead` | `PATCH /notifications/:id/read` | `lib/features/notifications/presentation/pages/notification_detail_screen.dart` | Đang thực hiện |

---

## 2. Bảng đối chiếu Tính năng & Thao tác (Feature Actions Mapping)

| STT | Màn hình | Hành động trên Web | Điều kiện hiển thị | API/logic | Cách triển khai trên Flutter |
| --- | -------- | ------------------ | ------------------ | --------- | ---------------------------- |
| 1 | Login | Đăng nhập hệ thống | Luôn hiển thị khi chưa đăng nhập | `POST /auth/login` | Form nhập username/password, lưu JWT token & user vào `FlutterSecureStorage` |
| 2 | All | Đăng xuất | Trong màn Profile | Clears local storage/token | Invalidate auth state, xoá token, điều hướng tới `/login` |
| 3 | Dashboard / Detail | Điểm danh nhanh / Check-in | Chưa check-in, đúng ngày/giờ kế hoạch | Haversine GPS radius <= 200m, capture photo, `POST /evidence/upload`, `POST /schedule-plans/:id/assignees/:userId/check-in` | `geolocator` check GPS geofence + `image_picker` chụp/chọn ảnh bằng chứng |
| 4 | Task Detail | Check-out | Đã check-in, chưa check-out | `POST /schedule-plans/:id/assignees/:userId/check-out` | Button Check-out gọi API check-out |
| 5 | Task List / Notifications | Xác nhận kế hoạch | Status = `PENDING` & User role = `LEAD` | `PATCH /schedule-plans/:id/status` (status: `CONFIRMED`) | Nút "Xác nhận kế hoạch" trên Detail & Notifications screen |
| 6 | Task Detail | Upload ảnh tiến độ | Task code IN (`SETUP`, `COLLECT`) | `POST /evidence/upload`, `PATCH /schedule-plans/:id/evidence` | Pick image từ camera/gallery, upload evidence API, gán evidenceId |
| 7 | Task Detail (`SURVEY`) | Lập Báo cáo khảo sát hiện trường | Task code = `SURVEY` | `POST /evidence/upload`, `POST /survey-reports` | Form nhập diện tích, dài, rộng, lối vào, vướng mắc, đề xuất + chụp ảnh bằng chứng |
| 8 | Task Detail (`SURVEY`) | Ghi nhận tiền đặt cọc hiện trường | Task code = `SURVEY` | `POST /orders/:id/deposits` | Form nhập số tiền, phương thức (Tiền mặt / Chuyển khoản QR + ảnh bằng chứng transfer) |
| 9 | Task Detail | Ghi nhận Biên bản bàn giao | Form Handover | State store / API | Form nhập ghi chú bàn giao + ảnh minh chứng |
| 10 | Task Detail | Ghi nhận Xuất/Nhập kho | Pick-list items | `POST /schedule-plans/:id/warehouse-movement` | Chọn số lượng từng thiết bị xuất/nhập kho hiện trường |
| 11 | Task Detail (`SETUP`) | Nhận thiết bị từ Nhà cung cấp | Task code = `SETUP` | `PATCH /supplier-transactions/:id/items/:itemId` | Danh sách thiết bị thuê, cho phép cập nhật `receivedQuantity` từng dòng |
| 12 | Task Detail (`COLLECT`) | Báo cáo Thu hồi thiết bị (Checkpoint) | Task code = `COLLECT` | `POST /mobile/orders/:id/collected-reports` | Chia 2 nhóm: Kho công ty & Nhà cung cấp. Nhập SL tốt, hỏng, mất + tự tính tiền bồi thường |
| 13 | Task Detail (`COLLECT`) | Ghi nhận Quyết toán cuối kỳ | Task code = `COLLECT` | `POST /orders/:id/settlement`, `PUT /settlements/:id/mark-paid` | Hiển thị bảng tính finalAmount, QR chuyển khoản, upload ảnh chứng từ thanh toán |
| 14 | Tasks | Tìm kiếm & Lọc trạng thái | Màn hình Danh sách công việc | Client-side search + filter buttons (ALL, PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED) | `TextField` tìm kiếm live + horizontal `FilterChip` / Segmented buttons |
| 15 | Schedule | Calendar xem lịch theo tuần | Màn hình Lịch trình | Date calculation (Monday-Sunday week bar, prev/next week navigation, today button) | Custom Horizontal Week Selector + Timeline list view |
| 16 | Team | Xem tiến độ nhóm | User role = `LEAD` | Filter plans where user is lead, group assignees | Card list KTV & progress status badge |
| 17 | Notifications | Xem & đánh dấu đã đọc thông báo | Màn hình Thông báo | `GET /notifications`, `PATCH /notifications/:id/read` | List tile clickable, auto-mark read khi tap |
