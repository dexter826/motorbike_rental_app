import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../services/config_service.dart';

class BikeLocationMapScreen extends StatefulWidget {
  final String bikeId;

  const BikeLocationMapScreen({required this.bikeId, super.key});

  @override
  BikeLocationMapScreenState createState() => BikeLocationMapScreenState();
}

class BikeLocationMapScreenState extends State<BikeLocationMapScreen> {
  // Google Maps controller
  GoogleMapController? _mapController;

  // Bike location data
  LatLng _bikeLocation = const LatLng(10.8231, 106.6297); // Default to HCMC
  String _address = "";
  Set<Marker> _markers = {};
  Timer? _timer;
  bool _isLoading = true;

  // For location permissions
  bool _locationPermissionChecked = false;
  LocationPermission? _permission;
  // Lấy địa chỉ từ tọa độ sử dụng Geocoding API
  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${ConfigService.googleMapsApiKey}&language=vi',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }

      // Fallback nếu API không trả về kết quả
      return "TP. Hồ Chí Minh, Việt Nam";
    } catch (e) {
      debugPrint('Error getting address: $e');
      return "Khu vực TP. Hồ Chí Minh";
    }
  }

  // Kiểm tra quyền truy cập vị trí
  Future<bool> _checkLocationPermission() async {
    if (_locationPermissionChecked) {
      return _permission != LocationPermission.denied;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Dịch vụ vị trí bị tắt, không thể tiếp tục
      return false;
    }

    _permission = await Geolocator.checkPermission();
    if (_permission == LocationPermission.denied) {
      _permission = await Geolocator.requestPermission();
      if (_permission == LocationPermission.denied) {
        // Quyền bị từ chối, không thể tiếp tục
        return false;
      }
    }

    if (_permission == LocationPermission.deniedForever) {
      // Quyền bị từ chối vĩnh viễn, không thể tiếp tục
      return false;
    }

    _locationPermissionChecked = true;
    return true;
  }

  // Lấy vị trí hiện tại từ GPS
  Future<LatLng?> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        debugPrint('Không có quyền truy cập vị trí');
        return null;
      }

      // Lấy vị trí hiện tại
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Cập nhật vị trí xe đạp
  Future<void> _updateLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy vị trí hiện tại từ GPS
      LatLng? currentLocation = await _getCurrentLocation();

      // Nếu không lấy được vị trí hiện tại, sử dụng vị trí mặc định
      LatLng newLocation = currentLocation ?? _bikeLocation;

      // Lấy địa chỉ từ tọa độ
      String address = await _getAddressFromLatLng(newLocation);

      if (mounted) {
        setState(() {
          _bikeLocation = newLocation;
          _address = address;
          _updateMarkers();
          _isLoading = false;
        });

        // Di chuyển camera đến vị trí mới
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _bikeLocation, zoom: 15.0),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Cập nhật marker trên bản đồ
  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('bike_location'),
        position: _bikeLocation,
        infoWindow: InfoWindow(
          title: "${'bike.bike_id'.tr()}: ${widget.bikeId}",
          snippet: _address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  @override
  void initState() {
    super.initState();

    // Khởi tạo và cập nhật vị trí ban đầu
    _initializeLocation();

    // Thiết lập timer để cập nhật vị trí định kỳ (30 giây)
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateLocation();
      }
    });
  }

  // Khởi tạo vị trí ban đầu
  Future<void> _initializeLocation() async {
    await _checkLocationPermission();
    await _updateLocation();
  }

  // Hàm mở Google Maps với tọa độ hiện tại
  Future<void> _openGoogleMaps() async {
    final lat = _bikeLocation.latitude;
    final lng = _bikeLocation.longitude;

    // Sử dụng địa chỉ văn bản của Trường Đại học Công Thương TP.HCM
    final originAddress = '140 đường Lê Trọng Tấn, Tây Thạnh, Tân Phú';
    final encodedOrigin = Uri.encodeComponent(originAddress);

    // Tạo URL với cả vị trí xuất phát và đích đến
    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$encodedOrigin'
        '&destination=$lat,$lng'
        '&travelmode=driving';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Hiển thị thông báo lỗi nếu không thể mở Google Maps
      if (!mounted) return;
      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'rental.cannot_open_maps'.tr(),
          message: 'rental.maps_error_message'.tr(),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  // Xử lý khi bản đồ được tạo
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMarkers();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer nếu nó tồn tại
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('rental.bike_location'.tr())),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Google Map
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _bikeLocation,
                    zoom: 15.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  mapToolbarEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                ),

                // Loading indicator
                if (_isLoading)
                  Container(
                    color: Colors.black.withAlpha(76),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'rental.location_info'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _address.isNotEmpty
                                ? _address
                                : 'rental.loading_address'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${_bikeLocation.latitude.toStringAsFixed(4)}, ${_bikeLocation.longitude.toStringAsFixed(4)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: Text('rental.directions_to_bike'.tr()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _openGoogleMaps,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
