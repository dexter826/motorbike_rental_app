import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Define payment status constants for use throughout the app
class PaymentStatusConstants {
  static const String pending = 'Pending';
  // pendingConfirmation đã bỏ vì không cần trạng thái trung gian
  static const String processing = 'Processing';
  static const String authorized = 'Authorized';
  static const String completed = 'Completed';
  static const String failed = 'Failed';
  static const String refunded = 'Refunded';
  static const String cancelled = 'Cancelled';

  static List<String> getAllStatuses() {
    return [
      pending,
      processing,
      authorized,
      completed,
      failed,
      refunded,
      cancelled,
    ];
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case pending:
        return Colors.orange;
      // Trạng thái pendingConfirmation đã bỏ
      case processing:
        return Colors.blue;
      case authorized:
        return Colors.purple;
      case completed:
        return Colors.green;
      case failed:
        return Colors.red;
      case refunded:
        return Colors.amber;
      case cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

// Define payment method constants
class PaymentMethodConstants {
  static const String cash = 'Cash';
  static const String vnpay = 'VNPay';

  static List<String> getAllMethods() {
    return [cash, vnpay];
  }

  static IconData getMethodIcon(String method) {
    switch (method) {
      case cash:
        return Icons.money;
      case vnpay:
        return Icons.qr_code;
      default:
        return Icons.payment;
    }
  }
}

// Define payment type constants
class PaymentTypeConstants {
  static const String additionalFee = 'Additional Fee';

  static List<String> getAllTypes() {
    return [additionalFee];
  }
}

class Payment {
  final String id;
  final String rentalId;
  final String paymentMethod;
  final DateTime paymentDate;
  final double amount;
  final String status;
  final String paymentType; // New field for payment type
  final double? damageCompensation;
  final String? damageDescription;
  final double? lateFee;
  final int? lateHours;
  // Các trường cần thiết
  final String? transactionId;
  final String? receiptNumber;
  final String? customerSignature; // URL đến chữ ký trong Storage
  final DateTime? processedDate;
  // VNPay specific fields
  final String? vnpayTransactionNo;

  Payment({
    required this.id,
    required this.rentalId,
    required this.paymentMethod,
    required this.paymentDate,
    required this.amount,
    required this.status,
    this.paymentType =
        PaymentTypeConstants
            .additionalFee, // Workflow mới: chỉ có một loại payment
    this.damageCompensation,
    this.damageDescription,
    this.lateFee,
    this.lateHours,
    // Các trường cần thiết
    this.transactionId,
    this.receiptNumber,
    this.customerSignature,
    this.processedDate,
    // VNPay specific fields
    this.vnpayTransactionNo,
  });

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      rentalId: map['rentalId'],
      paymentMethod: map['paymentMethod'],
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      amount: map['amount'].toDouble(),
      status: map['status'],
      paymentType:
          map['paymentType'] ??
          PaymentTypeConstants.additionalFee, // Workflow mới
      damageCompensation: map['damageCompensation']?.toDouble(),
      damageDescription: map['damageDescription'],
      lateFee: map['lateFee']?.toDouble(),
      lateHours: map['lateHours'],
      // Các trường cần thiết
      transactionId: map['transactionId'],
      receiptNumber: map['receiptNumber'],
      customerSignature: map['customerSignature'],
      processedDate:
          map['processedDate'] != null
              ? (map['processedDate'] as Timestamp).toDate()
              : null,
      // VNPay specific fields
      vnpayTransactionNo: map['vnpayTransactionNo'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'rentalId': rentalId,
      'paymentMethod': paymentMethod,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'amount': amount,
      'status': status,
      'paymentType': paymentType,
    };

    if (damageCompensation != null) {
      map['damageCompensation'] = damageCompensation!;
    }

    if (damageDescription != null) {
      map['damageDescription'] = damageDescription!;
    }

    if (lateFee != null) {
      map['lateFee'] = lateFee!;
    }

    if (lateHours != null) {
      map['lateHours'] = lateHours!;
    }

    // Add existing fields to map
    if (transactionId != null) {
      map['transactionId'] = transactionId!;
    }

    if (receiptNumber != null) {
      map['receiptNumber'] = receiptNumber!;
    }

    if (customerSignature != null) {
      map['customerSignature'] = customerSignature!;
    }

    if (processedDate != null) {
      map['processedDate'] = Timestamp.fromDate(processedDate!);
    }

    // Add VNPay specific fields to map
    if (vnpayTransactionNo != null) {
      map['vnpayTransactionNo'] = vnpayTransactionNo!;
    }

    return map;
  }

  // Create a copy of this payment with modified fields
  Payment copyWith({
    String? id,
    String? rentalId,
    String? paymentMethod,
    DateTime? paymentDate,
    double? amount,
    String? status,
    String? paymentType,
    double? damageCompensation,
    String? damageDescription,
    double? lateFee,
    int? lateHours,
    String? transactionId,
    String? receiptNumber,
    String? customerSignature,
    DateTime? processedDate,
    String? vnpayTransactionNo,
  }) {
    return Payment(
      id: id ?? this.id,
      rentalId: rentalId ?? this.rentalId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentType: paymentType ?? this.paymentType,
      damageCompensation: damageCompensation ?? this.damageCompensation,
      damageDescription: damageDescription ?? this.damageDescription,
      lateFee: lateFee ?? this.lateFee,
      lateHours: lateHours ?? this.lateHours,
      transactionId: transactionId ?? this.transactionId,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      customerSignature: customerSignature ?? this.customerSignature,
      processedDate: processedDate ?? this.processedDate,
      vnpayTransactionNo: vnpayTransactionNo ?? this.vnpayTransactionNo,
    );
  }
}
