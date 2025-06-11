import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/screens/bike/bike_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart';

class QRScannerScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const QRScannerScreen({super.key, this.onBack});

  @override
  State<StatefulWidget> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool isProcessing = false;
  bool hasPermission = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestCameraPermission(),
    );
  }

  @override
  void dispose() {
    // controller?.dispose(); // Không cần gọi dispose nữa vì controller tự dispose
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) controller?.pauseCamera();
    controller?.resumeCamera();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) setState(() => hasPermission = status.isGranted);
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (isProcessing || scanData.code == null) return;

      setState(() => isProcessing = true);

      try {
        final bikeService = BikeService();
        final bikes = await bikeService.getBikes();
        final bike = bikes.firstWhere(
          (bike) => bike.id == scanData.code,
          orElse: () => throw Exception('Bike not found'),
        );

        // Tạm dừng camera trước
        controller.pauseCamera();

        if (mounted) {
          // Sử dụng Navigator.push thay vì pushReplacement để có thể quay lại
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      BikeDetailsScreen(bike: bike),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          ).then((_) {
            // Khi quay lại từ BikeDetailsScreen, reset trạng thái và tiếp tục quét
            if (mounted) {
              setState(() => isProcessing = false);
              controller.resumeCamera();
            }
          });
        }
      } catch (e) {
        if (mounted) {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'qr.error'.tr(),
              message: 'qr.bike_not_found'.tr(),
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          setState(() => isProcessing = false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              widget.onBack?.call(); // Chỉ gọi callback để cập nhật trạng thái
            },
          ),
          title: Text('qr.scan'.tr(), style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('qr.camera_permission_required'.tr()),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: Text('qr.grant_permission'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            widget.onBack?.call(); // Chỉ gọi callback để cập nhật trạng thái
          },
        ),
        title: Text('qr.scan'.tr(), style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          if (isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: AppLoadingIndicator(color: Colors.white, size: 50),
              ),
            ),
        ],
      ),
    );
  }
}
