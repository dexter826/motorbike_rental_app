import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/services/payment_service.dart';

import 'package:bike_rental_app/services/notification_service.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VNPayQRScreen extends StatefulWidget {
  final Payment payment;
  final Map<String, dynamic> qrData;

  const VNPayQRScreen({super.key, required this.payment, required this.qrData});

  @override
  State<VNPayQRScreen> createState() => _VNPayQRScreenState();
}

class _VNPayQRScreenState extends State<VNPayQRScreen> {
  late Timer _timer;
  late DateTime _expiryTime;
  Duration _timeLeft = Duration.zero;
  StreamSubscription<DocumentSnapshot>? _paymentListener;

  @override
  void initState() {
    super.initState();
    _expiryTime = widget.qrData['expiryTime'] as DateTime;
    _updateTimeLeft();

    // Register this payment for notification
    NotificationService.registerPendingPayment(
      paymentId: widget.payment.id,
      rentalId: widget.payment.rentalId,
      amount: widget.payment.amount,
    );

    // Start timer to update countdown only
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });

    // Listen to Firestore changes for real-time payment status
    _setupFirestoreListener();
  }

  // Setup Firestore listener for real-time payment updates
  void _setupFirestoreListener() {
    try {
      _paymentListener = FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.payment.id)
          .snapshots()
          .listen((DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              final data = snapshot.data() as Map<String, dynamic>?;
              if (data != null &&
                  data['status'] == PaymentStatusConstants.completed) {
                // Payment completed, trigger notification
                _handlePaymentSuccess(data);
              }
            }
          });
    } catch (e) {
      print('Error setting up Firestore listener: $e');
      // Fallback to periodic checking if Firestore fails
      _setupFallbackChecking();
    }
  }

  // Fallback checking when Firestore listener fails
  void _setupFallbackChecking() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _checkPaymentStatusFallback();
    });
  }

  // Handle payment success from Firestore
  Future<void> _handlePaymentSuccess(Map<String, dynamic> paymentData) async {
    try {
      // Cancel timer and listener
      _timer.cancel();
      _paymentListener?.cancel();

      // Process the successful payment to update rental status
      await _processSuccessfulPayment();

      // Show success notification immediately
      await _showPaymentSuccessNotification();

      // Auto-complete the payment flow
      await _autoCompletePayment();
    } catch (e) {
      print('Error handling payment success: $e');
    }
  }

  // Process successful payment to update rental status
  Future<void> _processSuccessfulPayment() async {
    try {
      final paymentService = PaymentService();

      // Get current payment and handle successful payment
      // This will update rental status and send emails
      final payment = await paymentService.getPaymentById(widget.payment.id);
      await paymentService.handleSuccessfulPayment(payment);
    } catch (e) {
      print('Error processing successful payment: $e');
      // Don't block the flow if this fails
    }
  }

  // Show payment success notification
  Future<void> _showPaymentSuccessNotification() async {
    try {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.payment_success_snackbar_title'.tr(),
          message: 'notification.payment_success_snackbar_message'.tr(
            args: [widget.payment.amount.toStringAsFixed(0)],
          ),
          contentType: ContentType.success,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }

      // Also trigger local notification for staff
      final notificationService = NotificationService();
      await notificationService.showPaymentSuccessNotification(
        paymentId: widget.payment.id,
        rentalId: widget.payment.rentalId,
        amount: widget.payment.amount,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      print('Error showing payment success notification: $e');
    }
  }

  // Auto-complete payment and navigate home
  Future<void> _autoCompletePayment() async {
    try {
      // Wait a moment for user to see the success message
      await Future.delayed(Duration(seconds: 3));

      if (mounted) {
        // Navigate back to home
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      print('Error in auto-complete payment: $e');
    }
  }

  // Fallback payment status checking
  Future<void> _checkPaymentStatusFallback() async {
    try {
      final paymentService = PaymentService();
      final payment = await paymentService.getPaymentById(widget.payment.id);

      if (payment.status == PaymentStatusConstants.completed) {
        await _handlePaymentSuccess({});
      }
    } catch (e) {
      // Silently handle errors in fallback checking
    }
  }

  // Handle payment cancellation - delete payment record and keep rental in original status
  Future<void> _handleCancelPayment() async {
    try {
      // Show confirmation dialog
      final bool? shouldCancel = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('payment.cancel_payment_title'.tr()),
            content: Text('payment.cancel_payment_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('common.no'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('common.yes'.tr()),
              ),
            ],
          );
        },
      );

      if (shouldCancel == true) {
        // Cancel timers and listeners
        _timer.cancel();
        _paymentListener?.cancel();

        // Delete the payment record entirely
        await _deletePaymentRecord();

        // Show cancellation message
        if (mounted) {
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'payment.payment_cancelled'.tr(),
              message: 'payment.payment_cancelled_message'.tr(),
              contentType: ContentType.warning,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);

          // Navigate back after showing message
          await Future.delayed(Duration(seconds: 1));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('Error handling payment cancellation: $e');
      // Still navigate back even if cancellation fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Delete payment record from database
  Future<void> _deletePaymentRecord() async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(widget.payment.id)
          .delete();

      print('Payment record deleted: ${widget.payment.id}');
    } catch (e) {
      print('Error deleting payment record: $e');
      throw e;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _paymentListener?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    if (_expiryTime.isAfter(now)) {
      setState(() {
        _timeLeft = _expiryTime.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = Duration.zero;
      });
      _timer.cancel();
    }
  }

  String _formatTimeLeft() {
    final minutes = _timeLeft.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _timeLeft.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('payment.vnpay_payment'.tr())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // QR Code section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'payment.scan_qr_to_pay'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'payment.use_banking_app'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: widget.qrData['qrContent'] as String,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    SizedBox(height: 16),

                    // Timer
                    _timeLeft.inSeconds > 0
                        ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.orange),
                            SizedBox(width: 8),
                            Text(
                              'payment.qr_expires_in'.tr(
                                namedArgs: {'time': _formatTimeLeft()},
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          'payment.qr_expired'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Payment details
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'payment.payment_details_title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    _buildInfoRow(
                      'payment.rental_id'.tr(),
                      '#${widget.payment.rentalId.substring(0, 8)}',
                    ),
                    _buildInfoRow(
                      'payment.amount'.tr(),
                      formatCurrency.format(widget.payment.amount),
                    ),
                    _buildInfoRow(
                      'payment.method'.tr(),
                      widget.payment.paymentMethod,
                    ),
                    _buildInfoRow(
                      'payment.merchant'.tr(),
                      widget.qrData['merchantName'] as String,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Action buttons
            Column(
              children: [
                // Status indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'payment.waiting_for_payment'.tr(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleCancelPayment(),
                    icon: Icon(Icons.cancel),
                    label: Text('payment.cancel_payment'.tr()),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
