// ignore_for_file: library_private_types_in_public_api

import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:bike_rental_app/widgets/bike_card.dart';
import 'package:bike_rental_app/widgets/bike_grid_card.dart';
import 'package:bike_rental_app/widgets/filter_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class BikeListScreen extends StatefulWidget {
  final bool showBackButton;
  const BikeListScreen({super.key, this.showBackButton = true});

  @override
  _BikeListScreenState createState() => _BikeListScreenState();
}

class _BikeListScreenState extends State<BikeListScreen> {
  final BikeService _bikeService = BikeService();
  final BrandService _brandService = BrandService();
  late Future<List<Bike>> _bikes;
  late Future<List<Brand>> _brands;
  bool _isGridView = false;
  String _searchQuery = '';
  String? _selectedBrandId;
  bool _isSearching = false;
  bool isLoading = false;

  // Filter states
  RangeValues _priceRange = RangeValues(0, 500000);
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await _refreshData();
    setState(() => isLoading = false);
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final bikesData = _bikeService.getBikes();
    final brandsData = _brandService.getBrands();

    if (mounted) {
      setState(() {
        _bikes = bikesData;
        _brands = brandsData;
      });
    }
  }

  void _showFilterDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    'admin.bike.filter'.tr(),
                    style: theme.textTheme.titleLarge,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bộ lọc thương hiệu
                        Text(
                          '${'admin.bike.brand'.tr()}:',
                          style: theme.textTheme.titleMedium,
                        ),
                        FutureBuilder<List<Brand>>(
                          future: _brands,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text(
                                '${'admin.bike.brand_error'.tr()}: ${snapshot.error}',
                              );
                            }
                            final brands = snapshot.data ?? [];
                            return Wrap(
                              spacing: 8,
                              children: [
                                FilterChipWidget(
                                  label: 'admin.bike.all'.tr(),
                                  selected: _selectedBrandId == null,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedBrandId = null;
                                    });
                                  },
                                ),
                                ...brands.map(
                                  (brand) => FilterChipWidget(
                                    label: brand.name,
                                    selected: _selectedBrandId == brand.id,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedBrandId =
                                            selected ? brand.id : null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        // Bộ lọc loại xe
                        Text(
                          '${'admin.bike.bike_type'.tr()}:',
                          style: theme.textTheme.titleMedium,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            FilterChipWidget(
                              label: 'admin.bike.all'.tr(),
                              selected: _selectedType == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType = null;
                                });
                              },
                            ),
                            FilterChipWidget(
                              label: 'bike.manual_bike'.tr(),
                              selected:
                                  _selectedType == BikeTypeConstants.manual,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType =
                                      selected
                                          ? BikeTypeConstants.manual
                                          : null;
                                });
                              },
                            ),
                            FilterChipWidget(
                              label: 'bike.scooter'.tr(),
                              selected:
                                  _selectedType == BikeTypeConstants.scooter,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType =
                                      selected
                                          ? BikeTypeConstants.scooter
                                          : null;
                                });
                              },
                            ),
                            FilterChipWidget(
                              label: 'bike.electric_bike'.tr(),
                              selected:
                                  _selectedType == BikeTypeConstants.electric,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedType =
                                      selected
                                          ? BikeTypeConstants.electric
                                          : null;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Bộ lọc giá
                        Text(
                          '${'admin.bike.price'.tr()}:',
                          style: theme.textTheme.titleMedium,
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 500000,
                          divisions: 100,
                          labels: RangeLabels(
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                            ).format(_priceRange.start),
                            NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                            ).format(_priceRange.end),
                          ),
                          onChanged: (RangeValues values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('admin.bike.cancel'.tr()),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        this.setState(
                          () {},
                        ); // Cập nhật trạng thái của BikeListScreen
                        Navigator.pop(context);
                      },
                      child: Text('admin.bike.apply'.tr()),
                    ),
                  ],
                ),
          ),
    );
  }

  List<Bike> _filterBikes(List<Bike> bikes) {
    return bikes.where((bike) {
      bool matchesSearch =
          _searchQuery.isEmpty ||
          bike.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bike.type.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesBrand =
          _selectedBrandId == null || bike.brandId == _selectedBrandId;

      bool matchesType = _selectedType == null || bike.type == _selectedType;

      bool matchesStatus =
          _selectedStatus == null || bike.status == _selectedStatus;

      bool matchesPrice =
          bike.price >= _priceRange.start && bike.price <= _priceRange.end;

      return matchesSearch &&
          matchesBrand &&
          matchesType &&
          matchesStatus &&
          matchesPrice;
    }).toList();
  }

  // Kiểm tra xem có bộ lọc nào đang được áp dụng không
  bool _hasActiveFilters() {
    return _selectedBrandId != null ||
        _selectedType != null ||
        _selectedStatus != null ||
        _priceRange != const RangeValues(0, 500000);
  }

  // Xóa bộ lọc
  void _clearFilter(String filterType) {
    setState(() {
      switch (filterType) {
        case 'brand':
          _selectedBrandId = null;
          break;
        case 'type':
          _selectedType = null;
          break;
        case 'price':
          _priceRange = RangeValues(0, 500000);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          extendBody: true, // Cần thiết cho CrystalNavigationBar
          appBar: AppBar(
            title:
                _isSearching
                    ? TextField(
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'admin.bike.search_bike'.tr(),
                        hintStyle: theme.inputDecorationTheme.hintStyle,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      autofocus: true,
                    )
                    : Text(
                      'admin.bike.bike_list'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveHelper.adaptiveFontSize(
                          context,
                          theme.textTheme.titleLarge?.fontSize ?? 20,
                        ),
                      ),
                    ),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: theme.appBarTheme.elevation,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Container(color: theme.dividerColor, height: 1.0),
            ),
            leading:
                widget.showBackButton
                    ? IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.appBarTheme.foregroundColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                    : null,
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.clear : Icons.search,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      _searchQuery = '';
                      _isSearching = false;
                    } else {
                      _isSearching = true;
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  _showFilterDialog(context);
                },
              ),
              IconButton(
                icon: Icon(
                  _isGridView ? Icons.list : Icons.grid_view,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
          body: FutureBuilder<List<dynamic>>(
            future: Future.wait([_bikes, _brands]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  isLoading) {
                return AppLoadingIndicator(
                  color:
                      theme.progressIndicatorTheme.color ?? theme.primaryColor,
                  message: 'admin.bike.loading'.tr(),
                );
              }

              if (snapshot.hasError) {
                return AppErrorWidget(
                  message: '${'admin.bike.error'.tr()}: ${snapshot.error}',
                  onRetry: _refreshData,
                );
              }

              final List<Brand> brands = snapshot.data![1] as List<Brand>;
              final List<Bike> bikes = snapshot.data![0] as List<Bike>;
              final filteredBikes = _filterBikes(bikes);

              return RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.progressIndicatorTheme.color ?? theme.primaryColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hiển thị tiêu đề "Bộ lọc" và các bộ lọc đã áp dụng
                    if (_hasActiveFilters())
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: Text(
                          'admin.bike.filter'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor.withAlpha(153),
                            fontSize: ResponsiveHelper.adaptiveFontSize(
                              context,
                              theme.textTheme.titleMedium?.fontSize ?? 16,
                            ),
                          ),
                        ),
                      ),
                    if (_hasActiveFilters())
                      Container(
                        height: 60, // Chiều cao cố định để hiển thị các chip
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: theme.scaffoldBackgroundColor,
                        child: ListView(
                          scrollDirection:
                              Axis.horizontal, // Cho phép cuộn ngang
                          children: [
                            if (_selectedBrandId != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    brands
                                        .firstWhere(
                                          (brand) =>
                                              brand.id == _selectedBrandId,
                                        )
                                        .name,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  backgroundColor: theme.cardTheme.color,
                                  deleteIcon: Icon(Icons.close, size: 18),
                                  onDeleted: () => _clearFilter('brand'),
                                ),
                              ),
                            if (_selectedType != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    _selectedType!,
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  backgroundColor: theme.cardTheme.color,
                                  deleteIcon: Icon(Icons.close, size: 18),
                                  onDeleted: () => _clearFilter('type'),
                                ),
                              ),
                            if (_priceRange != const RangeValues(0, 500000))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text(
                                    '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_priceRange.start)} - ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(_priceRange.end)}',
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  backgroundColor: theme.cardTheme.color,
                                  deleteIcon: Icon(Icons.close, size: 18),
                                  onDeleted: () => _clearFilter('price'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child:
                          filteredBikes.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 80,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withAlpha(153),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'admin.bike.no_bike_found'.tr(),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              )
                              : _isGridView
                              ? GridView.builder(
                                padding: EdgeInsets.only(
                                  left:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).left,
                                  right:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).right,
                                  top:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).top,
                                  bottom: 100,
                                ), // Thêm padding ở dưới cùng cho thanh điều hướng
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          ResponsiveHelper.adaptiveGridCount(
                                            context,
                                          ),
                                      childAspectRatio:
                                          ResponsiveHelper.adaptiveChildAspectRatio(
                                            context,
                                          ),
                                      crossAxisSpacing:
                                          ResponsiveHelper.isTablet(context)
                                              ? 20
                                              : 16,
                                      mainAxisSpacing:
                                          ResponsiveHelper.isTablet(context)
                                              ? 20
                                              : 16,
                                    ),
                                itemCount: filteredBikes.length,
                                itemBuilder: (context, index) {
                                  Bike bike = filteredBikes[index];
                                  // Thêm hiệu ứng fadeInUp với độ trễ tăng dần theo index
                                  return AnimationHelper.fadeInUp(
                                    delay: Duration(milliseconds: 100 * index),
                                    child: BikeGridCard(
                                      bike: bike,
                                      onBikeUpdated: () {
                                        setState(() {
                                          _refreshData();
                                        });
                                      },
                                    ),
                                  );
                                },
                              )
                              : ListView.builder(
                                padding: EdgeInsets.only(
                                  left:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).left /
                                      1.5,
                                  right:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).right /
                                      1.5,
                                  top:
                                      ResponsiveHelper.adaptivePadding(
                                        context,
                                      ).top /
                                      1.5,
                                  bottom: 100,
                                ), // Thêm padding ở dưới cùng cho thanh điều hướng
                                itemCount: filteredBikes.length,
                                itemBuilder: (context, index) {
                                  Bike bike = filteredBikes[index];
                                  // Thêm hiệu ứng fadeInRight với độ trễ tăng dần theo index
                                  return AnimationHelper.fadeInRight(
                                    delay: Duration(milliseconds: 100 * index),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 8,
                                      ),
                                      child: BikeCard(
                                        bike: bike,
                                        onBikeUpdated: () {
                                          setState(() {
                                            _refreshData();
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: Padding(
            padding: EdgeInsets.only(
              bottom: 70,
            ), // Thêm padding để tránh bị che khuất bởi thanh điều hướng
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/manage-bike').then((_) {
                  if (mounted) {
                    _refreshData();
                  }
                });
              },
              backgroundColor:
                  theme.elevatedButtonTheme.style?.backgroundColor?.resolve(
                    {},
                  ) ??
                  theme.primaryColor,
              child: Icon(
                Icons.add,
                color:
                    theme.elevatedButtonTheme.style?.foregroundColor?.resolve(
                      {},
                    ) ??
                    Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
