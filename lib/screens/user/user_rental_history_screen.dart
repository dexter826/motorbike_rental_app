import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/user.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class UserRentalHistoryScreen extends StatefulWidget {
  final User user;

  const UserRentalHistoryScreen({super.key, required this.user});

  @override
  _UserRentalHistoryScreenState createState() =>
      _UserRentalHistoryScreenState();
}

class _UserRentalHistoryScreenState extends State<UserRentalHistoryScreen> {
  final RentalService _rentalService = RentalService();
  bool isLoading = true;
  List<Map<String, dynamic>> rentals = [];

  @override
  void initState() {
    super.initState();
    _loadRentalHistory();
  }

  Future<void> _loadRentalHistory() async {
    try {
      final userRentals = await _rentalService.getUserRentals(widget.user.id);
      setState(() {
        rentals = userRentals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'common.error'.tr(),
          message: 'rental.history_load_error'.tr(),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  String _getStatusText(String status) {
    return 'rental.${status.toLowerCase()}'.tr();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case RentalStatusConstants.ongoing:
        return Colors.orange;
      case RentalStatusConstants.completed:
        return Colors.green;
      case RentalStatusConstants.expired:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'rental.rental_history'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.primary.withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.colorScheme.primary,
                  size: 40,
                ),
              )
              : rentals.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_outlined,
                      size: 80,
                      color: theme.colorScheme.outline,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'rental.no_rental_history'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadRentalHistory,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: rentals.length,
                  itemBuilder: (context, index) {
                    final rental = rentals[index];
                    return AnimationHelper.fadeInUp(
                      duration: Duration(milliseconds: 500),
                      delay: Duration(milliseconds: index * 100),
                      child: Card(
                        elevation: 3,
                        margin: EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${'rental.rental_id'.tr()}: #${rental['id']}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        rental['status'],
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          rental['status'],
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusText(rental['status']),
                                      style: TextStyle(
                                        color: _getStatusColor(
                                          rental['status'],
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    'rental.rental_bike'.tr(),
                                    rental['bikeId'] ?? 'common.unknown'.tr(),
                                    Icons.motorcycle,
                                    theme,
                                  ),
                                  _buildInfoRow(
                                    'rental.start_time'.tr(),
                                    DateFormat('dd/MM/yyyy HH:mm').format(
                                      (rental['startTime'] as Timestamp)
                                          .toDate(),
                                    ),
                                    Icons.access_time,
                                    theme,
                                  ),
                                  _buildInfoRow(
                                    'rental.end_time'.tr(),
                                    rental['endTime'] != null
                                        ? DateFormat('dd/MM/yyyy HH:mm').format(
                                          (rental['endTime'] as Timestamp)
                                              .toDate(),
                                        )
                                        : 'rental.not_ended'.tr(),
                                    Icons.access_time_filled,
                                    theme,
                                  ),
                                  _buildInfoRow(
                                    'rental.return_date'.tr(),
                                    rental['returnedDate'] != null
                                        ? DateFormat('dd/MM/yyyy').format(
                                          (rental['returnedDate'] as Timestamp)
                                              .toDate(),
                                        )
                                        : 'rental.not_ended'.tr(),
                                    Icons.calendar_today,
                                    theme,
                                  ),
                                  _buildInfoRow(
                                    'rental.total_price'.tr(),
                                    NumberFormat.currency(
                                      locale: context.locale.toString(),
                                      symbol:
                                          context.locale.languageCode == 'en'
                                              ? r'$'
                                              : '₫',
                                      decimalDigits: 0,
                                    ).format(rental['totalAmount'] ?? 0),
                                    Icons.attach_money,
                                    theme,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.outline),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
