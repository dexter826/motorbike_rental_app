// ignore_for_file: deprecated_member_use

import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/screens/payment/create_payment_screen.dart';
import 'package:bike_rental_app/screens/rental/create_rental_screen.dart';
import 'package:bike_rental_app/screens/rental/map/bike_location_map_screen.dart';
import 'package:bike_rental_app/screens/rental/rental_detail_screen.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class RentalItem extends StatefulWidget {
  final Rental rental;
  final Function? onRefresh;

  const RentalItem({super.key, required this.rental, this.onRefresh});

  @override
  State<RentalItem> createState() => _RentalItemState();
}

class _RentalItemState extends State<RentalItem> {
  final UserService _userService = UserService();
  final BikeService _bikeService = BikeService();

  String _userName = '';
  String _bikeName = '';
  String _licensePlate = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Lấy thông tin người dùng
      final user = await _userService.getUserById(widget.rental.userId);
      // Lấy thông tin xe máy
      final bike = await _bikeService.getBikeById(widget.rental.bikeId);

      if (mounted) {
        setState(() {
          _userName = user?.name ?? 'common.unknown'.tr();
          _bikeName = bike.name;
          _licensePlate = bike.licensePlate;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'common.load_error'.tr();
          _bikeName = 'common.load_error'.tr();
          _licensePlate = 'common.load_error'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.cardColor, theme.cardColor.withOpacity(0.9)],
          ),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${'rental.rental'.tr()} #${widget.rental.id.substring(0, 8)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          widget.rental.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTranslatedStatus(widget.rental.status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _getStatusColor(widget.rental.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Main information section with glass morphism effect
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top row with bike info and user
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column - Bike info with icon
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.motorcycle,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _bikeName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _licensePlate,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Right column - User info with icon
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'rental.renter'.tr(),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Divider(height: 24, thickness: 0.5),

                      // Bottom row with dates and price
                      Row(
                        children: [
                          // Left column - Rental dates with icon
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.date_range,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'dd/MM/yyyy',
                                        ).format(widget.rental.startTime),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${'rental.to'.tr()} ${DateFormat('dd/MM/yyyy').format(widget.rental.endTime)}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right column - Price with emphasis
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 16,
                                  color: theme.primaryColor,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  NumberFormat.currency(
                                    locale: 'vi_VN',
                                    symbol: '₫',
                                    decimalDigits: 0,
                                  ).format(widget.rental.totalAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons section
                if (_shouldShowActionButtons())
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: _buildActionButtons(theme),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalDetailScreen(rentalId: widget.rental.id),
      ),
    );
  }

  // Kiểm tra xem có nên hiển thị action buttons hay không
  bool _shouldShowActionButtons() {
    final status = widget.rental.status;
    return status == RentalStatusConstants.ongoing ||
        status == RentalStatusConstants.expired;
  }

  // Xây dựng action buttons dựa trên status
  Widget _buildActionButtons(ThemeData theme) {
    final status = widget.rental.status;

    if (status == RentalStatusConstants.ongoing) {
      return _buildOngoingButtons(theme);
    } else if (status == RentalStatusConstants.expired) {
      return _buildExpiredButtons(theme);
    } else {
      return const SizedBox.shrink();
    }
  }

  // Buttons cho status Ongoing
  Widget _buildOngoingButtons(ThemeData theme) {
    return Column(
      children: [
        // Hàng 1: Location button - chiếm 100% width
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.location_on, size: 16),
            label: Text('rental.locate'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BikeLocationMapScreen(bikeId: widget.rental.bikeId),
                  ),
                ),
          ),
        ),

        const SizedBox(height: 8),

        // Hàng 2: Extension và Return buttons - chia đều 50% width
        Row(
          children: [
            // Extension button - 50% width, bên trái
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.schedule, size: 16),
                label: Text('rental.extend'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CreateRentalScreen(
                              bikeId: widget.rental.bikeId,
                              userId: widget.rental.userId,
                              isExtension: true,
                              existingRental: widget.rental,
                            ),
                      ),
                    ).then((_) {
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    }),
              ),
            ),

            const SizedBox(width: 8),

            // Return bike button - 50% width, bên phải
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assignment_return, size: 16),
                label: Text('rental.return_bike'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                CreatePaymentScreen(rentalId: widget.rental.id),
                      ),
                    ).then((_) {
                      if (widget.onRefresh != null) {
                        widget.onRefresh!();
                      }
                    }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Buttons cho status Expired
  Widget _buildExpiredButtons(ThemeData theme) {
    // Cho expired rental, hiển thị cả button gia hạn và trả xe
    return Row(
      children: [
        // Extension button - 50% width, bên trái
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.schedule, size: 16),
            label: Text('rental.extend'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => CreateRentalScreen(
                          bikeId: widget.rental.bikeId,
                          userId: widget.rental.userId,
                          isExtension: true,
                          existingRental: widget.rental,
                        ),
                  ),
                ).then((_) {
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                }),
          ),
        ),

        const SizedBox(width: 8),

        // Return bike button - 50% width, bên phải, màu đỏ để nhấn mạnh quá hạn
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.assignment_return, size: 16),
            label: Text('rental.return_bike'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CreatePaymentScreen(rentalId: widget.rental.id),
                  ),
                ).then((_) {
                  if (widget.onRefresh != null) {
                    widget.onRefresh!();
                  }
                  // Reload details để cập nhật payment status
                  _loadDetails();
                }),
          ),
        ),
      ],
    );
  }

  // Get translated status for display
  String _getTranslatedStatus(String status) {
    return 'rental.${status.toLowerCase()}'.tr();
  }

  Color _getStatusColor(String status) {
    if (status == RentalStatusConstants.ongoing) {
      return Colors.orange;
    } else if (status == RentalStatusConstants.completed) {
      return Colors.green;
    } else if (status == RentalStatusConstants.expired) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }
}
