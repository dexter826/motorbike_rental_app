import 'package:bike_rental_app/models/bike.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BikeService {
  final CollectionReference bikesCollection = FirebaseFirestore.instance
      .collection('bikes');

  // Lấy danh sách tất cả xe
  Future<List<Bike>> getBikes() async {
    try {
      QuerySnapshot querySnapshot = await bikesCollection.get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Bike.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting bikes: $e');
      throw e;
    }
  }

  // Lấy danh sách xe theo id
  Future<Bike> getBikeById(String id) async {
    try {
      DocumentSnapshot doc = await bikesCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Bike.fromJson(data);
      } else {
        throw Exception('Bike not found');
      }
    } catch (e) {
      print('Error getting bike: $e');
      throw e;
    }
  }

  // Thêm xe mới
  Future<void> addBike(Bike bike) async {
    try {
      await bikesCollection.doc(bike.id).set(bike.toJson());
    } catch (e) {
      print('Error adding bike: $e');
      throw e;
    }
  }

  // Cập nhật thông tin xe
  Future<void> updateBike(Bike bike) async {
    try {
      await bikesCollection.doc(bike.id).update(bike.toJson());
    } catch (e) {
      print('Error updating bike: $e');
      throw e;
    }
  }

  // Cập nhật số lượng xe và tự động cập nhật status
  Future<void> updateBikeQuantity(String id, int newQuantity) async {
    try {
      // Lấy thông tin bike hiện tại để kiểm tra status
      DocumentSnapshot doc = await bikesCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Bike not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String currentStatus = data['status'] ?? BikeStatusConstants.available;

      // Tự động cập nhật status dựa trên quantity (chỉ khi không phải manual unavailable)
      String newStatus = currentStatus;
      if (currentStatus == BikeStatusConstants.available && newQuantity <= 0) {
        newStatus = BikeStatusConstants.unavailable;
      } else if (currentStatus == BikeStatusConstants.unavailable &&
          newQuantity > 0) {
        // Chỉ tự động chuyển về available nếu admin không manually set unavailable
        // Để đơn giản, ta sẽ để admin tự quản lý status khi quantity > 0
        newStatus = BikeStatusConstants.available;
      }

      await bikesCollection.doc(id).update({
        'quantity': newQuantity,
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating bike quantity: $e');
      throw e;
    }
  }

  // Cập nhật status của bike (cho admin manual control)
  Future<void> updateBikeStatus(String id, String status) async {
    try {
      await bikesCollection.doc(id).update({'status': status});
    } catch (e) {
      print('Error updating bike status: $e');
      throw e;
    }
  }

  // Kiểm tra xem bike có thể thuê không
  Future<bool> canRentBike(String id, int requestedQuantity) async {
    try {
      Bike bike = await getBikeById(id);
      return BikeStatusConstants.canRent(bike.status, bike.quantity) &&
          bike.quantity >= requestedQuantity;
    } catch (e) {
      print('Error checking bike availability: $e');
      return false;
    }
  }

  // Xóa xe
  Future<void> deleteBike(String id) async {
    try {
      await bikesCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting bike: $e');
      throw e;
    }
  }
}
