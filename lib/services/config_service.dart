import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service để quản lý các API key và thông tin cấu hình nhạy cảm
class ConfigService {
  static const String _googleMapsApiKey = 'GOOGLE_MAPS_API_KEY';
  static const String _imgbbApiKey = 'IMGBB_API_KEY';

  /// Lấy Google Maps API key từ file .env
  static String get googleMapsApiKey {
    final apiKey = dotenv.env[_googleMapsApiKey];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Google Maps API key không được tìm thấy trong file .env',
      );
    }
    return apiKey;
  }

  /// Lấy ImgBB API key từ file .env
  static String get imgbbApiKey {
    final apiKey = dotenv.env[_imgbbApiKey];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ImgBB API key không được tìm thấy trong file .env');
    }
    return apiKey;
  }
}
