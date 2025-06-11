import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/email_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalService {
  final CollectionReference rentalsCollection = FirebaseFirestore.instance
      .collection('rentals');
  final BikeService _bikeService = BikeService();

  // Lấy danh sách đơn thuê với các tùy chọn lọc
  Future<List<Rental>> getRentals({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    String? lastDocumentId,
    String? status,
  }) async {
    try {
      Query query = rentalsCollection;

      // Áp dụng bộ lọc thời gian nếu có
      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Áp dụng bộ lọc trạng thái nếu có
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      // Sắp xếp theo thời gian bắt đầu giảm dần (mới nhất trước)
      query = query.orderBy('startTime', descending: true);

      // Áp dụng phân trang nếu có
      if (lastDocumentId != null) {
        DocumentSnapshot lastDoc =
            await rentalsCollection.doc(lastDocumentId).get();
        query = query.startAfterDocument(lastDoc);
      }

      // Giới hạn số lượng kết quả
      query = query.limit(limit);

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Rental.fromMap(doc.id, data);
      }).toList();
    } catch (e) {
      print('Error getting rentals: $e');
      throw e;
    }
  }

  // Lấy tổng số đơn thuê theo khoảng thời gian
  Future<int> getRentalCount({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      Query query = rentalsCollection;

      // Áp dụng bộ lọc thời gian nếu có
      if (startDate != null) {
        query = query.where(
          'startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      // Áp dụng bộ lọc trạng thái nếu có
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      AggregateQuerySnapshot aggregateSnapshot = await query.count().get();
      return aggregateSnapshot.count ?? 0;
    } catch (e) {
      print('Error getting rental count: $e');
      throw e;
    }
  }

  // Lấy thông tin đơn thuê theo ID
  Future<Rental> getRentalById(String id) async {
    try {
      DocumentSnapshot doc = await rentalsCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return Rental.fromMap(doc.id, data);
      } else {
        throw Exception('Rental not found');
      }
    } catch (e) {
      print('Error getting rental: $e');
      throw e;
    }
  }

  // Validate bike availability before rental
  Future<bool> validateBikeAvailability(
    String bikeId,
    int requestedQuantity,
  ) async {
    try {
      return await _bikeService.canRentBike(bikeId, requestedQuantity);
    } catch (e) {
      print('Error validating bike availability: $e');
      return false;
    }
  }

  // Thêm đơn thuê mới với validation
  Future<void> addRental(Rental rental) async {
    try {
      // Validate bike availability trước khi tạo rental
      bool canRent = await validateBikeAvailability(
        rental.bikeId,
        rental.quantity,
      );
      if (!canRent) {
        throw Exception(
          'Bike is not available for rent or insufficient quantity',
        );
      }

      await rentalsCollection.doc(rental.id).set(rental.toMap());

      // Workflow mới: Gửi email xác nhận thuê xe thành công ngay lập tức
      await _sendRentalConfirmationEmail(rental);
    } catch (e) {
      print('Error adding rental: $e');
      throw e;
    }
  }

  // Gia hạn đơn thuê - cập nhật ngày kết thúc và tính phí gia hạn
  Future<void> updateRentalEndDate({
    required String rentalId,
    required DateTime newEndDate,
    required double extensionFee,
  }) async {
    try {
      // Lấy thông tin đơn thuê hiện tại
      DocumentSnapshot rentalDoc = await rentalsCollection.doc(rentalId).get();
      if (!rentalDoc.exists) {
        throw Exception('Rental not found');
      }

      Map<String, dynamic> rentalData =
          rentalDoc.data() as Map<String, dynamic>;
      String currentStatus = rentalData['status'];

      // Kiểm tra xem rental có thể gia hạn không
      if (currentStatus != RentalStatusConstants.ongoing &&
          currentStatus != RentalStatusConstants.expired) {
        throw Exception(
          'Rental cannot be extended. Current status: $currentStatus',
        );
      }

      DateTime currentEndDate = (rentalData['endTime'] as Timestamp).toDate();

      // Validation: ngày gia hạn phải sau ngày kết thúc hiện tại
      if (newEndDate.isBefore(currentEndDate) ||
          newEndDate.isAtSameMomentAs(currentEndDate)) {
        throw Exception('New end date must be after current end date');
      }

      double currentTotalAmount = rentalData['totalAmount']?.toDouble() ?? 0.0;
      double newTotalAmount = currentTotalAmount + extensionFee;

      // Cập nhật đơn thuê với ngày kết thúc mới và tổng tiền mới
      await rentalsCollection.doc(rentalId).update({
        'endTime': Timestamp.fromDate(newEndDate),
        'totalAmount': newTotalAmount,
        'status':
            RentalStatusConstants.ongoing, // Reset về ongoing nếu đang expired
      });

      // Gửi email thông báo gia hạn thành công
      await _sendRentalExtensionEmail(rentalId, newEndDate, extensionFee);
    } catch (e) {
      print('Error updating rental end date: $e');
      throw e;
    }
  }

  // Ghi nhận xe trả
  Future<void> recordBikeReturn(String id) async {
    try {
      // Lấy thông tin đơn thuê
      DocumentSnapshot rentalDoc = await rentalsCollection.doc(id).get();
      if (!rentalDoc.exists) {
        throw Exception('Rental not found');
      }

      Map<String, dynamic> rentalData =
          rentalDoc.data() as Map<String, dynamic>;
      String currentStatus = rentalData['status'];

      // Kiểm tra xem rental đã được completed chưa để tránh xử lý nhiều lần
      if (currentStatus == RentalStatusConstants.completed) {
        print(
          'Rental $id is already completed, skipping bike return processing',
        );
        return;
      }

      String bikeId = rentalData['bikeId'];
      int rentedQuantity =
          rentalData['quantity'] ??
          1; // Số lượng đã thuê, mặc định là 1 nếu không có dữ liệu

      // Cập nhật trạng thái và ngày trả của đơn thuê
      await rentalsCollection.doc(id).update({
        'returnedDate': DateTime.now(),
        'status': RentalStatusConstants.completed,
      });

      // Cập nhật số lượng xe trong collection 'bikes' (status sẽ được tự động cập nhật bởi BikeService)
      await _bikeService.updateBikeQuantity(
        bikeId,
        (await _bikeService.getBikeById(bikeId)).quantity + rentedQuantity,
      );
    } catch (e) {
      print('Error recording bike return: $e');
      throw e;
    }
  }

  // Lấy danh sách đơn thuê của một người dùng
  Future<List<Map<String, dynamic>>> getUserRentals(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await rentalsCollection.where('userId', isEqualTo: userId).get();

      List<Map<String, dynamic>> rentals =
          querySnapshot.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

      // Sắp xếp danh sách theo thời gian bắt đầu (descending)
      rentals.sort((a, b) {
        Timestamp aTime = a['startTime'] as Timestamp;
        Timestamp bTime = b['startTime'] as Timestamp;
        return bTime.compareTo(aTime); // Descending order
      });

      return rentals;
    } catch (e) {
      print('Error getting user rentals: $e');
      throw e;
    }
  }

  // Kiểm tra và cập nhật trạng thái đơn thuê quá hạn
  Future<List<Rental>> checkAndUpdateExpiredRentals() async {
    try {
      final now = DateTime.now();

      // Lấy tất cả đơn thuê đã quá hạn nhưng vẫn có trạng thái 'Ongoing'
      QuerySnapshot querySnapshot =
          await rentalsCollection
              .where('endTime', isLessThan: Timestamp.fromDate(now))
              .where('status', isEqualTo: RentalStatusConstants.ongoing)
              .get();

      List<Rental> expiredRentals = [];

      // Cập nhật trạng thái của các đơn thuê quá hạn
      for (var doc in querySnapshot.docs) {
        await rentalsCollection.doc(doc.id).update({
          'status': RentalStatusConstants.expired,
        });
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        expiredRentals.add(Rental.fromMap(doc.id, data));
      }

      return expiredRentals;
    } catch (e) {
      print('Error checking expired rentals: $e');
      throw e;
    }
  }

  // Gửi email xác nhận thuê xe thành công
  Future<void> _sendRentalConfirmationEmail(Rental rental) async {
    try {
      final userService = UserService();
      final emailService = EmailService();

      // Lấy thông tin user
      final user = await userService.getUserById(rental.userId);

      if (user != null) {
        // Gửi email xác nhận
        await emailService.sendRentalConfirmation(rental: rental, user: user);
      } else {
        print('User not found for rental ${rental.id}');
      }
    } catch (e) {
      print('Error sending rental confirmation email: $e');
      // Không throw error để không ảnh hưởng đến việc tạo rental
      // Email failure không nên làm fail toàn bộ process
    }
  }

  // Gửi email thông báo gia hạn thành công
  Future<void> _sendRentalExtensionEmail(
    String rentalId,
    DateTime newEndDate,
    double extensionFee,
  ) async {
    try {
      final userService = UserService();
      final emailService = EmailService();

      // Lấy thông tin rental và user
      final rental = await getRentalById(rentalId);
      final user = await userService.getUserById(rental.userId);

      if (user != null) {
        // Gửi email thông báo gia hạn
        await emailService.sendRentalExtensionNotification(
          rental: rental,
          user: user,
          newEndDate: newEndDate,
          extensionFee: extensionFee,
        );
      } else {
        print('User not found for rental $rentalId');
      }
    } catch (e) {
      print('Error sending rental extension email: $e');
      // Không throw error để không ảnh hưởng đến việc gia hạn
      // Email failure không nên làm fail toàn bộ process
    }
  }
}
