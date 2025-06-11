import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bike_rental_app/models/staff.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current logged in staff
  Staff? _currentStaff;
  bool get isAdmin => _currentStaff?.role == 'admin';
  Staff? get currentStaff => _currentStaff;

  // Session keys for SharedPreferences
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';
  static const String _userNameKey = 'user_name';

  // Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString(_userIdKey);

    if (userId != null) {
      try {
        // Get current user data from Firestore
        final userDoc = await _firestore.collection('staff').doc(userId).get();
        if (userDoc.exists) {
          _currentStaff = Staff.fromJson({
            'id': userId,
            ...userDoc.data() as Map<String, dynamic>,
          });
          return true;
        }
      } catch (e) {
        print('Error retrieving user data: $e');
      }
    }

    return false;
  }

  // Save user session
  Future<void> _saveSession(Staff staff) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, staff.id);
    await prefs.setString(_userEmailKey, staff.email);
    await prefs.setString(_userRoleKey, staff.role);
    await prefs.setString(_userNameKey, staff.name);
    _currentStaff = staff;
  }

  // Clear session on logout
  Future<void> _clearSession() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userNameKey);
    _currentStaff = null;
  }

  // Đăng nhập bằng Email và mật khẩu
  Future<Map<String, dynamic>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    Map<String, dynamic> result = {
      'success': false,
      'emailError': null,
      'passError': null,
      'message': null,
    };

    try {
      // Authenticate with Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user exists in staff collection
      final userDoc =
          await _firestore
              .collection('staff')
              .doc(userCredential.user!.uid)
              .get();

      if (userDoc.exists) {
        // Create staff object
        Staff staff = Staff.fromJson({
          'id': userCredential.user!.uid,
          ...userDoc.data() as Map<String, dynamic>,
        });

        // Check if staff is active
        if (!staff.isActive) {
          result['message'] =
              'Tài khoản của bạn đã bị vô hiệu hóa. Vui lòng liên hệ với quản trị viên.';
          await _auth.signOut();
          return result;
        }

        // Save session and update current staff
        await _saveSession(staff);
        _currentStaff = staff; // Ensure _currentStaff is updated
        result['success'] = true;
      } else {
        // User exists in Auth but not in staff collection
        result['message'] =
            'Tài khoản không tồn tại trong hệ thống nhân viên. Vui lòng liên hệ với quản trị viên.';
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        result['emailError'] = 'Vui lòng nhập đúng định dạng email';
      } else if (e.code == 'wrong-password') {
        result['passError'] = 'Mật khẩu không đúng';
      } else if (e.code == 'user-not-found') {
        result['message'] = 'Không tìm thấy tài khoản';
      } else if (e.code == 'invalid-credential') {
        result['message'] =
            'Thông tin đăng nhập không hợp lệ. Vui lòng kiểm tra email và mật khẩu.';
      } else {
        result['message'] = 'Lỗi đăng nhập: ${e.message}'; // Xử lý các lỗi khác
      }
    } catch (e) {
      result['message'] = 'Đã xảy ra lỗi không xác định';
    }

    return result;
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _clearSession();
    await _auth.signOut();
  }

  // Create new staff (admin only function)
  Future<Map<String, dynamic>> createStaff({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? avatar,
  }) async {
    Map<String, dynamic> result = {'success': false, 'error': null};

    // Check if current user is admin
    if (_currentStaff?.role != 'admin') {
      result['error'] = 'Chỉ quản trị viên có thể tạo tài khoản nhân viên';
      return result;
    }

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Create staff document in Firestore
      final staff = Staff(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        avatar: avatar,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('staff').doc(staff.id).set(staff.toJson());

      result['success'] = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        result['error'] = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        result['error'] = 'The account already exists for that email';
      } else if (e.code == 'invalid-email') {
        result['error'] = 'The email address is not valid';
      } else {
        result['error'] = e.message;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  // Đăng ký tài khoản mới bằng Email và mật khẩu
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phoneNumber,
    String? avatar,
  }) async {
    Map<String, dynamic> result = {'success': false, 'error': null};

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Create staff document in Firestore
      final staff = Staff(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
        avatar: avatar,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('staff').doc(staff.id).set(staff.toJson());

      result['success'] = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        result['error'] = 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        result['error'] = 'The account already exists for that email';
      } else if (e.code == 'invalid-email') {
        result['error'] = 'The email address is not valid';
      } else {
        result['error'] = e.message;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  // Reset mật khẩu
  Future<Map<String, dynamic>> resetPassword({required String email}) async {
    Map<String, dynamic> result = {'success': false, 'error': null};

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      result['success'] = true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        result['error'] = 'No user found for that email';
      } else if (e.code == 'invalid-email') {
        result['error'] = 'The email address is not valid';
      } else {
        result['error'] = e.message;
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }
}
