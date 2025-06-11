import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import '../../models/bike.dart';
import '../../models/rental.dart';
import '../../models/user.dart';
import '../../services/bike_service.dart';
import '../../services/rental_service.dart';
import '../../services/user_service.dart';
import '../payment/create_payment_screen.dart';
import 'map/bike_location_map_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class RentalDetailScreen extends StatefulWidget {
  final String rentalId;

  const RentalDetailScreen({super.key, required this.rentalId});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  final RentalService _rentalService = RentalService();
  final BikeService _bikeService = BikeService();
  final UserService _userService = UserService();
  bool _isLoading = true;
  Rental? _rental;
  Bike? _bike;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadRentalDetails();
  }

  Future<void> _loadRentalDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rental = await _rentalService.getRentalById(widget.rentalId);
      final bike = await _bikeService.getBikeById(rental.bikeId);
      final user = await _userService.getUserById(rental.userId);

      setState(() {
        _rental = rental;
        _bike = bike;
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            contentType: ContentType.failure,
            title: 'common.error'.tr(),
            message: 'rental.load_error'.tr(),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('rental.rental_details'.tr()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.primaryColor.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _rental == null
              ? Center(child: Text('rental.not_found'.tr()))
              : RefreshIndicator(
                onRefresh: _loadRentalDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${'rental.rentals'.tr()} #${_rental!.id.substring(0, 8)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      _rental!.status,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'rental.${_rental!.status.toLowerCase()}'
                                        .tr(),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: _getStatusColor(_rental!.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            // Thông tin xe máy
                            Text(
                              'rental.bike_info'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'bike.bike_name'.tr(),
                              _bike?.name ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'bike.license_plate'.tr(),
                              _bike?.licensePlate ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'bike.bike_type'.tr(),
                              _bike?.type ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'bike.bike_price'.tr(),
                              _bike != null
                                  ? NumberFormat.currency(
                                    locale: 'vi_VN',
                                    symbol: 'đ',
                                  ).format(_bike!.price)
                                  : 'common.loading'.tr(),
                            ),

                            const Divider(height: 24),

                            // Thông tin người thuê
                            Text(
                              'rental.customer_info'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'rental.customer_name'.tr(),
                              _user?.name ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'rental.phone'.tr(),
                              _user?.phone ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'rental.email'.tr(),
                              _user?.email ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'rental.address'.tr(),
                              _user?.address ?? 'common.loading'.tr(),
                            ),
                            _buildInfoRow(
                              'rental.id_card'.tr(),
                              _user?.idCard ?? 'common.loading'.tr(),
                            ),

                            const Divider(height: 24),

                            // Thông tin đơn thuê
                            Text(
                              'rental.rental_info'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'rental.quantity'.tr(),
                              _rental!.quantity.toString(),
                            ),
                            _buildInfoRow(
                              'rental.created_at'.tr(),
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_rental!.createdAt),
                            ),
                            _buildInfoRow(
                              'rental.total_price'.tr(),
                              NumberFormat.currency(
                                locale: context.locale.toString(),
                                symbol: 'đ',
                              ).format(_rental!.totalAmount),
                            ),
                            _buildInfoRow(
                              'rental.start_time'.tr(),
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(_rental!.startTime),
                            ),
                            _buildInfoRow(
                              'rental.end_time'.tr(),
                              DateFormat('dd/MM/yyyy').format(_rental!.endTime),
                            ),
                            if (_rental!.returnedDate != null)
                              _buildInfoRow(
                                'rental.return_date'.tr(),
                                DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_rental!.returnedDate!),
                              ),
                            // Workflow mới: Không có prepayment
                            // Hiển thị buttons dựa trên trạng thái
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Xây dựng buttons dựa trên trạng thái rental
  Widget _buildActionButtons() {
    if (_rental == null) return const SizedBox.shrink();

    final status = _rental!.status;

    if (status == RentalStatusConstants.ongoing) {
      return _buildOngoingButtons();
    } else if (status == RentalStatusConstants.expired) {
      return _buildExpiredButtons();
    } else if (status == RentalStatusConstants.completed) {
      return _buildCompletedButtons();
    } else {
      return const SizedBox.shrink();
    }
  }

  // Buttons cho trạng thái Ongoing
  Widget _buildOngoingButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.location_on, size: 20),
              label: Text('rental.locate'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              BikeLocationMapScreen(bikeId: _rental!.bikeId),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.payment, size: 20),
              label: Text('rental.make_payment'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => CreatePaymentScreen(rentalId: _rental!.id),
                    ),
                  ).then((_) => _loadRentalDetails()),
            ),
          ),
        ],
      ),
    );
  }

  // Buttons cho trạng thái Expired
  Widget _buildExpiredButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.payment, size: 20),
        label: Text('rental.pay_and_return'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size.fromHeight(50),
        ),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePaymentScreen(rentalId: _rental!.id),
              ),
            ).then((_) => _loadRentalDetails()),
      ),
    );
  }

  // Buttons cho trạng thái Completed
  Widget _buildCompletedButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'rental.rental_completed'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
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
