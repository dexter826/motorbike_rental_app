import 'package:cloud_firestore/cloud_firestore.dart';

class BikeNotification {
  final String id;
  final String userId;
  final String rentalId;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String type;

  BikeNotification({
    required this.id,
    required this.userId,
    required this.rentalId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory BikeNotification.fromMap(String id, Map<String, dynamic> map) {
    return BikeNotification(
      id: id,
      userId: map['userId'] ?? '',
      rentalId: map['rentalId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'rental_due',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'rentalId': rentalId,
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'type': type,
    };
  }

  BikeNotification copyWith({
    String? id,
    String? userId,
    String? rentalId,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return BikeNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rentalId: rentalId ?? this.rentalId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
