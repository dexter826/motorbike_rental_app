import 'package:bike_rental_app/models/brand.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandService {
  final CollectionReference brandsCollection = FirebaseFirestore.instance
      .collection('brands');

  // Lấy tất cả các hãng xe
  Future<List<Brand>> getBrands() async {
    QuerySnapshot snapshot = await brandsCollection.get();
    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return Brand.fromJson(data);
    }).toList();
  }

  // Lấy danh sách hãng xe dưới dạng Stream
  Stream<List<Brand>> getBrandsStream() {
    return brandsCollection
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              try {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return Brand.fromJson(data);
              } catch (e) {
                print('Error parsing brand document ${doc.id}: $e');
                return Brand(id: doc.id, name: 'Lỗi dữ liệu');
              }
            }).toList();
          } catch (e) {
            print('Error processing brands snapshot: $e');
            return <Brand>[];
          }
        })
        .handleError((error) {
          print('Error in brands stream: $error');
          return <Brand>[];
        });
  }

  // Lấy thông tin một hãng xe theo ID
  Future<Brand?> getBrandById(String brandId) async {
    try {
      DocumentSnapshot doc = await brandsCollection.doc(brandId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Brand.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting brand by ID: $e');
      return null;
    }
  }

  // Thêm một hãng xe mới
  Future<void> addBrand(Brand brand) {
    return brandsCollection.add(brand.toJson());
  }

  // Cập nhật thông tin một hãng xe
  Future<void> updateBrand(Brand brand) {
    return brandsCollection.doc(brand.id).update(brand.toJson());
  }

  // Xóa một hãng xe
  Future<void> deleteBrand(String id) {
    return brandsCollection.doc(id).delete();
  }
}
