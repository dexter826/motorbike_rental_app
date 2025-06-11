class User {
  String id;
  String name;
  String email;
  String phone;
  String? imageUrl;
  String address;
  String idCard; // Số căn cước công dân
  DateTime dateOfBirth;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.imageUrl,
    required this.address,
    required this.idCard,
    required this.dateOfBirth,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      imageUrl: json['imageUrl'],
      address: json['address'],
      idCard: json['idCard'],
      dateOfBirth:
          json['dateOfBirth'] != null
              ? (json['dateOfBirth'] is DateTime
                  ? json['dateOfBirth']
                  : DateTime.parse(json['dateOfBirth'].toString()))
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'imageUrl': imageUrl,
      'address': address,
      'idCard': idCard,
      'dateOfBirth': dateOfBirth.toIso8601String(),
    };
  }
}
