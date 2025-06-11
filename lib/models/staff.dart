import 'package:cloud_firestore/cloud_firestore.dart';

class Staff {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' hoặc 'staff'
  final String? phoneNumber;
  final String? avatar;
  final DateTime createdAt;
  final bool isActive;

  Staff({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.avatar,
    required this.createdAt,
    this.isActive = true,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'staff',
      phoneNumber: json['phoneNumber'],
      avatar: json['avatar'],
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] is Timestamp
                  ? json['createdAt'].toDate()
                  : DateTime.parse(json['createdAt']))
              : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phoneNumber': phoneNumber,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  Staff copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phoneNumber,
    String? avatar,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Staff(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
