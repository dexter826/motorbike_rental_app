import 'dart:async';
import 'dart:math';
import '../models/payment.dart';

// Enum to represent payment status as defined by a typical payment gateway
enum PaymentStatus {
  pending,
  processing,
  authorized,
  completed,
  failed,
  refunded,
  cancelled,
}

// Class to simulate payment gateway responses
class PaymentResponse {
  final bool success;
  final String transactionId;
  final PaymentStatus status;
  final String? errorMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalInfo;

  PaymentResponse({
    required this.success,
    required this.transactionId,
    required this.status,
    this.errorMessage,
    required this.timestamp,
    this.additionalInfo,
  });
}

// VNPay response simulation class (simplified)
class VNPayResponse {
  final bool success;
  final String transactionNo;
  final String responseCode;
  final String orderInfo;
  final DateTime timestamp;
  final String? errorMessage;

  VNPayResponse({
    required this.success,
    required this.transactionNo,
    required this.responseCode,
    required this.orderInfo,
    required this.timestamp,
    this.errorMessage,
  });
}

// Main class for the mock payment gateway
class MockPaymentGateway {
  // Singleton instance
  static final MockPaymentGateway _instance = MockPaymentGateway._internal();
  factory MockPaymentGateway() => _instance;
  MockPaymentGateway._internal();

  // Method to process payment
  Future<PaymentResponse> processPayment({
    required String paymentMethod,
    required double amount,
    required String orderId,
    Map<String, dynamic>? additionalData,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Handle based on payment method
    if (paymentMethod == PaymentMethodConstants.cash) {
      return _processCashPayment(amount, orderId, additionalData);
    } else if (paymentMethod == PaymentMethodConstants.vnpay) {
      // VNPay payments are handled through the VNPay portal
      // This method should not be called directly for VNPay
      throw Exception(
        'VNPay payments should be processed through initVNPayTransaction',
      );
    } else {
      // Unsupported payment method
      return PaymentResponse(
        success: false,
        transactionId: 'ERROR-${DateTime.now().millisecondsSinceEpoch}',
        status: PaymentStatus.failed,
        errorMessage: 'Unsupported payment method',
        timestamp: DateTime.now(),
      );
    }
  }

  // Method to process cash payment
  Future<PaymentResponse> _processCashPayment(
    double amount,
    String orderId,
    Map<String, dynamic>? additionalData,
  ) async {
    // Cash payments are always successful in the mock
    final transactionId =
        'CASH-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';

    return PaymentResponse(
      success: true,
      transactionId: transactionId,
      status: PaymentStatus.completed,
      timestamp: DateTime.now(),
      additionalInfo: {
        'paymentMethod': PaymentMethodConstants.cash,
        'amount': amount,
        'orderId': orderId,
        'processingTime': '0.5 seconds',
        ...?additionalData,
      },
    );
  }

  // Generate VNPay QR code data
  Future<Map<String, dynamic>> generateVNPayQRData({
    required double amount,
    required String orderId,
    String? description,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    // Create URL for the demo payment website
    final baseUrl = 'https://dexter826.github.io/bike-rental-payment-demo/';
    final encodedDescription = Uri.encodeComponent(
      description ?? 'Thanh toán đơn thuê',
    );
    final merchantName = Uri.encodeComponent('Smurf Bike Rental');

    // Build the payment URL with parameters
    final qrContent =
        '$baseUrl?orderId=$orderId&amount=${amount.round()}&description=$encodedDescription&merchantName=$merchantName';

    return {
      'qrContent': qrContent,
      'amount': amount,
      'orderId': orderId,
      'description': description ?? 'Thanh toán đơn thuê: $orderId',
      'expiryTime': DateTime.now().add(Duration(minutes: 15)),
      'merchantName': 'Smurf Company Rental',
      'merchantId': 'SMURF1234',
      'paymentUrl': qrContent, // Add the full URL for reference
    };
  }

  // Phương thức initVNPayTransaction đã được loại bỏ vì không còn sử dụng WebView

  // Simulate external payment completion (from website)
  static final Map<String, bool> _externalPaymentStatus = {};

  // Method to simulate external payment completion
  static void simulateExternalPaymentSuccess(String orderId) {
    _externalPaymentStatus[orderId] = true;
    print('External payment simulated for order: $orderId');
  }

  // Check if external payment was completed
  static bool isExternalPaymentCompleted(String orderId) {
    return _externalPaymentStatus[orderId] ?? false;
  }

  // Clear external payment status
  static void clearExternalPaymentStatus(String orderId) {
    _externalPaymentStatus.remove(orderId);
  }

  // Process VNPay payment response (simulating callback from VNPay)
  Future<VNPayResponse> processVNPayCallback({
    required String orderId,
    required double amount,
    bool forceSuccess = true, // For testing, allow forcing success or failure
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Check if external payment was completed first
    final externalPaymentCompleted = isExternalPaymentCompleted(orderId);

    final random = Random();
    // Success probability - prioritize external payment status
    final isSuccessful =
        externalPaymentCompleted ||
        (forceSuccess ? true : random.nextDouble() < 0.9);

    // Clear external payment status after checking
    if (externalPaymentCompleted) {
      clearExternalPaymentStatus(orderId);
    }

    if (isSuccessful) {
      return VNPayResponse(
        success: true,
        transactionNo: 'VNP${DateTime.now().millisecondsSinceEpoch}',
        responseCode: '00', // 00 means success in VNPay
        orderInfo: 'Thanh toán đơn thuê: $orderId',
        timestamp: DateTime.now(),
      );
    } else {
      // Error codes from VNPay
      final errorCodes = ['01', '02', '07', '09', '10', '11', '12', '99'];
      final errorMessages = {
        '01': 'Order not found',
        '02': 'Order already paid',
        '07': 'Transaction declined by bank',
        '09': 'Transaction expired',
        '10': 'Technical error',
        '11': 'Customer cancelled',
        '12': 'Invalid amount',
        '99': 'Other error',
      };

      final errorCode = errorCodes[random.nextInt(errorCodes.length)];

      return VNPayResponse(
        success: false,
        transactionNo: 'VNP${DateTime.now().millisecondsSinceEpoch}',
        responseCode: errorCode,
        orderInfo: 'Thanh toán đơn thuê: $orderId',
        timestamp: DateTime.now(),
        errorMessage: errorMessages[errorCode],
      );
    }
  }

  // Process refund for a payment
  Future<PaymentResponse> refundPayment({
    required String transactionId,
    required double amount,
    String? reason,
  }) async {
    await Future.delayed(Duration(seconds: 2));

    final random = Random();
    final isSuccessful = random.nextDouble() < 0.95;

    if (isSuccessful) {
      return PaymentResponse(
        success: true,
        transactionId: 'REF-$transactionId',
        status: PaymentStatus.refunded,
        timestamp: DateTime.now(),
        additionalInfo: {
          'originalTransaction': transactionId,
          'refundAmount': amount,
          'reason': reason ?? 'Customer request',
        },
      );
    } else {
      return PaymentResponse(
        success: false,
        transactionId: 'REF-$transactionId',
        status: PaymentStatus.failed,
        errorMessage: 'Refund failed: original transaction not found',
        timestamp: DateTime.now(),
      );
    }
  }

  // Generate payment receipt data
  Map<String, dynamic> generateReceipt({
    required String transactionId,
    required double amount,
    required String paymentMethod,
    required DateTime timestamp,
    required String orderId,
    Map<String, dynamic>? additionalInfo,
  }) {
    final receiptNumber = 'R-${DateTime.now().millisecondsSinceEpoch}';

    return {
      'receiptNumber': receiptNumber,
      'transactionId': transactionId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp,
      'orderId': orderId,
      'additionalInfo': additionalInfo,
      'merchantName': 'Smurf Company Rental',
      'merchantAddress': '123 Bike Street, Ho Chi Minh City',
      'merchantTaxId': '0123456789',
    };
  }
}
