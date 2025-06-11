import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  PaymentDetailScreenState createState() => PaymentDetailScreenState();
}

class PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final RentalService _rentalService = RentalService();
  final UserService _userService = UserService();
  final BikeService _bikeService = BikeService();

  bool isLoading = true;
  Rental? rental;
  String userName = '';
  String bikeName = '';

  String _getPaymentMethodTranslation(String method) {
    if (method == PaymentMethodConstants.cash) {
      return 'payment.cash'.tr();
    } else if (method == PaymentMethodConstants.vnpay) {
      return 'payment.vnpay'.tr();
    }
    return method;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Lấy thông tin đơn thuê
      rental = await _rentalService.getRentalById(widget.payment.rentalId);

      // Lấy thông tin người dùng
      final user = await _userService.getUserById(rental!.userId);
      if (user != null) {
        userName = user.name;
      }

      // Lấy thông tin xe
      final bike = await _bikeService.getBikeById(rental!.bikeId);
      bikeName = bike.name;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'payment.load_error'.tr()}: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'payment.payment_details'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(51),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body:
          isLoading
              ? Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              )
              : rental == null
              ? Center(child: Text('rental.not_found'.tr()))
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentInfoCard(theme),
                    SizedBox(height: 16),
                    _buildRentalInfoCard(theme),
                    SizedBox(height: 16),
                    if (widget.payment.damageCompensation != null) ...[
                      _buildDamageInfoCard(theme),
                      SizedBox(height: 16),
                    ],
                    if (widget.payment.lateFee != null) ...[
                      _buildLateFeeInfoCard(theme),
                      SizedBox(height: 16),
                    ],
                    _buildTotalAmountCard(theme),
                  ],
                ),
              ),
    );
  }

  Widget _buildPaymentInfoCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'payment.payment_info'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.payment.status).withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(widget.payment.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.payment.status,
                    style: TextStyle(
                      color: _getStatusColor(widget.payment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow(
              'payment.payment_id'.tr(),
              '#${widget.payment.id.substring(0, 8)}',
            ),
            _buildInfoRow(
              'payment.method'.tr(),
              _getPaymentMethodTranslation(widget.payment.paymentMethod),
            ),
            _buildInfoRow(
              'payment.payment_date'.tr(),
              DateFormat('dd/MM/yyyy HH:mm').format(widget.payment.paymentDate),
            ),
            _buildInfoRow('payment.customer'.tr(), userName),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalInfoCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment.rental_info'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 24),
            _buildInfoRow(
              'payment.rental_id'.tr(),
              '#${rental!.id.substring(0, 8)}',
            ),
            _buildInfoRow('payment.rental_bike'.tr(), bikeName),
            _buildInfoRow('payment.quantity'.tr(), rental!.quantity.toString()),
            _buildInfoRow(
              'payment.start_time'.tr(),
              DateFormat('dd/MM/yyyy HH:mm').format(rental!.startTime),
            ),
            _buildInfoRow(
              'payment.end_time'.tr(),
              DateFormat('dd/MM/yyyy HH:mm').format(rental!.endTime),
            ),
            if (rental!.returnedDate != null)
              _buildInfoRow(
                'payment.return_time'.tr(),
                DateFormat('dd/MM/yyyy HH:mm').format(rental!.returnedDate!),
              ),
            if (rental!.cancelledAt != null)
              _buildInfoRow(
                'payment.cancel_time'.tr(),
                DateFormat('dd/MM/yyyy HH:mm').format(rental!.cancelledAt!),
              ),
            _buildInfoRow(
              'payment.base_rental_fee'.tr(),
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
              ).format(rental!.totalAmount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDamageInfoCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'payment.damage_info'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow(
              'payment.damage_compensation'.tr(),
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
              ).format(widget.payment.damageCompensation),
            ),
            _buildInfoRow(
              'payment.damage_description'.tr(),
              widget.payment.damageDescription ?? '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLateFeeInfoCard(ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer_off, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'payment.late_fee_info'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow(
              'payment.late_hours'.tr(),
              '${widget.payment.lateHours} ${'payment.hours'.tr()}',
            ),
            _buildInfoRow(
              'payment.late_fee'.tr(),
              NumberFormat.currency(
                locale: 'vi_VN',
                symbol: 'đ',
              ).format(widget.payment.lateFee),
            ),
            SizedBox(height: 8),
            Text(
              'payment.late_fee_rules'.tr(),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('payment.late_fee_rule1'.tr()),
            Text('payment.late_fee_rule2'.tr()),
            Text('payment.late_fee_rule3'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(ThemeData theme) {
    return Card(
      elevation: 3,
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'payment.total_payment'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            Divider(
              height: 24,
              color: theme.colorScheme.onPrimary.withAlpha(128),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'payment.base_rental_fee'.tr()}:',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                  ).format(rental!.totalAmount),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (widget.payment.damageCompensation != null) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'payment.damage_compensation'.tr()}:',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    ).format(widget.payment.damageCompensation),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (widget.payment.lateFee != null) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'payment.late_fee'.tr()}:',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    ).format(widget.payment.lateFee),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            Divider(
              height: 24,
              color: theme.colorScheme.onPrimary.withAlpha(128),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'payment.total'.tr()}:',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: 'đ',
                  ).format(widget.payment.amount),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(179),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case PaymentStatusConstants.completed:
        return Colors.green;
      case PaymentStatusConstants.pending:
        return Colors.orange;
      case PaymentStatusConstants.failed:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
