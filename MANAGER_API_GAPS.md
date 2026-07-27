# MANAGER API GAPS — BNWEMS Manager

Tài liệu ghi nhận các lưu ý về API contract và tổng hợp dữ liệu trên Frontend giữa Web Manager và Backend.

---

## Bảng theo dõi API & Contract

| STT | Chức năng | Màn hình Web | API Web đang gọi | API Backend thực tế | Vấn đề | Ảnh hưởng tới Flutter | Giải pháp đã triển khai |
| --- | --------- | ------------ | ---------------- | ------------------- | ------ | --------------------- | ----------------------- |
| 1 | Tổng hợp Chờ xử lý | `/manager/pending` | Composite `pendingApiService.getPendingSummary` | Từng API riêng lẻ (`GET /orders`, `GET /orders/:id/deposits`, `GET /orders/:id/settlement`, `GET /change-requests`, `GET /inventory/return-reports`) | Backend chưa có endpoint gộp duy nhất cho toàn bộ danh sách chờ của Manager trên mọi đơn hàng | Cần gọi nhiều request và gộp dữ liệu ở phía Client | Triển khai `ManagerPendingService.getPendingSummary` tổng hợp async dữ liệu tương tự Web |
| 2 | Danh sách hoàn kho | `/manager/returns` | `inventoryApiService.getReturnReports` | `GET /inventory/return-reports` | Endpoint trả về cả phiếu `INTERNAL` và `SUPPLIER` | Cần filter phía FE để chỉ lấy phiếu nội bộ `INTERNAL` | Thêm `.where((r) => r.reportType == 'INTERNAL')` trong service / provider Flutter |
| 3 | Tính finalAmount Quyết toán | `/manager/settlements/[orderId]` | Client-side formula & `POST /orders/:orderId/settlement` | `POST /orders/:orderId/settlement` | Server tự tính `finalAmount` khi lưu, nhưng FE Web tính nhẩm live trên UI trước khi submit | Cần đồng bộ công thức tính nhẩm live trên Flutter | Áp dụng công thức `totalAmount + additionalFee + compensation - depositCollected - discount` trên UI |
| 4 | Cổng thanh toán VietQR | `/manager/deposits`, `/manager/settlements` | Static VietQR URL generator (`https://img.vietqr.io/image/...`) | N/A (Tạo QR trên Client theo chuẩn VietQR) | Không cần API backend cho QR image | Cần render QR image mượt mà trên mobile | Xây dựng `VietQrWidget` render ảnh VietQR kèm tính năng tải QR & copy nội dung chuyển khoản |
