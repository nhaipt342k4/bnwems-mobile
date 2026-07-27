# API GAPS — BNWEMS Staff

Tài liệu rà soát các API cần thiết đối chiếu giữa Frontend Web và Backend API (`sep490-backend-api`).

## Summary

Tất cả các tính năng trên Web đã được đối chiếu 100% với Backend API contract (`sep490-backend-api`). Không có API bị thiếu hoặc bị mock thiếu trên backend.

| Chức năng | Màn hình Web | API cần thiết | API thực tế tìm thấy | Vấn đề | Ảnh hưởng tới Flutter |
| --------- | ------------ | ------------- | -------------------- | ------ | --------------------- |
| Đăng nhập & Đổi mật khẩu | `/auth/login`, Profile | `POST /auth/login`, `GET /auth/profile`, `PUT /auth/change-password` | `POST /api/v1/auth/login`, `GET /api/v1/auth/profile`, `PUT /api/v1/auth/change-password` | Không có | Hoạt động 100% |
| Danh sách & Chi tiết Kế hoạch | `/staff/dashboard`, `/staff/tasks`, `/staff/tasks/[id]` | `GET /schedule-plans`, `GET /schedule-plans/:id` | `GET /api/v1/schedule-plans`, `GET /api/v1/schedule-plans/:id` | Không có | Hoạt động 100% |
| Check-in & Check-out | Task Detail / Attendance Tab | `POST /schedule-plans/:id/assignees/:userId/check-in`, `POST /schedule-plans/:id/assignees/:userId/check-out` | `POST /api/v1/schedule-plans/:id/assignees/:userId/check-in`, `POST /api/v1/schedule-plans/:id/assignees/:userId/check-out` | Bắt buộc đính kèm evidenceId từ upload | Hoạt động 100% |
| Xác nhận kế hoạch & Upload ảnh tiến độ | Task Detail / Notifications | `PATCH /schedule-plans/:id/status`, `PATCH /schedule-plans/:id/evidence` | `PATCH /api/v1/schedule-plans/:id/status`, `PATCH /api/v1/schedule-plans/:id/evidence` | Không có | Hoạt động 100% |
| Báo cáo khảo sát (`SURVEY`) | Task Detail (`SURVEY`) | `POST /survey-reports`, `GET /survey-reports?planId=` | `POST /api/v1/survey-reports`, `GET /api/v1/survey-reports` | Không có | Hoạt động 100% |
| Đặt cọc hiện trường (`SURVEY`) | Task Detail (`SURVEY`) | `POST /orders/:id/deposits`, `GET /orders/:id/deposits` | `POST /api/v1/deposits`, `GET /api/v1/deposits` | Không có | Hoạt động 100% |
| Picklist thiết bị kho | Task Detail | `GET /inventory/picklist/:orderId` | `GET /api/v1/inventory/picklist/:orderId` | Không có | Hoạt động 100% |
| Nhập/Xuất kho hiện trường | Task Detail | `POST /schedule-plans/:id/warehouse-movement` | `POST /api/v1/schedule-plans/:id/warehouse-movement` | Không có | Hoạt động 100% |
| Giao dịch thiết bị NCC (`SETUP`) | Task Detail (`SETUP`) | `GET /supplier-transactions`, `PATCH /supplier-transactions/:id/items/:itemId` | `GET /api/v1/supplier-transactions`, `PATCH /api/v1/supplier-transactions/:id/items/:itemId` | Không have | Hoạt động 100% |
| Báo cáo thu hồi (`COLLECT`) | Task Detail (`COLLECT`) | `POST /mobile/orders/:id/collected-reports`, `GET /inventory/collected-equipment-reports` | `POST /api/v1/mobile/orders/:id/collected-reports`, `GET /api/v1/inventory/collected-equipment-reports` | Không có | Hoạt động 100% |
| Quyết toán (`COLLECT`) | Task Detail (`COLLECT`) | `POST /orders/:id/settlement`, `GET /orders/:id/settlement`, `PUT /settlements/:id/mark-paid` | `POST /api/v1/settlements`, `GET /api/v1/settlements`, `PUT /api/v1/settlements/:id/mark-paid` | Không có | Hoạt động 100% |
| Upload & Lấy chứng từ | Mọi màn hình upload | `POST /evidence/upload`, `GET /evidence/:id` | `POST /api/v1/evidence/upload`, `GET /api/v1/evidence/:id` | `FormData` multipart/form-data | Hoạt động 100% |
| Thông báo | Notifications | `GET /notifications`, `PATCH /notifications/:id/read`, `POST /notifications/device-token` | `GET /api/v1/notifications`, `PATCH /api/v1/notifications/:id/read`, `POST /api/v1/notifications/device-token` | Không có | Hoạt động 100% |
