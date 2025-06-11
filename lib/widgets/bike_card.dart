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
import 'package:cached_network_image/cached_network_image.dart';

class BikeCard extends StatefulWidget {
  final Bike bike;
  final Function? onBikeUpdated;

  const BikeCard({super.key, required this.bike, this.onBikeUpdated});

  @override
  State<BikeCard> createState() => _BikeCardState();
}

class _BikeCardState extends State<BikeCard> {
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

  // Xác nhận xóa xe
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('common.confirm_delete'.tr()),
          content: Text('admin.bike.delete_confirm'.tr()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: () => _confirmAndDeleteBike(context),
              child: Text('common.delete'.tr()),
            ),
          ],
        );
      },
    );
  }

  // Xử lý xóa xe
  void _confirmAndDeleteBike(BuildContext dialogContext) {
    // Đóng hộp thoại xác nhận
    Navigator.of(dialogContext).pop();

    // Thực hiện xóa xe trong hàm riêng
    _deleteBike();
  }

  // Hàm xóa xe và xử lý kết quả
  Future<void> _deleteBike() async {
    try {
      // Xóa xe
      await _bikeService.deleteBike(widget.bike.id);

      // Kiểm tra mounted trước khi cập nhật UI
      if (!mounted) return;

      // Gọi callback cập nhật
      if (widget.onBikeUpdated != null) {
        widget.onBikeUpdated!();
      }

      // Hiển thị thông báo thành công
      _showSuccessMessage();
    } catch (e) {
      // Kiểm tra mounted trước khi cập nhật UI
      if (!mounted) return;

      // Hiển thị thông báo lỗi
      _showErrorMessage();
    }
  }

  // Hiển thị thông báo thành công
  void _showSuccessMessage() {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
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
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: theme.cardColor,
          child: InkWell(
            splashColor: theme.colorScheme.primary.withOpacity(0.1),
            highlightColor: theme.colorScheme.primary.withOpacity(0.05),
            onTap: () {
              // Chuyển đến trang chi tiết xe với animation mượt mà
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BikeDetailsScreen(bike: widget.bike),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần hình ảnh với các badge
                Hero(
                  tag: 'bike-${widget.bike.id}',
                  child: Stack(
                    children: [
                      // Hình ảnh xe
                      Container(
                        height: ResponsiveHelper.responsiveValue(
                          context: context,
                          mobile: 200.0,
                          tablet: isLandscape ? 180.0 : 220.0,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.3,
                          ),
                        ),
                        child:
                            widget.bike.imageUrl == null ||
                                    widget.bike.imageUrl!.isEmpty
                                ? Center(
                                  child: Icon(
                                    Icons.motorcycle_outlined,
                                    size: 60,
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                  ),
                                )
                                : CachedNetworkImage(
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
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image_rounded,
                                              size: 40,
                                              color: theme.colorScheme.error
                                                  .withOpacity(0.7),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Không thể tải hình ảnh',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ),
                      ),

                      // Gradient overlay để làm nổi bật thông tin
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Badge trạng thái
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildStatusBadge(widget.bike.status),
                      ),

                      // Badge thương hiệu
                      Positioned(
                        top: 12,
                        left: 12,
                        child: FutureBuilder<Brand?>(
                          future: _brandService.getBrandById(
                            widget.bike.brandId,
                          ),
                          builder: (context, snapshot) {
                            String brandName = '';

                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data != null) {
                              brandName = snapshot.data!.name;
                            }

                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.8,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                brandName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Badge giá
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${currencyFormat.format(widget.bike.price)} / ngày',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Phần thông tin xe
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên xe
                      Text(
                        widget.bike.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveHelper.adaptiveFontSize(
                            context,
                            18,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 8),

                      // Thông tin cơ bản
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildInfoItem(
                                  Icons.motorcycle_outlined,
                                  '${'admin.bike.type'.tr()}: ${BikeTypeConstants.getTranslationKey(widget.bike.type).tr()}',
                                  theme.colorScheme.onSurface,
                                ),
                                Spacer(),
                                _buildInfoItem(
                                  Icons.inventory_2,
                                  '${'admin.bike.quantity_short'.tr()}: ${widget.bike.quantity}',
                                  theme.colorScheme.onSurface,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoItem(
                                  Icons.confirmation_number_outlined,
                                  '${'admin.bike.license_plate'.tr()}: ${widget.bike.licensePlate}',
                                  theme.colorScheme.onSurface,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 8),

                      // Các nút hành động
                      Row(
                        children: [
                          // Nút Sửa (chỉ hiển thị với admin)
                          Visibility(
                            visible: _isAdmin,
                            child: Expanded(
                              flex: 1,
                              child: _buildActionButton(
                                context,
                                icon: Icons.edit_outlined,
                                label: 'common.edit'.tr(),
                                colorbg: theme.colorScheme.surface,
                                colorfg: theme.colorScheme.primary,
                                colorbd: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                                borderWidth: 1,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ManageBikeScreen(
                                            bike: widget.bike,
                                            onBikeUpdated: () {
                                              if (mounted &&
                                                  widget.onBikeUpdated !=
                                                      null) {
                                                widget.onBikeUpdated!();
                                              }
                                            },
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Khoảng cách giữa các nút
                          Visibility(
                            visible: _isAdmin,
                            child: SizedBox(width: 8),
                          ),

                          // Nút Xoá (chỉ hiển thị với admin)
                          Visibility(
                            visible: _isAdmin,
                            child: Expanded(
                              flex: 1,
                              child: _buildActionButton(
                                context,
                                icon: Icons.delete_outline,
                                label: 'common.delete'.tr(),
                                colorbg: theme.colorScheme.surface,
                                colorfg: theme.colorScheme.error,
                                colorbd: theme.colorScheme.error.withOpacity(
                                  0.5,
                                ),
                                borderWidth: 1,
                                onPressed:
                                    () => _showDeleteConfirmation(context),
                              ),
                            ),
                          ),

                          // Khoảng cách giữa các nút
                          Visibility(
                            visible: _isAdmin,
                            child: SizedBox(width: 8),
                          ),

                          // Nút Thuê ngay
                          Expanded(
                            flex: _isAdmin ? 2 : 1,
                            child: _buildActionButton(
                              context,
                              icon: Icons.shopping_cart_outlined,
                              label: 'rental.rent_now'.tr(),
                              colorbg:
                                  BikeStatusConstants.canRent(
                                        widget.bike.status,
                                        widget.bike.quantity,
                                      )
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceVariant,
                              colorfg:
                                  BikeStatusConstants.canRent(
                                        widget.bike.status,
                                        widget.bike.quantity,
                                      )
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                              colorbd: Colors.transparent,
                              borderWidth: 0,
                              onPressed:
                                  BikeStatusConstants.canRent(
                                        widget.bike.status,
                                        widget.bike.quantity,
                                      )
                                      ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => UserListScreen(
                                                  bikeId: widget.bike.id,
                                                ),
                                          ),
                                        );
                                      }
                                      : () {
                                        final snackBar = SnackBar(
                                          elevation: 0,
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.transparent,
                                          content: AwesomeSnackbarContent(
                                            contentType: ContentType.warning,
                                            message:
                                                'bike.bike_not_available'.tr(),
                                            title: 'common.notification'.tr(),
                                          ),
                                        );
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(snackBar);
                                      },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: ResponsiveHelper.adaptiveFontSize(context, 13),
            color: color,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color colorbg,
    required Color colorfg,
    required Color colorbd,
    required double borderWidth,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: ResponsiveHelper.adaptiveFontSize(context, 12),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorbg,
        foregroundColor: colorfg,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 12),
        minimumSize: Size(0, 0),
        side: BorderSide(color: colorbd, width: borderWidth),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Widget _buildStatusBadge(String status) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        Color backgroundColor;
        Color textColor = Colors.white;
        IconData icon;
        String statusText;

        switch (status) {
          case BikeStatusConstants.available:
            backgroundColor = Colors.green.shade600;
            icon = Icons.check_circle_rounded;
            statusText = 'admin.bike.available'.tr();
            break;
          case BikeStatusConstants.unavailable:
            backgroundColor = Colors.red.shade600;
            icon = Icons.build_rounded;
            statusText = 'admin.bike.unavailable'.tr();
            break;
          default:
            backgroundColor = Colors.grey.shade600;
            icon = Icons.info_rounded;
            statusText = status;
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: textColor),
              SizedBox(width: 4),
              Text(
                statusText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  fontSize: ResponsiveHelper.adaptiveFontSize(
                    context,
                    theme.textTheme.labelSmall?.fontSize ?? 10,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
