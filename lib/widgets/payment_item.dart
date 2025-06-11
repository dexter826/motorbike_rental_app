// ignore_for_file: deprecated_member_use

import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/screens/payment/payment_detail_screen.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';

class PaymentItem extends StatefulWidget {
  final Payment payment;
  final Function? onRefresh;

  const PaymentItem({super.key, required this.payment, this.onRefresh});

  @override
  State<PaymentItem> createState() => _PaymentItemState();
}

class _PaymentItemState extends State<PaymentItem> {
  final RentalService _rentalService = RentalService();
  String rentalInfo = '';
  bool isLoading = true;

  String _getPaymentMethodTranslation(String method) {
    if (method == PaymentMethodConstants.cash) {
      return 'payment.cash'.tr();
    } else if (method == PaymentMethodConstants.vnpay) {
      return 'payment.vnpay'.tr();
    }
    return method;
  }

  String _getStatusTranslation(String status) {
    switch (status) {
      case PaymentStatusConstants.completed:
        return 'payment.completed'.tr();
      case PaymentStatusConstants.processing:
        return 'payment.processing'.tr();
      case PaymentStatusConstants.pending:
        return 'payment.pending'.tr();
      case PaymentStatusConstants.failed:
        return 'payment.failed'.tr();
      case PaymentStatusConstants.refunded:
        return 'payment.refunded'.tr();
      case PaymentStatusConstants.cancelled:
        return 'payment.cancelled'.tr();
      default:
        return status;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRentalInfo();
  }

  Future<void> _loadRentalInfo() async {
    try {
      final rental = await _rentalService.getRentalById(
        widget.payment.rentalId,
      );
      setState(() {
        rentalInfo = '${'rental.rental_id'.tr()} #${rental.id.substring(0, 8)}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        rentalInfo = 'rental.load_error'.tr();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentDetailScreen(payment: widget.payment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'payment.payment'.tr()} #${widget.payment.id.substring(0, 8)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatAmount(widget.payment.amount, widget.payment.status),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getStatusColor(widget.payment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              isLoading
                  ? Center(
                    child: SizedBox(
                      height: 30,
                      child: AppLoadingIndicator(
                        color: theme.colorScheme.primary,
                        size: 20,
                        type: LoadingIndicatorType.circularProgress,
                      ),
                    ),
                  )
                  : _buildInfoRow('rental.rental'.tr(), rentalInfo),
              _buildInfoRow(
                'payment.method'.tr(),
                _getPaymentMethodTranslation(widget.payment.paymentMethod),
              ),
              _buildInfoRow(
                'payment.status'.tr(),
                _getStatusTranslation(widget.payment.status),
                statusColor: _getStatusColor(widget.payment.status),
              ),
              _buildInfoRow(
                'payment.payment_date'.tr(),
                DateFormat(
                  'dd/MM/yyyy HH:mm',
                ).format(widget.payment.paymentDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor, // Apply status color if provided
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format amount based on payment status
  String _formatAmount(double amount, String status) {
    final formattedAmount = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    ).format(amount);

    // Show "+" for completed payments (successful transactions)
    if (status == 'Completed') {
      return '+$formattedAmount';
    }

    return formattedAmount;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case PaymentStatusConstants.completed:
        return Colors.green;
      case PaymentStatusConstants.processing:
        return Colors.blue;
      case PaymentStatusConstants.pending:
        return Colors.orange;
      case PaymentStatusConstants.failed:
        return Colors.red;
      case PaymentStatusConstants.refunded:
        return Colors.purple;
      case PaymentStatusConstants.cancelled:
        return Colors.grey[600] ?? Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
