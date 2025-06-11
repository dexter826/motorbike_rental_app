# Ứng dụng Quản lý Cho thuê Xe máy

Ứng dụng quản lý cho thuê xe máy dành cho nhân viên, phát triển bằng Flutter và Firebase.

![Mock GUI](assets/images/MockGUI.png)

## Thông tin đồ án

**Môn học:** Lập trình di động
**Trường:** Đại học Công Thương TP.HCM

**Nhóm phát triển:**

- Trần Công Minh - 2001222641 (Nhóm trưởng)
- Lê Đức Trung - 2001225676
- Nguyễn Chí Tài - 2001224227
- Tạ Nguyên Vũ - 2001225916

## Mô tả

Ứng dụng di động dành cho nhân viên quản lý việc cho thuê xe máy. Đặc điểm chính: khách hàng thanh toán khi trả xe (không trả trước), bao gồm phí trễ hạn và bồi thường nếu có.

## Tính năng chính

### Quản lý xe máy

- Thêm/sửa/xóa thông tin xe máy và thương hiệu
- Theo dõi trạng thái xe (Available/Rented/Maintenance)
- Upload hình ảnh xe
- Quét QR code để xem chi tiết

### Quản lý khách hàng

- Quản lý thông tin khách hàng (CCCD, địa chỉ, ngày sinh)
- Tìm kiếm và xem lịch sử thuê xe

### Quản lý đơn thuê

- Tạo đơn thuê mới (chọn xe, khách hàng, thời gian)
- Trạng thái: Ongoing → Completed/Expired
- Quét QR xác nhận pickup/return
- Theo dõi vị trí xe trên Google Maps

### Thanh toán (đặc biệt)

- **Thanh toán khi trả xe** (không trả trước)
- Tính phí: thuê cơ bản + phí trễ + bồi thường (nếu có)
- Phương thức: Tiền mặt, VNPay QR Code
- Chữ ký khách hàng trên màn hình
- Tạo hóa đơn PDF tự động

### Thông báo & Báo cáo

- Push notification và email tự động
- Dashboard thống kê doanh thu ngày
- Báo cáo PDF với biểu đồ
- Quản lý nhân viên (Admin)

## Workflow

**Thuê xe:** Tạo đơn → Xác nhận pickup → Ongoing
**Trả xe:** Kiểm tra xe → Tính phí → Thanh toán → Completed
**Thông báo:** Auto email/notification cho đơn sắp hết hạn

## Công nghệ

**Frontend:** Flutter 3.7.2, Provider (state management)
**Backend:** Firebase (Auth, Firestore, Storage)
**Tính năng:** Google Maps, QR Scanner, PDF Reports, Email notifications
**Thanh toán:** VNPay QR Code integration

## Cấu trúc

```
lib/
├── models/     # Data models (bike, rental, payment, user, staff)
├── services/   # Business logic (auth, bike, rental, payment, email)
├── screens/    # UI screens (auth, home, bike, rental, payment, admin)
├── widgets/    # Reusable components
└── config/     # Routes, theme
```

## Database (Firestore)

**Collections:**

- `bikes` - Thông tin xe máy (name, brand, price, status, imageUrl)
- `rentals` - Đơn thuê (bikeId, userId, startTime, endTime, status)
- `payments` - Thanh toán (rentalId, amount, method, lateFee, damageCompensation)
- `users` - Khách hàng (name, email, phone, idCard, address)
- `staff` - Nhân viên (email, name, role, isActive)

## Yêu cầu

- Flutter SDK 3.7.2+
- Firebase project (Auth, Firestore)
- Google Maps API key
- ImgBB API key (upload ảnh)
- Gmail SMTP (gửi email)

## Cài đặt

### 1. Clone repository

```bash
git clone https://github.com/your-username/motorbike_rental_app.git
cd motorbike_rental_app
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Firebase

- Tạo Firebase project mới
- Kích hoạt Authentication và Firestore
- Sao chép `lib/firebase_options.dart.example` thành `lib/firebase_options.dart` và cập nhật thông tin
- Sao chép `android/app/google-services.json.example` thành `android/app/google-services.json` và cập nhật
- Sao chép `ios/Runner/GoogleService-Info.plist.example` thành `ios/Runner/GoogleService-Info.plist` và cập nhật

### 4. Cấu hình API keys

- Sao chép `.env.example` thành `.env` và điền thông tin:

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
IMGBB_API_KEY=your_imgbb_api_key
EMAIL_USERNAME=your_email@gmail.com
EMAIL_PASSWORD=your_app_password
```

- Sao chép `android/gradle.properties.example` thành `android/gradle.properties` và cập nhật Google Maps API key
- Sao chép `ios/Config.xcconfig.example` thành `ios/Config.xcconfig` và cập nhật (nếu build iOS)

### 5. Chạy app

```bash
flutter run
```

## Sử dụng

**Quy trình cơ bản:**

1. Đăng nhập → Quản lý xe máy → Quản lý khách hàng
2. Tạo đơn thuê → Xác nhận pickup → Xử lý trả xe & thanh toán

## Ghi chú

**Đặc điểm:** Thanh toán khi trả xe (không trả trước), tích hợp VNPay QR, thông báo email tự động

**Hạn chế:** VNPay dùng mock gateway, cần cấu hình SMTP thủ công

---

**Đồ án Lập trình di động - Đại học Công Thương TP.HCM**
