import 'package:bike_rental_app/models/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../services/user_service.dart';
import '../services/rental_service.dart';
import '../services/email_service.dart';
import '../services/mock_payment_gateway.dart';

class PaymentService {
  final CollectionReference paymentsCollection = FirebaseFirestore.instance
      .collection('payments');
  final MockPaymentGateway _paymentGateway = MockPaymentGateway();

  // Lấy danh sách các thanh toán với các tùy chọn lọc
  Future<List<Payment>> getPayments({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    String? lastDocumentId,
    String? status,
    String? paymentMethod,
  }) async {
    try {
      Query query = paymentsCollection;

      // Áp dụng bộ lọc thời gian nếu có
      if (startDate != null) {
        query = query.where(
          'paymentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'paymentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Áp dụng bộ lọc trạng thái nếu có
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Áp dụng bộ lọc phương thức thanh toán nếu có
      if (paymentMethod != null) {
        query = query.where('paymentMethod', isEqualTo: paymentMethod);
      }

      // Sắp xếp theo thời gian thanh toán giảm dần (mới nhất trước)
      query = query.orderBy('paymentDate', descending: true);

      // Áp dụng phân trang nếu có
      if (lastDocumentId != null) {
        DocumentSnapshot lastDoc =
            await paymentsCollection.doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDoc);
      }

      // Giới hạn số lượng kết quả
      query = query.limit(limit);

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Payment.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting payments: $e');
      throw e;
    }
  }

  // Lấy tổng số thanh toán theo khoảng thời gian
  Future<int> getPaymentCount({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? paymentMethod,
  }) async {
    try {
      Query query = paymentsCollection;

      // Áp dụng bộ lọc thời gian nếu có
      if (startDate != null) {
        query = query.where(
          'paymentDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'paymentDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Áp dụng bộ lọc trạng thái nếu có
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Áp dụng bộ lọc phương thức thanh toán nếu có
      if (paymentMethod != null) {
        query = query.where('paymentMethod', isEqualTo: paymentMethod);
      }

      AggregateQuerySnapshot aggregateSnapshot = await query.count().get();
      return aggregateSnapshot.count ?? 0;
    } catch (e) {
      print('Error getting payment count: $e');
      throw e;
    }
  }

  // Lấy tổng doanh thu theo khoảng thời gian
  Future<Map<String, dynamic>> getRevenueStats({
    DateTime? startDate,
    DateTime? endDate,
    String? paymentMethod,
  }) async {
    try {
      // Lấy danh sách thanh toán trong khoảng thời gian
      // Lấy tất cả payments trước, sau đó lọc theo status (case insensitive)
      List<Payment> allPayments = await getPayments(
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
        limit: 1000, // Lấy nhiều hơn để tính toán chính xác
      );

      // Lọc chỉ lấy payments đã hoàn thành
      List<Payment> payments =
          allPayments
              .where(
                (payment) => payment.status == PaymentStatusConstants.completed,
              )
              .toList();

      // Tính tổng doanh thu
      double totalRevenue = payments.fold(
        0,
        (sum, payment) => sum + payment.amount,
      );

      // Tính tổng tiền đền bù
      double totalCompensation = payments.fold(
        0,
        (sum, payment) => sum + (payment.damageCompensation ?? 0),
      );

      // Tính tổng phí trễ hẹn
      double totalLateFee = payments.fold(
        0,
        (sum, payment) => sum + (payment.lateFee ?? 0),
      );

      // Tổng hợp theo phương thức thanh toán
      Map<String, int> methodCounts = {};
      for (var payment in payments) {
        if (!methodCounts.containsKey(payment.paymentMethod)) {
          methodCounts[payment.paymentMethod] = 0;
        }
        methodCounts[payment.paymentMethod] =
            methodCounts[payment.paymentMethod]! + 1;
      }

      // Tổng hợp doanh thu theo phương thức thanh toán
      Map<String, double> methodRevenues = {};
      for (var payment in payments) {
        if (!methodRevenues.containsKey(payment.paymentMethod)) {
          methodRevenues[payment.paymentMethod] = 0;
        }
        methodRevenues[payment.paymentMethod] =
            methodRevenues[payment.paymentMethod]! + payment.amount;
      }

      return {
        'totalRevenue': totalRevenue,
        'totalCompensation': totalCompensation,
        'totalLateFee': totalLateFee,
        'methodCounts': methodCounts,
        'methodRevenues': methodRevenues,
        'paymentCount': payments.length,
      };
    } catch (e) {
      print('Error getting revenue stats: $e');
      throw e;
    }
  }

  // Lấy thông tin thanh toán theo ID
  Future<Payment> getPaymentById(String id) async {
    try {
      DocumentSnapshot doc = await paymentsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Payment.fromMap(doc.id, data);
      } else {
        throw Exception('Payment not found');
      }
    } catch (e) {
      print('Error getting payment: $e');
      throw e;
    }
  }

  // Lấy danh sách thanh toán theo ID đơn thuê
  Future<List<Payment>> getPaymentsByRentalId(String rentalId) async {
    try {
      QuerySnapshot querySnapshot =
          await paymentsCollection.where('rentalId', isEqualTo: rentalId).get();

      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Payment.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting payments by rental ID: $e');
      throw e;
    }
  }

  // Create a payment with Pending status (before processing)
  Future<Payment> createPendingPayment({
    required String rentalId,
    required String paymentMethod,
    required double amount,
    String? paymentType, // Add paymentType parameter
    double? damageCompensation,
    String? damageDescription,
    double? lateFee,
    int? lateHours,
  }) async {
    try {
      final uuid = Uuid();
      final paymentId = uuid.v4();

      // Workflow mới: Chỉ có một loại thanh toán duy nhất khi trả xe
      String finalPaymentType =
          paymentType ?? PaymentTypeConstants.additionalFee;

      final payment = Payment(
        id: paymentId,
        rentalId: rentalId,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.now(),
        amount: amount,
        status: PaymentStatusConstants.pending,
        paymentType: finalPaymentType,
        damageCompensation: damageCompensation,
        damageDescription: damageDescription,
        lateFee: lateFee,
        lateHours: lateHours,
      );

      await paymentsCollection.doc(payment.id).set(payment.toMap());
      return payment;
    } catch (e) {
      print('Error creating pending payment: $e');
      throw e;
    }
  }

  // Process payment through the appropriate payment gateway based on method
  Future<Payment> processPayment(Payment payment) async {
    try {
      // Update payment status to Processing
      Payment updatedPayment = payment.copyWith(
        status: PaymentStatusConstants.processing,
        processedDate: DateTime.now(),
      );

      await paymentsCollection.doc(payment.id).update({
        'status': PaymentStatusConstants.processing,
        'processedDate': Timestamp.fromDate(DateTime.now()),
      });

      // Process based on payment method
      if (payment.paymentMethod == PaymentMethodConstants.cash) {
        return _processCashPayment(updatedPayment);
      } else if (payment.paymentMethod == PaymentMethodConstants.vnpay) {
        // VNPay payment should be processed via VNPay portal
        // This method shouldn't be called directly for VNPay
        throw Exception(
          'VNPay payments should be processed via initVNPayPayment',
        );
      } else {
        throw Exception('Unsupported payment method: ${payment.paymentMethod}');
      }
    } catch (e) {
      print('Error processing payment: $e');
      // Update payment status to failed
      await paymentsCollection.doc(payment.id).update({
        'status': PaymentStatusConstants.failed,
        'processingNote': 'System error: ${e.toString()}',
      });
      throw e;
    }
  }

  // Process cash payment
  Future<Payment> _processCashPayment(Payment payment) async {
    try {
      // Process payment through gateway
      final response = await _paymentGateway.processPayment(
        paymentMethod: payment.paymentMethod,
        amount: payment.amount,
        orderId: payment.rentalId,
        additionalData: {
          'paymentId': payment.id,
          'hasDamages': payment.damageCompensation != null,
          'isLate': payment.lateFee != null,
        },
      );

      // Update payment with response
      final String newStatus =
          response.success
              ? PaymentStatusConstants.completed
              : PaymentStatusConstants.failed;

      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'transactionId': response.transactionId,
        'gatewayResponse': response.additionalInfo,
        'processingNote':
            response.success
                ? 'Payment processed successfully'
                : 'Payment failed: ${response.errorMessage}',
      };

      // Generate receipt number if payment was successful
      if (response.success) {
        final receiptData = _paymentGateway.generateReceipt(
          transactionId: response.transactionId,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          timestamp: response.timestamp,
          orderId: payment.rentalId,
          additionalInfo: {
            'damageCompensation': payment.damageCompensation,
            'lateFee': payment.lateFee,
          },
        );

        updateData['receiptNumber'] = receiptData['receiptNumber'];
      }

      await paymentsCollection.doc(payment.id).update(updateData);

      // Handle successful payment based on payment type
      if (response.success) {
        final updatedPayment = payment.copyWith(
          status: newStatus,
          transactionId: response.transactionId,
          receiptNumber: updateData['receiptNumber'],
        );
        await _handleSuccessfulPayment(updatedPayment);
      }

      // Return updated payment
      return payment.copyWith(
        status: newStatus,
        transactionId: response.transactionId,
        receiptNumber: response.success ? updateData['receiptNumber'] : null,
      );
    } catch (e) {
      print('Error processing cash payment: $e');
      throw e;
    }
  }

  // Initialize VNPay payment with QR code
  Future<Map<String, dynamic>> initVNPayQRPayment({
    required String rentalId,
    required double amount,
    double? damageCompensation,
    String? damageDescription,
    double? lateFee,
    int? lateHours,
    String? customerSignature,
  }) async {
    try {
      // 1. Create pending payment record
      final payment = await createPendingPayment(
        rentalId: rentalId,
        paymentMethod: PaymentMethodConstants.vnpay,
        amount: amount,
        damageCompensation: damageCompensation,
        damageDescription: damageDescription,
        lateFee: lateFee,
        lateHours: lateHours,
      );

      // 2. Add customer signature if provided
      if (customerSignature != null) {
        await paymentsCollection.doc(payment.id).update({
          'customerSignature': customerSignature,
        });
      }

      // 3. Generate VNPay QR code data
      final totalAmount = amount + (damageCompensation ?? 0) + (lateFee ?? 0);
      final description = 'Thanh toán thuê xe #${rentalId.substring(0, 8)}';

      final qrData = await _paymentGateway.generateVNPayQRData(
        amount: totalAmount,
        orderId: payment.id,
        description: description,
      );

      // 4. Return QR data and payment information
      return {'payment': payment, 'qrData': qrData, 'paymentId': payment.id};
    } catch (e) {
      print('Error generating VNPay QR code: $e');
      throw e;
    }
  }

  // Phương thức initVNPayWebViewPayment đã được loại bỏ vì không còn sử dụng WebView

  // Process VNPay payment callback (for testing sandbox)
  Future<Payment> processVNPayCallback({
    required String paymentId,
    bool forceSuccess = true, // For testing, allow forcing success or failure
  }) async {
    try {
      // 1. Get the pending payment
      final payment = await getPaymentById(paymentId);

      if (payment.status != PaymentStatusConstants.pending) {
        throw Exception('Payment is not in pending status');
      }

      // 2. Update payment status to processing
      await paymentsCollection.doc(paymentId).update({
        'status': PaymentStatusConstants.processing,
        'processedDate': Timestamp.fromDate(DateTime.now()),
      });

      // 3. Process the VNPay callback
      final vnpayResponse = await _paymentGateway.processVNPayCallback(
        orderId: paymentId,
        amount: payment.amount,
        forceSuccess: forceSuccess,
      );

      // 4. Update payment with VNPay response
      final newStatus =
          vnpayResponse.success
              ? PaymentStatusConstants.completed
              : PaymentStatusConstants.failed;

      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'transactionId': vnpayResponse.transactionNo,
        'vnpayTransactionNo': vnpayResponse.transactionNo,
        'vnpayResponseCode': vnpayResponse.responseCode,
        'vnpayOrderInfo': vnpayResponse.orderInfo,
        'processingNote':
            vnpayResponse.success
                ? 'Payment processed successfully via VNPay'
                : 'Payment failed: ${vnpayResponse.errorMessage}',
      };

      // 5. Generate receipt number if payment was successful
      if (vnpayResponse.success) {
        final receiptData = _paymentGateway.generateReceipt(
          transactionId: vnpayResponse.transactionNo,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          timestamp: vnpayResponse.timestamp,
          orderId: payment.rentalId,
          additionalInfo: {
            'damageCompensation': payment.damageCompensation,
            'lateFee': payment.lateFee,
          },
        );

        updateData['receiptNumber'] = receiptData['receiptNumber'];
      }

      // 6. Update payment record
      await paymentsCollection.doc(paymentId).update(updateData);

      // 7. If successful, handle payment based on type
      if (vnpayResponse.success) {
        final updatedPayment = payment.copyWith(
          status: newStatus,
          transactionId: vnpayResponse.transactionNo,
          receiptNumber: updateData['receiptNumber'],
          vnpayTransactionNo: vnpayResponse.transactionNo,
        );

        await _handleSuccessfulPayment(updatedPayment);

        return updatedPayment;
      }

      // 8. Return updated payment
      return payment.copyWith(
        status: newStatus,
        transactionId: vnpayResponse.transactionNo,
        receiptNumber:
            vnpayResponse.success ? updateData['receiptNumber'] : null,
        vnpayTransactionNo: vnpayResponse.transactionNo,
      );
    } catch (e) {
      print('Error processing VNPay callback: $e');

      // Update payment status to failed
      await paymentsCollection.doc(paymentId).update({
        'status': PaymentStatusConstants.failed,
        'processingNote': 'Error processing VNPay callback: ${e.toString()}',
      });

      throw e;
    }
  }

  // Add new payment and process it immediately (for Cash payments)
  Future<Payment> addAndProcessPayment({
    required String rentalId,
    required String paymentMethod,
    required double amount,
    double? damageCompensation,
    String? damageDescription,
    double? lateFee,
    int? lateHours,
    String? customerSignature,
  }) async {
    try {
      // Only support Cash payments through this method
      if (paymentMethod != PaymentMethodConstants.cash) {
        throw Exception(
          'This method only supports cash payments. For other methods, use appropriate methods.',
        );
      }

      // Create pending payment
      final pendingPayment = await createPendingPayment(
        rentalId: rentalId,
        paymentMethod: paymentMethod,
        amount: amount,
        damageCompensation: damageCompensation,
        damageDescription: damageDescription,
        lateFee: lateFee,
        lateHours: lateHours,
      );

      // Add customer signature if provided
      if (customerSignature != null) {
        await paymentsCollection.doc(pendingPayment.id).update({
          'customerSignature': customerSignature,
        });
      }

      // Process the payment
      final processedPayment = await processPayment(
        pendingPayment.copyWith(customerSignature: customerSignature),
      );

      // Note: processPayment already calls _handleSuccessfulPayment internally
      // No need to call it again here to avoid duplicate processing

      return processedPayment;
    } catch (e) {
      print('Error adding and processing payment: $e');
      throw e;
    }
  }

  // Helper method to handle successful payment
  Future<void> _handleSuccessfulPayment(Payment payment) async {
    try {
      final rentalService = RentalService();

      // Workflow mới: Thanh toán chỉ xảy ra khi trả xe
      // Ghi nhận việc trả xe và hoàn tất đơn thuê
      // recordBikeReturn đã có kiểm tra để tránh xử lý nhiều lần
      await rentalService.recordBikeReturn(payment.rentalId);

      // Send confirmation email
      await _sendPaymentConfirmationEmail(payment);
    } catch (e) {
      print('Error handling successful payment: $e');
      throw e;
    }
  }

  // Public method to handle successful payment (for external calls)
  Future<void> handleSuccessfulPayment(Payment payment) async {
    await _handleSuccessfulPayment(payment);
  }

  // Helper method to send payment confirmation email
  Future<void> _sendPaymentConfirmationEmail(Payment payment) async {
    try {
      final userService = UserService();
      final rentalService = RentalService();
      final emailService = EmailService();

      // Get rental information
      final rental = await rentalService.getRentalById(payment.rentalId);

      // Get user information
      final user = await userService.getUserById(rental.userId);

      if (user != null) {
        // Send payment confirmation email
        await emailService.sendPaymentConfirmation(
          payment: payment,
          rental: rental,
          user: user,
        );
      }
    } catch (emailError) {
      print('Error sending payment confirmation email: $emailError');
    }
  }

  // Add payment (legacy method - kept for backward compatibility)
  Future<void> addPayment(Payment payment) async {
    try {
      await paymentsCollection.doc(payment.id).set(payment.toMap());

      // Send confirmation email for completed payments
      if (payment.status == PaymentStatusConstants.completed) {
        await _sendPaymentConfirmationEmail(payment);
      }
    } catch (e) {
      print('Error adding payment: $e');
      throw e;
    }
  }

  // Process refund for a payment
  Future<Payment> refundPayment(String paymentId, {String? reason}) async {
    try {
      // Get payment details
      final payment = await getPaymentById(paymentId);

      // Check if payment can be refunded
      if (payment.status != PaymentStatusConstants.completed) {
        throw Exception('Only completed payments can be refunded');
      }

      // Process refund through gateway
      final response = await _paymentGateway.refundPayment(
        transactionId: payment.transactionId ?? paymentId,
        amount: payment.amount,
        reason: reason,
      );

      if (response.success) {
        // Update payment status
        final updateData = {
          'status': PaymentStatusConstants.refunded,
          'refundReason': reason,
          'processingNote': 'Refunded: ${reason ?? 'Customer request'}',
        };

        await paymentsCollection.doc(paymentId).update(updateData);

        return payment.copyWith(status: PaymentStatusConstants.refunded);
      } else {
        throw Exception('Refund failed: ${response.errorMessage}');
      }
    } catch (e) {
      print('Error refunding payment: $e');
      throw e;
    }
  }

  // Cập nhật trạng thái thanh toán
  Future<void> updatePaymentStatus(String id, String status) async {
    try {
      await paymentsCollection.doc(id).update({'status': status});
    } catch (e) {
      print('Error updating payment status: $e');
      throw e;
    }
  }

  // Xóa thanh toán
  Future<void> deletePayment(String id) async {
    try {
      await paymentsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting payment: $e');
      throw e;
    }
  }
}
