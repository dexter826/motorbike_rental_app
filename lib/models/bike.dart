// Define bike status constants
class BikeStatusConstants {
  static const String available = 'Available'; // Xe có thể thuê
  static const String unavailable =
      'Unavailable'; // Xe không thể thuê (bảo trì, hỏng, v.v.)

  static List<String> getAllStatuses() {
    return [available, unavailable];
  }

  // Kiểm tra xem bike có thể thuê không
  static bool canRent(String status, int quantity) {
    return status == available && quantity > 0;
  }
}

// Define bike type constants
class BikeTypeConstants {
  static const String manual = 'Manual';
  static const String scooter = 'Scooter';
  static const String electric = 'Electric';

  static List<String> getAllTypes() {
    return [manual, scooter, electric];
  }

  // Lấy translation key cho loại xe
  static String getTranslationKey(String type) {
    switch (type) {
      case manual:
        return 'bike.manual_bike';
      case scooter:
        return 'bike.scooter';
      case electric:
        return 'bike.electric_bike';
      default:
        return type;
    }
  }

  // Lấy icon cho loại xe
  static String getTypeIcon(String type) {
    switch (type) {
      case manual:
        return '🏍️';
      case scooter:
        return '🛵';
      case electric:
        return '⚡';
      default:
        return '🏍️';
    }
  }
}

class Bike {
  String id;
  String name;
  String brandId;
  String type;
  String licensePlate;
  int quantity;
  double price;
  String status;
  String? imageUrl;

  Bike({
    required this.id,
    required this.name,
    required this.brandId,
    required this.type,
    required this.licensePlate,
    required this.quantity,
    required this.price,
    required this.status,
    this.imageUrl = '',
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brandId: json['brandId'] ?? '',
      type: json['type'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      quantity:
          json['quantity'] != null ? (json['quantity'] as num).toInt() : 0,
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      status: json['status'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brandId': brandId,
      'type': type,
      'licensePlate': licensePlate,
      'quantity': quantity,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
    };
  }
}
