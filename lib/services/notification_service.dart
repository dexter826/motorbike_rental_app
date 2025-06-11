import 'package:bike_rental_app/services/rental_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:easy_localization/easy_localization.dart';
import '../models/notification.dart';
import '../models/rental.dart';
import '../services/user_service.dart';
import '../services/email_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Collection references
  CollectionReference get _notificationsRef =>
      _firestore.collection('notifications');
  CollectionReference get _rentalsRef => _firestore.collection('rentals');

  // Khởi tạo service
  Future<void> init() async {
    // Initialize timezone
    tz_data.initializeTimeZones();

    try {
      // Yêu cầu quyền cho local notifications
      await _requestLocalPermissions();

      // Khởi tạo local notifications
      await _initializeLocalNotifications();

      // Kiểm tra các đơn thuê sắp đến hạn và đã quá hạn
      await checkDueRentals();
      await checkExpiredRentals();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  // Yêu cầu quyền cho local notifications
  Future<void> _requestLocalPermissions() async {
    try {
      // Thêm quyền trên Android 13+
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // Yêu cầu quyền trên iOS
      print('Local notification permissions requested');
    } catch (e) {
      print('Error requesting local notification permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Notification clicked: ${response.payload}');
        },
      );
    } catch (e) {
      print('Error initializing local notifications: $e');
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'rental_notifications',
            'notification.channel_name'.tr(),
            channelDescription: 'notification.channel_description'.tr(),
            importance: Importance.high,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Kiểm tra và thông báo các đơn thuê sắp đến hạn
  // Chỉ gửi thông báo cho đơn thuê ≥ 2 ngày và sẽ đến hạn vào ngày mai
  Future<void> checkDueRentals() async {
    try {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final dayAfterTomorrow = DateTime(now.year, now.month, now.day + 2);

      // Lấy các đơn thuê sẽ đến hạn vào ngày mai
      final QuerySnapshot snapshot =
          await _rentalsRef
              .where(
                'endTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(tomorrow),
              )
              .where(
                'endTime',
                isLessThan: Timestamp.fromDate(dayAfterTomorrow),
              )
              .where('status', isEqualTo: RentalStatusConstants.ongoing)
              .get();

      // Import các service cần thiết
      final userService = UserService();
      final emailService = EmailService();

      for (final doc in snapshot.docs) {
        final rental = Rental.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        // Kiểm tra thời gian thuê ≥ 2 ngày
        final rentalDuration = rental.endTime.difference(rental.startTime);
        if (rentalDuration.inDays < 2) {
          continue; // Bỏ qua đơn thuê dưới 2 ngày
        }

        final existingNotifications =
            await _notificationsRef
                .where('rentalId', isEqualTo: rental.id)
                .where('type', isEqualTo: 'rental_due')
                .get();

        if (existingNotifications.docs.isEmpty) {
          // Ở đây, userId không còn ý nghĩa lọc theo user,
          // nhưng ta vẫn giữ lại để biết ai đã thuê (nếu cần).
          final title = 'notification.rental_due_title'.tr();
          final body = 'notification.rental_due_body'.tr(args: [rental.id]);

          await createNotification(
            userId: rental.userId,
            rentalId: rental.id,
            title: title,
            body: body,
            type: 'rental_due',
          );

          await _showLocalNotification(title, body, payload: rental.id);

          // Gửi email thông báo đơn thuê sắp hết hạn
          try {
            // Lấy thông tin người dùng
            final user = await userService.getUserById(rental.userId);
            if (user != null) {
              // Gửi email
              await emailService.sendRentalDueNotification(
                rental: rental,
                user: user,
              );
            }
          } catch (emailError) {
            print('Error sending due rental email: $emailError');
            // Không throw lỗi ở đây để không ảnh hưởng đến luồng chính
          }
        }
      }
    } catch (e) {
      print('Error checking due rentals: $e');
    }
  }

  // Kiểm tra và thông báo các đơn thuê đã quá hạn
  Future<void> checkExpiredRentals() async {
    try {
      final now = DateTime.now();
      final userService = UserService();
      final emailService = EmailService();
      final rentalService = RentalService();

      // Sử dụng phương thức từ RentalService để cập nhật trạng thái đơn thuê quá hạn
      final expiredRentals = await rentalService.checkAndUpdateExpiredRentals();

      // Xử lý thông báo cho từng đơn thuê quá hạn
      for (final rental in expiredRentals) {
        // Tính thời gian quá hạn
        final difference = now.difference(rental.endTime);
        String overdueText;

        if (difference.inDays < 1) {
          // Nếu chưa đủ 1 ngày, hiển thị theo giờ
          final hoursOverdue = difference.inHours;
          overdueText = '$hoursOverdue ${'notification.hours'.tr()}';
        } else {
          // Nếu từ 1 ngày trở lên, hiển thị theo ngày
          final daysOverdue = difference.inDays;
          overdueText = '$daysOverdue ${'notification.days'.tr()}';
        }

        // Kiểm tra xem đã có thông báo quá hạn ban đầu cho đơn thuê này chưa
        final existingNotifications =
            await _notificationsRef
                .where('rentalId', isEqualTo: rental.id)
                .where('type', isEqualTo: 'rental_expired')
                .get();

        // Kiểm tra xem đã có thông báo nhắc nhở hàng ngày cho đơn thuê này trong ngày hôm nay chưa
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));

        final dailyReminders =
            await _notificationsRef
                .where('rentalId', isEqualTo: rental.id)
                .where('type', isEqualTo: 'rental_daily_reminder')
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(today),
                )
                .where('createdAt', isLessThan: Timestamp.fromDate(tomorrow))
                .get();

        // Nếu chưa có thông báo ban đầu, tạo thông báo mới
        if (existingNotifications.docs.isEmpty) {
          final title = 'notification.rental_expired_title'.tr();
          final body = 'notification.rental_expired_body'.tr(
            args: [rental.id, overdueText],
          );

          await createNotification(
            userId: rental.userId,
            rentalId: rental.id,
            title: title,
            body: body,
            type: 'rental_expired',
          );

          await _showLocalNotification(title, body, payload: rental.id);

          // Gửi email thông báo đơn thuê đã quá hạn
          try {
            // Lấy thông tin người dùng
            final user = await userService.getUserById(rental.userId);
            if (user != null) {
              // Gửi email
              await emailService.sendRentalExpiredNotification(
                rental: rental,
                user: user,
              );
            }
          } catch (emailError) {
            print('Error sending expired rental email: $emailError');
            // Không throw lỗi ở đây để không ảnh hưởng đến luồng chính
          }
        }
        // Nếu đã có thông báo ban đầu nhưng chưa có thông báo nhắc nhở hàng ngày, tạo thông báo nhắc nhở
        else if (dailyReminders.docs.isEmpty &&
            existingNotifications.docs.isNotEmpty) {
          // Tạo thông báo nhắc nhở hàng ngày
          final title = 'notification.rental_daily_reminder_title'.tr();
          final body = 'notification.rental_daily_reminder_body'.tr(
            args: [rental.id, overdueText],
          );

          await createNotification(
            userId: rental.userId,
            rentalId: rental.id,
            title: title,
            body: body,
            type: 'rental_daily_reminder',
          );

          await _showLocalNotification(title, body, payload: rental.id);

          // Gửi email nhắc nhở hàng ngày
          try {
            // Lấy thông tin người dùng
            final user = await userService.getUserById(rental.userId);
            if (user != null) {
              // Gửi email
              await emailService.sendRentalExpiredNotification(
                rental: rental,
                user: user,
              );
            }
          } catch (emailError) {
            print('Error sending daily reminder email: $emailError');
          }
        }
      }
    } catch (e) {
      print('Error checking expired rentals: $e');
    }
  }

  /// Tạo thông báo mới trên Firestore
  Future<BikeNotification> createNotification({
    required String userId, // Giữ lại để biết ai đã thuê
    required String rentalId,
    required String title,
    required String body,
    required String type,
  }) async {
    final data = {
      'userId': userId,
      'rentalId': rentalId,
      'title': title,
      'body': body,
      'createdAt': Timestamp.now(),
      'isRead': false,
      'type': type,
    };

    final docRef = await _notificationsRef.add(data);
    return BikeNotification.fromMap(docRef.id, data);
  }

  /// Lấy tất cả thông báo (dành cho Admin)
  Stream<List<BikeNotification>> getAllNotifications() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BikeNotification.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'isRead': true});
  }

  /// Tạo thông báo thanh toán thành công
  Future<void> showPaymentSuccessNotification({
    required String paymentId,
    required String rentalId,
    required double amount,
    required String transactionId,
  }) async {
    try {
      final title = 'notification.payment_success_title'.tr();
      final body = 'notification.payment_success_body'.tr(
        args: [_formatCurrency(amount), rentalId.substring(0, 8)],
      );

      // Tạo thông báo trong Firestore
      await createNotification(
        userId: 'system', // System notification
        rentalId: rentalId,
        title: title,
        body: body,
        type: 'payment_success',
      );

      // Hiển thị local notification
      await _showLocalNotification(
        title,
        body,
        payload: 'payment_success:$paymentId:$rentalId',
      );
    } catch (e) {
      print('Error showing payment success notification: $e');
    }
  }

  /// Format currency helper
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  /// Simulate external payment success (for demo)
  static final Map<String, Map<String, dynamic>> _pendingPayments = {};

  /// Register a pending payment for notification
  static void registerPendingPayment({
    required String paymentId,
    required String rentalId,
    required double amount,
  }) {
    _pendingPayments[paymentId] = {
      'rentalId': rentalId,
      'amount': amount,
      'timestamp': DateTime.now(),
    };
  }

  /// Trigger payment success notification (called from website or test)
  Future<void> triggerPaymentSuccess(
    String paymentId,
    String transactionId,
  ) async {
    final paymentData = _pendingPayments[paymentId];
    if (paymentData != null) {
      await showPaymentSuccessNotification(
        paymentId: paymentId,
        rentalId: paymentData['rentalId'],
        amount: paymentData['amount'],
        transactionId: transactionId,
      );

      // Remove from pending after notification
      _pendingPayments.remove(paymentId);
    }
  }

  /// Đánh dấu **tất cả** thông báo là đã đọc (cho Admin)
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final snapshot =
        await _notificationsRef.where('isRead', isEqualTo: false).get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Xoá một thông báo
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
