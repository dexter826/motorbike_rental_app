import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/screens/payment/vnpay_qr_screen.dart';
import 'package:bike_rental_app/services/payment_service.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';
import 'package:bike_rental_app/utils/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_signature_pad/flutter_signature_pad.dart';
import 'package:easy_localization/easy_localization.dart';

class CreatePaymentScreen extends StatefulWidget {
  final String? rentalId;

  const CreatePaymentScreen({super.key, this.rentalId});

  @override
  _CreatePaymentScreenState createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends State<CreatePaymentScreen> {
  late TextEditingController _amountController;
  late TextEditingController _damageCompensationController;
  late TextEditingController _damageDescriptionController;
  late TextEditingController _lateFeeController;
  final PaymentService _paymentService = PaymentService();
  final RentalService _rentalService = RentalService();
  final _formKey = GlobalKey<FormState>();

  String? selectedRentalId;
  String paymentMethod = PaymentMethodConstants.cash;
  String currentPaymentType =
      PaymentTypeConstants.additionalFee; // Chỉ có thanh toán cuối
  double baseRentalAmount = 0; // Phí thuê cơ bản
  double amount = 0; // Tổng tiền thanh toán
  double damageCompensation = 0;
  double lateFee = 0;
  int lateHours = 0;
  bool hasDamage = false;
  bool isLateReturn = false;
  List<Rental> rentals = [];
  bool isLoading = true;

  bool isProcessingPayment =
      false; // Biến để kiểm soát trạng thái xử lý thanh toán
  bool showCustomerSignature = false;
  final GlobalKey<SignatureState> _signatureKey = GlobalKey<SignatureState>();
  String? customerSignature;
  bool paymentInProgress = false;
  bool paymentSuccess = false;
  String? paymentErrorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: amount.toString());
    _damageCompensationController = TextEditingController(text: '0');
    _damageDescriptionController = TextEditingController();
    _lateFeeController = TextEditingController(text: '0');
    _initializeData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _damageCompensationController.dispose();
    _damageDescriptionController.dispose();
    _lateFeeController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadRentals();
    if (widget.rentalId != null) {
      setState(() {
        selectedRentalId = widget.rentalId;
      });
      await _loadRentalDetails(widget.rentalId!);
    }
  }

  Future<void> _loadRentals() async {
    try {
      final loadedRentals = await _rentalService.getRentals();
      setState(() {
        rentals =
            loadedRentals
                .where(
                  (rental) => rental.status != RentalStatusConstants.completed,
                )
                .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'common.error'.tr(),
          message: 'rental.load_error'.tr(),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  Future<void> _loadRentalDetails(String rentalId) async {
    try {
      final rental = await _rentalService.getRentalById(rentalId);
      setState(() {
        final now = DateTime.now();

        // Workflow mới: Chỉ có thanh toán cuối khi trả xe
        currentPaymentType = PaymentTypeConstants.additionalFee;

        // Tính phí thuê cơ bản
        baseRentalAmount = rental.totalAmount;
        _amountController.text = baseRentalAmount.toString();

        // Kiểm tra nếu đã quá hạn thuê (so sánh thời gian hiện tại với thời gian kết thúc)
        if (now.isAfter(rental.endTime)) {
          isLateReturn = true;

          // Tính số giờ trả muộn
          final difference = now.difference(rental.endTime);
          lateHours = (difference.inMinutes / 60).ceil(); // Làm tròn lên số giờ

          // Tính phí phạt theo quy tắc
          double calculatedLateFee = 0;

          if (lateHours < 1) {
            // Dưới 1 giờ: Phí cố định 20.000 VNĐ
            calculatedLateFee = 20000;
          } else if (lateHours <= 12) {
            // Từ 1 giờ đến 12 giờ: 30.000 VNĐ/giờ
            calculatedLateFee = lateHours * 30000;
          } else {
            // Trên 12 giờ: Tính dựa trên tổng số giờ trả muộn
            // Tính số ngày trả muộn (làm tròn lên)
            int lateDays = (lateHours / 24).ceil();
            // Phí phạt = số ngày trả muộn * giá thuê một ngày
            calculatedLateFee = lateDays * rental.totalAmount;
          }

          lateFee = calculatedLateFee;
          _lateFeeController.text = lateFee.toString();
        } else {
          isLateReturn = false;
          lateFee = 0;
          lateHours = 0;
          _lateFeeController.text = '0';
        }

        // Reset damage compensation
        hasDamage = false;
        damageCompensation = 0;
        _damageCompensationController.text = '0';

        // Cập nhật tổng tiền sau khi đã tính toán
        _updateTotalAmount();
      });
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'common.error'.tr(),
            message: 'rental.load_error'.tr(),
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  void _updateTotalAmount() {
    setState(() {
      // Tính tổng tiền = phí thuê cơ bản + phí trễ hẹn + phí bồi thường hư hại
      double rentalFee = double.tryParse(_amountController.text) ?? 0;
      double compensation =
          hasDamage
              ? (double.tryParse(_damageCompensationController.text) ?? 0)
              : 0;
      double latePayment =
          isLateReturn ? (double.tryParse(_lateFeeController.text) ?? 0) : 0;

      amount = rentalFee + compensation + latePayment;
    });
  }

  String _getPaymentMethodTranslation(String method) {
    if (method == PaymentMethodConstants.cash) {
      return 'payment.cash'.tr();
    } else if (method == PaymentMethodConstants.vnpay) {
      return 'payment.vnpay'.tr();
    }
    return method;
  }

  // Phương thức _buildWalletOption đã bỏ vì không còn sử dụng

  Future<void> _getSignature() async {
    setState(() {
      showCustomerSignature = true;
    });
  }

  void _clearSignature() {
    final sign = _signatureKey.currentState;
    if (sign != null) {
      sign.clear();
      setState(() {
        customerSignature = null;
      });
    }
  }

  Future<void> _saveSignature() async {
    final sign = _signatureKey.currentState;
    if (sign != null && sign.hasPoints) {
      try {
        // Hiển thị loading dialog
        LoadingDialog.show(context);

        final image = await sign.getData();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes != null) {
          final encoded = base64Encode(bytes.buffer.asUint8List());
          final base64Data = 'data:image/png;base64,$encoded';

          // Tải lên chữ ký lên Imgur để có URL công khai
          final storageService = StorageService();
          final signatureUrl = await storageService.uploadSignatureFromBase64(
            base64Data,
            'signature_${DateTime.now().millisecondsSinceEpoch}.png',
          );

          if (mounted) LoadingDialog.hide(context);

          setState(() {
            // Lưu URL công khai thay vì base64 data
            customerSignature = signatureUrl;
            showCustomerSignature = false;
          });
        }
      } catch (e) {
        if (mounted) LoadingDialog.hide(context);
        if (mounted) {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'common.error'.tr(),
              message: 'payment.signature_upload_error'.tr(),
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      }
    } else {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'payment.empty_signature'.tr(),
          message: 'payment.please_sign'.tr(),
          contentType: ContentType.warning,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate() && selectedRentalId != null) {
      // Workflow mới: Luôn có ít nhất phí thuê cơ bản
      // Không cần kiểm tra thanh toán 0đ vì luôn có baseRentalAmount

      if (amount <= 0) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'common.error'.tr(),
            message: 'payment.invalid_amount'.tr(),
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        return;
      }

      // Kiểm tra xem có cần chữ ký không
      if (customerSignature == null) {
        // Hiển thị hộp thoại chữ ký
        setState(() {
          showCustomerSignature = true;
        });
        return;
      }

      // Set processing state
      setState(() {
        isProcessingPayment = true;
        paymentInProgress = true;
        paymentSuccess = false;
        paymentErrorMessage = null;
      });

      try {
        LoadingDialog.show(context);

        final rentalId = selectedRentalId!;
        final damageCompensation =
            hasDamage ? double.parse(_damageCompensationController.text) : null;
        final damageDescription =
            hasDamage ? _damageDescriptionController.text : null;
        final lateFeeValue =
            isLateReturn ? double.parse(_lateFeeController.text) : null;
        final lateHoursValue = isLateReturn ? lateHours : null;

        // Handle different payment methods
        switch (paymentMethod) {
          case PaymentMethodConstants.vnpay:
            // Initialize VNPay payment with QR code
            final result = await _paymentService.initVNPayQRPayment(
              rentalId: rentalId,
              amount: amount,
              damageCompensation: damageCompensation,
              damageDescription: damageDescription,
              lateFee: lateFeeValue,
              lateHours: lateHoursValue,
              customerSignature: customerSignature,
            );

            if (mounted) LoadingDialog.hide(context);
            setState(() {
              isProcessingPayment = false;
              paymentInProgress = false;
            });

            // Navigate to VNPay QR Screen
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => VNPayQRScreen(
                        payment: result['payment'],
                        qrData: result['qrData'],
                      ),
                ),
              );
            }
            break;

          case PaymentMethodConstants.cash:
            // Process cash payment
            final payment = await _paymentService.addAndProcessPayment(
              rentalId: rentalId,
              paymentMethod: PaymentMethodConstants.cash,
              amount: amount,
              damageCompensation: damageCompensation,
              damageDescription: damageDescription,
              lateFee: lateFeeValue,
              lateHours: lateHoursValue,
              customerSignature: customerSignature,
            );

            if (mounted) LoadingDialog.hide(context);
            setState(() {
              isProcessingPayment = false;
              paymentInProgress = false;
              paymentSuccess =
                  payment.status == PaymentStatusConstants.completed;

              if (!paymentSuccess) {
                paymentErrorMessage = 'payment.payment_failed'.tr();
              }
            });

            if (mounted) {
              if (paymentSuccess) {
                // Hiển thị thông báo thành công ngắn gọn
                final snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'payment.payment_success'.tr(),
                    message: 'payment.payment_success_message'.tr(),
                    contentType: ContentType.success,
                  ),
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);

                // Chuyển về home screen
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              } else {
                final snackBar = SnackBar(
                  elevation: 0,
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.transparent,
                  content: AwesomeSnackbarContent(
                    title: 'payment.payment_failed'.tr(),
                    message:
                        paymentErrorMessage ??
                        'payment.payment_processing_error'.tr(),
                    contentType: ContentType.failure,
                  ),
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(snackBar);
              }
            }
            break;

          // Phương thức thẻ ngân hàng đã bị loại bỏ

          // Removed Ví điện tử case as it's now merged with VNPay

          default:
            if (mounted) LoadingDialog.hide(context);
            setState(() {
              isProcessingPayment = false;
              paymentInProgress = false;
            });

            if (mounted) {
              // Show error message for unsupported payment method
              final snackBar = SnackBar(
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'payment.unsupported_method'.tr(),
                  message: 'payment.method_not_supported'.tr(),
                  contentType: ContentType.warning,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            }
            break;
        }
      } catch (e) {
        if (mounted) LoadingDialog.hide(context);
        setState(() {
          isProcessingPayment = false;
          paymentInProgress = false;
          paymentSuccess = false;
          paymentErrorMessage = e.toString();
        });

        if (mounted) {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'common.error'.tr(),
              message: 'common.error_with_message'.tr(args: [e.toString()]),
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      }
    }
  }

  Widget _buildSignaturePad() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'payment.customer_signature'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Signature(
              key: _signatureKey,
              color: Colors.black,
              strokeWidth: 3.0,
              backgroundPainter: null,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: _clearSignature,
                icon: Icon(Icons.refresh),
                label: Text('payment.clear'.tr()),
              ),
              TextButton.icon(
                onPressed: _saveSignature,
                icon: Icon(Icons.check),
                label: Text('payment.save_signature'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paymentSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: paymentSuccess ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            paymentSuccess ? Icons.check_circle : Icons.error,
            color: paymentSuccess ? Colors.green : Colors.red,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            paymentSuccess
                ? 'payment.payment_success'.tr()
                : 'payment.payment_failed'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: paymentSuccess ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            paymentSuccess
                ? 'payment.thank_you_payment'.tr()
                : paymentErrorMessage ?? 'payment.payment_error'.tr(),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          if (paymentSuccess)
            ElevatedButton.icon(
              onPressed: () {
                // Reset form for new payment
                setState(() {
                  paymentSuccess = false;
                  paymentInProgress = false;
                  customerSignature = null;
                  _clearSignature();
                });
              },
              icon: Icon(Icons.refresh),
              label: Text('payment.create_new_payment'.tr()),
            )
          else
            ElevatedButton.icon(
              onPressed: _processPayment,
              icon: Icon(Icons.replay),
              label: Text('payment.try_again'.tr()),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'payment.customer_signature'.tr(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),

        if (customerSignature != null)
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child:
                      customerSignature!.startsWith('http')
                          ? Image.network(
                            customerSignature!,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                          )
                          : Image.memory(
                            Uri.parse(
                              customerSignature!,
                            ).data!.contentAsBytes(),
                            fit: BoxFit.contain,
                          ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        customerSignature = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _getSignature,
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.draw, size: 32, color: Colors.grey.shade600),
                    SizedBox(height: 8),
                    Text(
                      'payment.add_signature'.tr(),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'payment.add_payment'.tr(),
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            child:
                isLoading
                    ? Center(
                      child: AppLoadingIndicator(
                        color: theme.progressIndicatorTheme.color!,
                        size: 30,
                      ),
                    )
                    : rentals.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 80,
                            color: theme.dividerColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'payment.no_rentals_to_pay'.tr(),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                    : Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Card(
                            elevation: theme.cardTheme.elevation,
                            shape: theme.cardTheme.shape,
                            color: theme.cardTheme.color,
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (paymentInProgress &&
                                      !paymentSuccess &&
                                      paymentErrorMessage == null)
                                    Center(
                                      child: Column(
                                        children: [
                                          AppLoadingIndicator(
                                            color: theme.colorScheme.primary,
                                            size: 40,
                                            type:
                                                LoadingIndicatorType
                                                    .staggeredDotsWave,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'payment.processing_payment'.tr(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'payment.please_wait_processing'
                                                .tr(),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (paymentSuccess ||
                                      paymentErrorMessage != null)
                                    _buildPaymentStatus()
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'payment.payment_info'.tr(),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        SizedBox(height: 24),
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText:
                                                'payment.select_rental'.tr(),
                                            prefixIconColor:
                                                Theme.of(context).primaryColor,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.receipt_long,
                                            ),
                                          ),
                                          value: selectedRentalId,
                                          items:
                                              rentals.map((rental) {
                                                return DropdownMenuItem(
                                                  value: rental.id,
                                                  child: Text(
                                                    '${'rental.rental'.tr()} #${rental.id.substring(0, 8)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          Theme.of(
                                                            context,
                                                          ).colorScheme.primary,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              selectedRentalId = value;
                                              if (value != null) {
                                                _loadRentalDetails(value);
                                              }
                                            });
                                          },
                                          validator:
                                              (value) =>
                                                  value == null
                                                      ? 'payment.please_select_rental'
                                                          .tr()
                                                      : null,
                                        ),
                                        SizedBox(height: 16),
                                        // Workflow mới: Luôn hiển thị field phí thuê cơ bản
                                        CustomTextFormField(
                                          controller: _amountController,
                                          label: 'payment.base_amount'.tr(),
                                          prefixIcon: Icons.attach_money,
                                          keyboardType: TextInputType.number,
                                          onChanged: (val) {
                                            _updateTotalAmount();
                                          },
                                          validator: (val) {
                                            if (val == null || val.isEmpty) {
                                              return 'payment.please_enter_amount'
                                                  .tr();
                                            }
                                            if (double.tryParse(val) == null ||
                                                double.parse(val) <= 0) {
                                              return 'payment.invalid_amount'
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),

                                        // Phần kiểm tra hư hại (luôn hiển thị trong workflow mới)
                                        SizedBox(height: 16),
                                        SwitchListTile(
                                          title: Text(
                                            'payment.has_damage'.tr(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'payment.damage_compensation_subtitle'
                                                .tr(),
                                          ),
                                          value: hasDamage,
                                          activeColor: Colors.red,
                                          onChanged: (bool value) {
                                            setState(() {
                                              hasDamage = value;
                                              _updateTotalAmount();
                                            });
                                          },
                                        ),
                                        if (isLateReturn) ...[
                                          SizedBox(height: 16),
                                          Container(
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.orange
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors.orange,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'payment.late_fee'.tr(),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  '${'payment.late_hours'.tr()}: $lateHours ${'payment.hours'.tr()}',
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'payment.late_fee_rules'.tr(),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  'payment.late_fee_rule1'.tr(),
                                                ),
                                                Text(
                                                  'payment.late_fee_rule2'.tr(),
                                                ),
                                                Text(
                                                  'payment.late_fee_rule3'.tr(),
                                                ),
                                                SizedBox(height: 8),
                                                CustomTextFormField(
                                                  controller:
                                                      _lateFeeController,
                                                  label:
                                                      'payment.late_fee'.tr(),
                                                  prefixIcon: Icons.timer_off,
                                                  suffixIcon: Text('VND'),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  onChanged: (val) {
                                                    _updateTotalAmount();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (hasDamage) ...[
                                          SizedBox(height: 12),
                                          CustomTextFormField(
                                            controller:
                                                _damageCompensationController,
                                            label:
                                                'payment.damage_compensation'
                                                    .tr(),
                                            prefixIcon: Icons.healing,
                                            suffixIcon: Text('VND'),
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) {
                                              _updateTotalAmount();
                                            },
                                            validator: (val) {
                                              if (hasDamage) {
                                                if (val == null ||
                                                    val.isEmpty) {
                                                  return 'payment.please_enter_compensation'
                                                      .tr();
                                                }
                                                if (double.tryParse(val) ==
                                                    null) {
                                                  return 'payment.invalid_compensation'
                                                      .tr();
                                                }
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 12),
                                          CustomTextFormField(
                                            controller:
                                                _damageDescriptionController,
                                            label:
                                                'payment.damage_description'
                                                    .tr(),
                                            prefixIcon: Icons.description,
                                            maxLines: 3,
                                            validator: (val) {
                                              if (hasDamage &&
                                                  (val == null ||
                                                      val.isEmpty)) {
                                                return 'payment.please_describe_damage'
                                                    .tr();
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${'payment.total'.tr()}:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                '${amount.toStringAsFixed(0)} ₫',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            labelText:
                                                'payment.payment_method'.tr(),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                width: 2,
                                              ),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.payment,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                          value: paymentMethod,
                                          items:
                                              PaymentMethodConstants.getAllMethods()
                                                  .map<
                                                    DropdownMenuItem<String>
                                                  >((method) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: method,
                                                      child: Text(
                                                        _getPaymentMethodTranslation(
                                                          method,
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              theme
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                    );
                                                  })
                                                  .toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              paymentMethod = value!;
                                            });
                                          },
                                        ),

                                        _buildCustomerSignatureSection(),

                                        SizedBox(height: 32),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: ElevatedButton(
                                            style:
                                                isProcessingPayment
                                                    ? theme
                                                        .elevatedButtonTheme
                                                        .style
                                                        ?.copyWith(
                                                          backgroundColor:
                                                              MaterialStateProperty.all(
                                                                Colors.grey,
                                                              ),
                                                        )
                                                    : theme
                                                        .elevatedButtonTheme
                                                        .style,
                                            onPressed:
                                                isProcessingPayment
                                                    ? null
                                                    : _processPayment,
                                            child:
                                                isProcessingPayment
                                                    ? Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        AppLoadingIndicator(
                                                          color: Colors.black,
                                                          size: 20,
                                                          type:
                                                              LoadingIndicatorType
                                                                  .staggeredDotsWave,
                                                        ),
                                                        SizedBox(width: 12),
                                                        Text(
                                                          'common.processing'
                                                              .tr(),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                    : Text(
                                                      'payment.process_payment'
                                                          .tr(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
          ),

          if (showCustomerSignature)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'payment.signature_confirmation'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildSignaturePad(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                showCustomerSignature = false;
                              });
                            },
                            icon: Icon(Icons.cancel),
                            label: Text('common.cancel'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _saveSignature,
                            icon: Icon(Icons.check),
                            label: Text('common.confirm'.tr()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
