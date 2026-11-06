# My Order - Dart Practical Exam SET01

Website quản lý đơn hàng bám sát đề thi "Introduction to Dart Programming".

## Đã đáp ứng thang điểm

- **Create class Order (2 điểm):** `lib/order.dart` có thuộc tính, `fromJson()`, `toJson()` và kiểm tra dữ liệu.
- **Read JSON, save objects, display (5 điểm):** server đọc `data/order.json`, chuyển thành `List<Order>` và giao diện hiển thị dạng bảng.
- **Insert order (4 điểm):** form gọi API Dart; server kiểm tra dữ liệu và ghi đơn mới thật vào `data/order.json`.
- **Search order (3 điểm):** tìm gần đúng theo `ItemName`, không phân biệt hoa thường.
- **Good UI (1 điểm):** giao diện responsive, thống kê, trạng thái rỗng/loading và thông báo kết quả.

## Cách chạy nhanh trên Windows

1. Cài Dart SDK hoặc Flutter (Flutter đã bao gồm Dart).
2. Nhấp đúp `run.bat`.
3. Mở `http://localhost:8080` trong trình duyệt.

Hoặc chạy thủ công trong thư mục dự án:

```powershell
dart compile js web/main.dart -O2 -o web/main.dart.js
dart run bin/server.dart
```

Đổi cổng nếu 8080 đang được sử dụng:

```powershell
dart run bin/server.dart 9000
```

## Cấu trúc chính

```text
bin/server.dart      Dart HTTP server và REST API
lib/order.dart       Lớp Order dùng chung cho server và website
web/main.dart        Logic giao diện viết bằng Dart
web/index.html       Bố cục website
web/styles.css       Giao diện responsive
data/order.json      Dữ liệu đơn hàng được đọc và cập nhật
```

## API dùng trong bài

- `GET /api/orders`: lấy toàn bộ đơn hàng.
- `GET /api/orders?search=iphone`: tìm theo `ItemName`.
- `POST /api/orders`: thêm đơn mới và ghi vào `order.json`.

## Gợi ý trình bày khi bảo vệ

1. Mở `lib/order.dart`, giải thích `fromJson()` và `toJson()`.
2. Mở `bin/server.dart`, chỉ phần `readOrders()`, `insertOrder()` và `writeOrders()`.
3. Chạy web, thêm một item code mới và mở `data/order.json` để chứng minh file đã được cập nhật.
4. Gõ một phần tên sản phẩm vào ô tìm kiếm để chứng minh tìm kiếm không phân biệt hoa thường.
