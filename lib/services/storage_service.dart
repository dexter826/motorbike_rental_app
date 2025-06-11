import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bike_rental_app/services/config_service.dart';

class StorageService {
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// Upload file ảnh lên ImgBB
  Future<String> uploadFile(File imageFile, String fileName) async {
    try {
      // Đọc file ảnh dưới dạng byte
      List<int> imageBytes = await imageFile.readAsBytes();

      // Tạo FormData để gửi file lên ImgBB
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['key'] = ConfigService.imgbbApiKey;
      request.files.add(
        http.MultipartFile.fromBytes('image', imageBytes, filename: fileName),
      );

      // Gửi request và nhận response
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Phân tích JSON response
      var jsonResponse = jsonDecode(responseBody);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        // Lấy URL của ảnh từ response
        String imageUrl = jsonResponse['data']['url'];
        return imageUrl;
      } else {
        throw Exception(
          'Error uploading to ImgBB: ${jsonResponse['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload chữ ký từ base64 data lên ImgBB
  Future<String> uploadSignatureFromBase64(
    String base64Data,
    String fileName,
  ) async {
    try {
      // Xử lý base64 data (loại bỏ phần header nếu có)
      String base64Image = base64Data;
      if (base64Data.contains(',')) {
        base64Image = base64Data.split(',')[1];
      }

      // Tạo FormData để gửi lên ImgBB
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['key'] = ConfigService.imgbbApiKey;
      request.fields['image'] = base64Image;

      // Gửi request và nhận response
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Phân tích JSON response
      var jsonResponse = jsonDecode(responseBody);
      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        // Lấy URL của ảnh từ response
        String imageUrl = jsonResponse['data']['url'];
        return imageUrl;
      } else {
        throw Exception(
          'Error uploading signature to ImgBB: ${jsonResponse['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading signature: $e');
    }
  }
}
