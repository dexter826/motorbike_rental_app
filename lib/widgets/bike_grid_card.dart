// ignore_for_file: deprecated_member_use

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/screens/bike/bike_details_screen.dart';
import 'package:bike_rental_app/screens/bike/manage_bike_screen.dart';
import 'package:bike_rental_app/screens/user/user_list_screen.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BikeGridCard extends StatefulWidget {
  final Bike bike;
  final Function? onBikeUpdated;

  const BikeGridCard({super.key, required this.bike, this.onBikeUpdated});

  @override
  State<BikeGridCard> createState() => _BikeGridCardState();
}

class _BikeGridCardState extends State<BikeGridCard> {
  late final NumberFormat currencyFormat;

  @override
  void initState() {
    super.initState();
    _isAdmin = _authService.isAdmin;
    currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  }

  final BrandService _brandService = BrandService();
  final BikeService _bikeService = BikeService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isAdmin = _authService.isAdmin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final bool isAvailableForRent = BikeStatusConstants.canRent(
      widget.bike.status,
      widget.bike.quantity,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: InkWell(
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            onTap: () => _navigateToBikeDetails(),
            child: AspectRatio(
              aspectRatio: isLandscape ? 1.5 : 0.75,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phần hình ảnh
                  Expanded(
                    flex: isLandscape ? 6 : 7,
                    child: _buildImageSection(theme, isLandscape),
                  ),
                  // Phần thông tin và nút hành động
                  Expanded(
                    flex: isLandscape ? 4 : 5,
                    child: _buildInfoSection(
                      theme,
                      isAvailableForRent,
                      isLandscape,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Phần hình ảnh và các badge
  Widget _buildImageSection(ThemeData theme, bool isLandscape) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hình ảnh xe
        _buildBikeImage(theme),

        // Badge trạng thái
        Positioned(
          top: 8,
          right: 8,
          child: _buildStatusBadge(widget.bike.status),
        ),

        // Badge thương hiệu
        Positioned(top: 8, left: 8, child: _buildBrandBadge(theme)),

        // Gradient overlay và giá
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildPriceOverlay(theme),
        ),
      ],
    );
  }

  // Hình ảnh xe với Hero animation
  Widget _buildBikeImage(ThemeData theme) {
    return Hero(
      tag: 'bike-${widget.bike.id}',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        child:
            widget.bike.imageUrl == null || widget.bike.imageUrl!.isEmpty
                ? _buildPlaceholderImage(theme)
                : _buildNetworkImage(theme),
      ),
    );
  }

  // Placeholder khi không có hình ảnh
  Widget _buildPlaceholderImage(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.motorcycle_outlined,
        size: 40,
        color: theme.colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  // Hiển thị hình ảnh từ network với cache
  Widget _buildNetworkImage(ThemeData theme) {
    return CachedNetworkImage(
      imageUrl: widget.bike.imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder:
          (context, url) => Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 2,
            ),
          ),
      errorWidget:
          (context, url, error) => Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 30,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
          ),
    );
  }

  // Badge hiển thị thương hiệu
  Widget _buildBrandBadge(ThemeData theme) {
    return FutureBuilder<Brand?>(
      future: _brandService.getBrandById(widget.bike.brandId),
      builder: (context, snapshot) {
        String brandName = '';
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data != null) {
          brandName = snapshot.data!.name;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            brandName,
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 10),
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }

  // Overlay hiển thị giá
  Widget _buildPriceOverlay(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              currencyFormat.format(widget.bike.price),
              style: TextStyle(
                fontSize: ResponsiveHelper.adaptiveFontSize(context, 10),
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Phần thông tin xe
  Widget _buildInfoSection(
    ThemeData theme,
    bool isAvailableForRent,
    bool isLandscape,
  ) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Căn giữa các phần tử
        children: [
          // Phần thông tin cơ bản
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.bike.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.adaptiveFontSize(
                      context,
                      isLandscape ? 10 : 11,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                _buildBikeTypeAndQuantity(theme),
                SizedBox(height: 2),
                _buildLicensePlate(theme),
              ],
            ),
          ),
          // Phần nút hành động (luôn hiển thị ở dưới cùng)
          SizedBox(height: 4),
          _buildActionButtons(theme, isAvailableForRent),
        ],
      ),
    );
  }

  // Hiển thị loại xe và số lượng
  Widget _buildBikeTypeAndQuantity(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.motorcycle_outlined,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            BikeTypeConstants.getTranslationKey(widget.bike.type).tr(),
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 10),
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2,
                size: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 1),
              Text(
                '${widget.bike.quantity}',
                style: TextStyle(
                  fontSize: ResponsiveHelper.adaptiveFontSize(context, 9),
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Hiển thị biển số xe
  Widget _buildLicensePlate(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.confirmation_number_outlined,
          size: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            widget.bike.licensePlate,
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 10),
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Các nút hành động
  Widget _buildActionButtons(ThemeData theme, bool isAvailableForRent) {
    return Row(
      children: [
        // Menu thao tác (chỉ hiển thị với admin)
        if (_isAdmin) _buildAdminActions(theme),

        if (_isAdmin) const SizedBox(width: 6),

        // Nút thuê
        Expanded(child: _buildRentButton(theme, isAvailableForRent)),
      ],
    );
  }

  // Menu thao tác cho admin
  Widget _buildAdminActions(ThemeData theme) {
    return Container(
      height: 20,
      width: 20,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.more_vert,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onSelected: (value) {
          if (value == 'edit') {
            _navigateToEditBike();
          } else if (value == 'delete') {
            _showDeleteConfirmation(context);
          }
        },
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'edit',
                height: 36,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('common.edit'.tr(), style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 36,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text('common.delete'.tr(), style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
      ),
    );
  }

  // Nút thuê xe
  Widget _buildRentButton(ThemeData theme, bool isAvailableForRent) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    return SizedBox(
      width: double.infinity,
      height: isLandscape ? 22 : 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isAvailableForRent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceVariant,
          foregroundColor:
              isAvailableForRent
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: Size(0, isLandscape ? 20 : 24),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: isAvailableForRent ? () => _navigateToRentBike() : null,
        child: Text(
          'rental.rent_now'.tr(),
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveFontSize(
              context,
              isLandscape ? 9 : 10,
            ),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Badge hiển thị trạng thái
  Widget _buildStatusBadge(String status) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        Color backgroundColor;
        IconData icon;

        switch (status) {
          case BikeStatusConstants.available:
            backgroundColor = Colors.green.shade600;
            icon = Icons.check_circle_rounded;
            break;
          case BikeStatusConstants.unavailable:
            backgroundColor = Colors.red.shade600;
            icon = Icons.build_rounded;
            break;
          default:
            backgroundColor = Colors.grey.shade600;
            icon = Icons.info_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 10, color: backgroundColor),
        );
      },
    );
  }

  // Điều hướng đến trang chi tiết xe
  void _navigateToBikeDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BikeDetailsScreen(bike: widget.bike),
      ),
    );
  }

  // Điều hướng đến trang chỉnh sửa xe
  void _navigateToEditBike() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ManageBikeScreen(
              bike: widget.bike,
              onBikeUpdated: () {
                if (mounted && widget.onBikeUpdated != null) {
                  widget.onBikeUpdated!();
                }
              },
            ),
      ),
    );
  }

  // Điều hướng đến trang thuê xe
  void _navigateToRentBike() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserListScreen(bikeId: widget.bike.id)),
    );
  }

  // Xác nhận xóa xe
  void _showDeleteConfirmation(BuildContext context) {
    PanaraConfirmDialog.show(
      context,
      title: 'common.confirm_delete'.tr(),
      message: 'admin.bike.delete_confirm'.tr(),
      confirmButtonText: 'common.delete'.tr(),
      cancelButtonText: 'common.cancel'.tr(),
      textColor: Theme.of(context).primaryColor,
      onTapCancel: () {
        Navigator.pop(context);
      },
      onTapConfirm: () {
        Navigator.pop(context);
        _deleteBike();
      },
      panaraDialogType: PanaraDialogType.custom,
      color: Theme.of(context).primaryColor,
      barrierDismissible: false,
    );
  }

  // Xóa xe và xử lý kết quả
  Future<void> _deleteBike() async {
    try {
      await _bikeService.deleteBike(widget.bike.id);

      if (!mounted) return;

      if (widget.onBikeUpdated != null) {
        widget.onBikeUpdated!();
      }

      _showSuccessMessage();
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage();
    }
  }

  // Hiển thị thông báo thành công
  void _showSuccessMessage() {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: AwesomeSnackbarContent(
        contentType: ContentType.success,
        message: 'admin.bike.delete_success'.tr(),
        title: 'common.success'.tr(),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  // Hiển thị thông báo lỗi
  void _showErrorMessage() {
    final snackBar = SnackBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      behavior: SnackBarBehavior.floating,
      content: AwesomeSnackbarContent(
        contentType: ContentType.failure,
        message: 'admin.bike.delete_error'.tr(),
        title: 'common.error'.tr(),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
