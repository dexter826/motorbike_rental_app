import 'package:cloud_firestore/cloud_firestore.dart';

// Define rental status constants
class RentalStatusConstants {
  static const String ongoing =
      'Ongoing'; // Đang thuê xe (đã thanh toán và nhận xe)
  static const String completed = 'Completed'; // Đã trả xe và hoàn tất
  static const String expired = 'Expired'; // Quá hạn trả xe

  static List<String> getAllStatuses() {
    return [ongoing, completed, expired];
  }
}

class Rental {
  final String id;
  final String bikeId;
  final String userId;
  final int quantity;
  final DateTime createdAt;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? returnedDate;
  final DateTime? cancelledAt;
  final double totalAmount;
  final String status;

  Rental({
    required this.id,
    required this.bikeId,
    required this.userId,
    required this.quantity,
    required this.createdAt,
    required this.startTime,
    required this.endTime,
    this.returnedDate,
    this.cancelledAt,
    required this.totalAmount,
    required this.status,
  });

  factory Rental.fromMap(String id, Map<String, dynamic> map) {
    return Rental(
      id: id,
      bikeId: map['bikeId'],
      userId: map['userId'],
      quantity: map['quantity'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      returnedDate:
          map['returnedDate'] != null
              ? (map['returnedDate'] as Timestamp).toDate()
              : null,
      cancelledAt:
          map['cancelledAt'] != null
              ? (map['cancelledAt'] as Timestamp).toDate()
              : null,
      totalAmount: map['totalAmount'].toDouble(),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'bikeId': bikeId,
      'userId': userId,
      'quantity': quantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalAmount': totalAmount,
      'status': status,
    };

    if (returnedDate != null) {
      map['returnedDate'] = Timestamp.fromDate(returnedDate!);
    }

    if (cancelledAt != null) {
      map['cancelledAt'] = Timestamp.fromDate(cancelledAt!);
    }

    return map;
  }
}
