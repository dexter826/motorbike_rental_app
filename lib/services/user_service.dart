import 'package:bike_rental_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> addUser(User user) async {
    await usersCollection.doc(user.id).set(user.toJson());
  }

  Future<List<User>> getUsers() async {
    QuerySnapshot snapshot = await usersCollection.get();
    return snapshot.docs
        .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<User?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userId).get();
      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Kiểm tra ID Card đã tồn tại hay chưa (BẮT BUỘC)
  Future<bool> checkIdCardExists(String idCard) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('idCard', isEqualTo: idCard)
              .limit(1)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking ID Card existence: $e');
      return false;
    }
  }

  // Kiểm tra Email đã tồn tại hay chưa (BẮT BUỘC)
  Future<bool> checkEmailExists(String email) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Kiểm tra Phone đã tồn tại hay chưa (CẢNH BÁO)
  Future<bool> checkPhoneExists(String phone) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('phone', isEqualTo: phone.trim())
              .limit(1)
              .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone existence: $e');
      return false;
    }
  }

  // Lấy thông tin user theo ID Card
  Future<User?> getUserByIdCard(String idCard) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('idCard', isEqualTo: idCard)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return User.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by ID Card: $e');
      return null;
    }
  }

  // Lấy thông tin user theo Email
  Future<User?> getUserByEmail(String email) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('email', isEqualTo: email.toLowerCase().trim())
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return User.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  // Lấy thông tin user theo Phone
  Future<User?> getUserByPhone(String phone) async {
    try {
      QuerySnapshot snapshot =
          await usersCollection
              .where('phone', isEqualTo: phone.trim())
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return User.fromJson(
          snapshot.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Error getting user by phone: $e');
      return null;
    }
  }

  // Kiểm tra tất cả các trường trùng lặp
  Future<Map<String, dynamic>> validateUserData({
    required String email,
    required String phone,
    required String idCard,
    String? excludeUserId, // Để loại trừ user hiện tại khi update
  }) async {
    Map<String, dynamic> result = {
      'isValid': true,
      'errors': <String>[],
      'warnings': <String>[],
    };

    try {
      // 1. Kiểm tra ID Card (BẮT BUỘC)
      bool idCardExists = await checkIdCardExists(idCard);
      if (idCardExists) {
        User? existingUser = await getUserByIdCard(idCard);
        if (existingUser != null && existingUser.id != excludeUserId) {
          result['isValid'] = false;
          result['errors'].add(
            'Số CCCD "$idCard" đã được sử dụng bởi khách hàng "${existingUser.name}"',
          );
        }
      }

      // 2. Kiểm tra Email (BẮT BUỘC)
      bool emailExists = await checkEmailExists(email);
      if (emailExists) {
        User? existingUser = await getUserByEmail(email);
        if (existingUser != null && existingUser.id != excludeUserId) {
          result['isValid'] = false;
          result['errors'].add(
            'Email "$email" đã được sử dụng bởi khách hàng "${existingUser.name}"',
          );
        }
      }

      // 3. Kiểm tra Phone (CẢNH BÁO)
      bool phoneExists = await checkPhoneExists(phone);
      if (phoneExists) {
        User? existingUser = await getUserByPhone(phone);
        if (existingUser != null && existingUser.id != excludeUserId) {
          result['warnings'].add(
            'Số điện thoại "$phone" đã được sử dụng bởi khách hàng "${existingUser.name}". Bạn có muốn tiếp tục?',
          );
        }
      }
    } catch (e) {
      print('Error validating user data: $e');
      result['isValid'] = false;
      result['errors'].add(
        'Lỗi hệ thống khi kiểm tra dữ liệu. Vui lòng thử lại.',
      );
    }

    return result;
  }
}
