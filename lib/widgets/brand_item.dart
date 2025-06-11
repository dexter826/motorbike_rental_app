import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/screens/brand/manage_brand_screen.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrandItem extends StatelessWidget {
  final Brand brand;
  final Function(Brand) onDelete;

  const BrandItem({super.key, required this.brand, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageBrandScreen(brand: brand),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Logo or Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child:
                        brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CachedNetworkImage(
                                imageUrl: brand.logoUrl!,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) => Center(
                                      child: CircularProgressIndicator(
                                        color: theme.colorScheme.primary,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Center(
                                      child: Text(
                                        brand.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                              ),
                            )
                            : Center(
                              child: Text(
                                brand.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                  ),
                  SizedBox(width: 16),
                  // Brand Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              brand.country!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ManageBrandScreen(brand: brand),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: () {
                          _showDeleteConfirmation(context, brand);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Brand brand) {
    final theme = Theme.of(context);
    PanaraConfirmDialog.show(
      context,
      title: 'common.confirm_delete'.tr(),
      message: 'admin.brand.delete_confirm'.tr(namedArgs: {'0': brand.name}),
      confirmButtonText: 'common.delete'.tr(),
      cancelButtonText: 'common.cancel'.tr(),
      textColor: theme.primaryColor,
      onTapCancel: () {
        Navigator.pop(context);
      },
      onTapConfirm: () {
        Navigator.pop(context);
        onDelete(brand);
      },
      panaraDialogType: PanaraDialogType.custom,
      color: theme.primaryColor,
      barrierDismissible: false,
    );
  }
}
