// ignore_for_file: deprecated_member_use

import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:bike_rental_app/widgets/rental_item.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  _RentalScreenState createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen>
    with SingleTickerProviderStateMixin {
  final RentalService _rentalService = RentalService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String _searchQuery = '';

  final List<String> _tabs = [
    'rental.all'.tr(),
    'rental.ongoing'.tr(),
    'rental.completed'.tr(),
    'rental.expired'.tr(),
  ];
  final List<String> _statusFilters = [
    'All',
    RentalStatusConstants.ongoing,
    RentalStatusConstants.completed,
    RentalStatusConstants.expired,
  ];

  // Get translated status for display

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadRentals();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadRentals();
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRentals() {
    setState(() {});
  }

  Future<List<Rental>> _getFilteredRentals() async {
    final allRentals = await _rentalService.getRentals();

    List<Rental> filteredRentals;
    if (_tabController.index == 0) {
      filteredRentals = allRentals;
    } else {
      final statusFilter = _statusFilters[_tabController.index];
      filteredRentals =
          allRentals.where((rental) => rental.status == statusFilter).toList();
    }

    // Áp dụng tìm kiếm nếu có
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final userService = UserService();
      final bikeService = BikeService();

      // Lọc danh sách đơn thuê dựa trên query
      List<Rental> searchResults = [];

      for (var rental in filteredRentals) {
        // Tìm kiếm theo ID đơn thuê (giữ nguyên)
        if (rental.id.toLowerCase().contains(query)) {
          searchResults.add(rental);
          continue;
        }

        try {
          // Tìm kiếm theo thông tin người dùng
          final user = await userService.getUserById(rental.userId);
          if (user != null && user.name.toLowerCase().contains(query)) {
            searchResults.add(rental);
            continue;
          }

          // Tìm kiếm theo thông tin xe máy
          final bike = await bikeService.getBikeById(rental.bikeId);
          if (bike.name.toLowerCase().contains(query) ||
              bike.licensePlate.toLowerCase().contains(query)) {
            searchResults.add(rental);
            continue;
          }
        } catch (e) {
          // Bỏ qua lỗi và tiếp tục tìm kiếm
          debugPrint('Lỗi khi tìm kiếm: $e');
        }
      }

      filteredRentals = searchResults;
    }

    filteredRentals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filteredRentals;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Cần thiết cho CrystalNavigationBar
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title:
            _showSearch
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'rental.search_rentals'.tr(),
                    hintStyle: TextStyle(
                      color: theme.appBarTheme.foregroundColor,
                    ),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: theme.appBarTheme.foregroundColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _showSearch = false;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.appBarTheme.foregroundColor),
                  cursorColor: theme.appBarTheme.foregroundColor,
                  autofocus: true,
                )
                : Text(
                  'rental.rentals'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.appBarTheme.foregroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            tabs:
                _tabs
                    .map(
                      (tab) => Tab(
                        text: tab,
                        height: ResponsiveHelper.isLandscape(context) ? 32 : 40,
                      ),
                    )
                    .toList(),
            indicatorColor: theme.appBarTheme.foregroundColor,
            labelStyle: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.appBarTheme.foregroundColor,
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 14),
            ),
            unselectedLabelStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 14),
            ),
            isScrollable: true,
            labelPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.responsiveValue(
                context: context,
                mobile: 12,
                tablet: 16,
              ),
            ),
            tabAlignment: TabAlignment.center,
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: List.generate(_tabs.length, (index) {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: FutureBuilder<List<Rental>>(
                future: _getFilteredRentals(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return AppLoadingIndicator(
                      color: theme.primaryColor,
                      message: 'common.loading'.tr(),
                    );
                  } else if (snapshot.hasError) {
                    return AppErrorWidget(
                      message: 'common.error_with_message'.tr(
                        args: [snapshot.error.toString()],
                      ),
                      onRetry: () => setState(() {}),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.motorcycle_outlined,
                            size: 80,
                            color: theme.colorScheme.outline,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'rental.no_rentals'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.only(
                        left: ResponsiveHelper.responsiveValue(
                          context: context,
                          mobile: 12,
                          tablet: 16,
                        ),
                        right: ResponsiveHelper.responsiveValue(
                          context: context,
                          mobile: 12,
                          tablet: 16,
                        ),
                        top: 12,
                        bottom: 100,
                      ), // Thêm padding ở dưới cùng cho thanh điều hướng
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        Rental rental = snapshot.data![index];
                        return AnimationHelper.fadeInUp(
                          duration: Duration(milliseconds: 500),
                          delay: Duration(milliseconds: index * 100),
                          child: RentalItem(
                            rental: rental,
                            onRefresh: _loadRentals,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
