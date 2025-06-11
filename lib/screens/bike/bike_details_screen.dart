import 'package:bike_rental_app/screens/user/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/models/bike.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class BikeDetailsScreen extends StatelessWidget {
  final Bike bike;

  const BikeDetailsScreen({super.key, required this.bike});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'bike.bike_details'.tr(),
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2, // Added elevation for shadow
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () {
            // Sử dụng Navigator.pop để quay lại màn hình trước đó
            Navigator.of(context).pop();
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor.withAlpha(51),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            AnimationHelper.fadeIn(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                height: ResponsiveHelper.responsiveValue(
                  context: context,
                  mobile: 250.0,
                  tablet: isLandscape ? 300.0 : 350.0,
                ),
                width: double.infinity,
                decoration: BoxDecoration(color: theme.cardColor),
                child:
                    bike.imageUrl != null && bike.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: bike.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Center(
                                child: CircularProgressIndicator(
                                  color: theme.primaryColor,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Icon(
                                Icons.motorcycle,
                                size: 100,
                                color: theme.colorScheme.primary.withAlpha(128),
                              ),
                        )
                        : Icon(
                          Icons.motorcycle,
                          size: 100,
                          color: theme.colorScheme.primary.withAlpha(128),
                        ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  AnimationHelper.fadeInRight(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      bike.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: ResponsiveHelper.adaptiveFontSize(
                          context,
                          24,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  AnimationHelper.fadeInRight(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      '${'bike.bike_type'.tr()}: ${bike.type}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: ResponsiveHelper.adaptiveFontSize(
                          context,
                          16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Status Card
                  AnimationHelper.fadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            bike.status == BikeStatusConstants.available
                                ? Colors.green.withAlpha(77)
                                : Colors.red.withAlpha(77),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            bike.status == BikeStatusConstants.available
                                ? Icons.check_circle
                                : Icons.error,
                            color:
                                bike.status == BikeStatusConstants.available
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            bike.status == BikeStatusConstants.available
                                ? 'bike.available_for_rent'.tr()
                                : 'bike.unavailable'.tr(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper.adaptiveFontSize(
                                context,
                                16,
                              ),
                              color:
                                  bike.status == BikeStatusConstants.available
                                      ? Colors.green
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Details Grid
                  AnimationHelper.fadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 600),
                    child: _buildDetailRow(
                      'bike.license_plate'.tr(),
                      bike.licensePlate,
                      context,
                    ),
                  ),
                  AnimationHelper.fadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 700),
                    child: _buildDetailRow(
                      'bike.bike_price'.tr(),
                      NumberFormat.currency(
                        locale: 'vi_VN',
                        symbol: 'đ',
                      ).format(bike.price),
                      context,
                    ),
                  ),
                  AnimationHelper.fadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 800),
                    child: _buildDetailRow(
                      'bike.bike_quantity'.tr(),
                      bike.quantity.toString(),
                      context,
                    ),
                  ),
                  AnimationHelper.fadeInLeft(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 900),
                    child: _buildDetailRow(
                      'bike.bike_id'.tr(),
                      bike.id,
                      context,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: ResponsiveHelper.adaptivePadding(context),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 16.0,
                tablet: 20.0,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed:
              BikeStatusConstants.canRent(bike.status, bike.quantity)
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserListScreen(bikeId: bike.id),
                      ),
                    );
                  }
                  : null,
          child: Text(
            'bike.rent_bike'.tr(),
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 18),
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                label == 'bike.license_plate'.tr()
                    ? Icons.confirmation_number
                    : label == 'bike.bike_price'.tr()
                    ? Icons.attach_money
                    : label == 'bike.bike_quantity'.tr()
                    ? Icons.inventory_2
                    : Icons.qr_code,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: ResponsiveHelper.adaptiveFontSize(context, 16),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
