import 'package:bike_rental_app/models/staff.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bike_rental_app/services/auth_service.dart';

class StaffService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  StaffService({required AuthService authService}) : _authService = authService;

  // Lấy danh sách nhân viên
  Future<List<Staff>> getStaffList() async {
    try {
      final querySnapshot = await _firestore.collection('staff').get();
      return querySnapshot.docs
          .map((doc) => Staff.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error fetching staff list: $e');
      return [];
    }
  }

  // Cập nhật thông tin nhân viên
  Future<bool> updateStaff(Staff staff) async {
    if (!_authService.isAdmin) {
      return false;
    }

    try {
      await _firestore.collection('staff').doc(staff.id).update(staff.toJson());
      return true;
    } catch (e) {
      print('Error updating staff: $e');
      return false;
    }
  }

  // Tạo mới nhân viên
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? avatar,
  }) async {
    return await _authService.createStaff(
      email: email,
      password: password,
      name: name,
      role: role,
      phoneNumber: phoneNumber,
      avatar: avatar,
    );
  }

  // Xóa nhân viên
  Future<Map<String, dynamic>> deleteStaff(String staffId) async {
    Map<String, dynamic> result = {'success': false, 'error': null};

    if (!_authService.isAdmin) {
      result['error'] = 'Chỉ quản trị viên có thể xóa nhân viên';
      return result;
    }

    try {
      // Xóa tài khoản người dùng
      await _firestore.collection('staff').doc(staffId).delete();
      result['success'] = true;
      return result;
    } catch (e) {
      print('Error deleting staff: $e');
      result['error'] = e.toString();
      return result;
    }
  }
}
