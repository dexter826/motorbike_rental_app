import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/screens/brand/manage_brand_screen.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/widgets/brand_item.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class BrandListScreen extends StatefulWidget {
  @override
  _BrandListScreenState createState() => _BrandListScreenState();
}

class _BrandListScreenState extends State<BrandListScreen> {
  final BrandService _brandService = BrandService();
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'admin.brand.search_brand'.tr(),
                    border: InputBorder.none,
                    hintStyle: theme.inputDecorationTheme.hintStyle,
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
                : Text(
                  'admin.brand.brand_list'.tr(),
                  style: theme.appBarTheme.titleTextStyle,
                ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.primary.withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: theme.colorScheme.primary,
              onRefresh: () async {
                await Future.delayed(Duration(seconds: 1));
                setState(() {});
              },
              child: StreamBuilder<List<Brand>>(
                stream: _brandService.getBrandsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return AppLoadingIndicator(
                      color: theme.progressIndicatorTheme.color!,
                      message: 'admin.brand.loading'.tr(),
                    );
                  }

                  if (snapshot.hasError) {
                    return AppErrorWidget(
                      message: '${'admin.brand.error'.tr()}: ${snapshot.error}',
                      onRetry: () => setState(() {}),
                    );
                  }

                  List<Brand> brands = snapshot.data ?? [];

                  if (_searchQuery.isNotEmpty) {
                    brands =
                        brands
                            .where(
                              (brand) => brand.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                            )
                            .toList();
                  }

                  if (brands.isEmpty) {
                    return AppEmptyWidget(
                      message: 'admin.brand.no_brand_found'.tr(),
                      icon: Icons.search_off,
                      onAction:
                          _searchQuery.isNotEmpty
                              ? () => setState(() => _searchQuery = '')
                              : null,
                      actionLabel:
                          _searchQuery.isNotEmpty
                              ? 'admin.brand.clear_search'.tr()
                              : null,
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: 16),
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      Brand brand = brands[index];
                      // Thêm hiệu ứng fadeInLeft với độ trễ tăng dần theo index
                      return AnimationHelper.fadeInLeft(
                        delay: Duration(milliseconds: 100 * index),
                        child: BrandItem(
                          brand: brand,
                          onDelete: (brand) async {
                            await _brandService.deleteBrand(brand.id);
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'admin.brand.deleted'.tr(),
                                message: 'admin.brand.deleted_message'
                                    .tr()
                                    .replaceAll('{name}', brand.name),
                                contentType: ContentType.success,
                              ),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ManageBrandScreen()),
          );
        },
      ),
    );
  }
}
