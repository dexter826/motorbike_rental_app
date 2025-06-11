// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:bike_rental_app/models/notification.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/screens/bike/bike_list_screen.dart';
import 'package:bike_rental_app/screens/payment/payment_list_screen.dart';
import 'package:bike_rental_app/screens/home/qr_scanner_screen.dart';
import 'package:bike_rental_app/screens/rental/rental_screen.dart';
import 'package:bike_rental_app/screens/admin/staff_management_screen.dart';
import 'package:bike_rental_app/screens/user/user_list_screen.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/notification_service.dart';
import 'package:bike_rental_app/services/payment_service.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/screens/brand/brand_list_screen.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import 'package:one_clock/one_clock.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import '../notification/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? dashboardStats;
  final AuthService _authService = AuthService();
  bool get isAdmin => _authService.isAdmin;
  final NotificationService _notificationService = NotificationService();

  // Biến cờ để kiểm tra xem animation đã được load lần đầu chưa
  bool _isFirstLoad = true;

  // initState đã được di chuyển xuống dưới

  Future<void> _initializeAuth() async {
    await _authService.isLoggedIn();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadAllData() async {
    try {
      final stats = await _loadDashboardStats();

      if (mounted) {
        setState(() {
          dashboardStats = stats;
          isLoading = false;
          // Không reset biến _isFirstLoad để animation chỉ load một lần duy nhất
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadDashboardStats() async {
    final bikeService = BikeService();
    final rentalService = RentalService();
    final paymentService = PaymentService();

    final bikes = await bikeService.getBikes();
    final rentals = await rentalService.getRentals();
    final payments = await paymentService.getPayments();

    final activeRentalCount =
        rentals.where((r) => r.status == RentalStatusConstants.ongoing).length;

    // Tính doanh thu của ngày hôm nay
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(
      today.year,
      today.month,
      today.day,
      23,
      59,
      59,
      999,
    );

    final totalRevenueAmount = payments
        .where(
          (p) =>
              p.status == PaymentStatusConstants.completed &&
                  p.paymentDate.isAtSameMomentAs(startOfDay) ||
              (p.paymentDate.isAfter(startOfDay) &&
                  p.paymentDate.isBefore(endOfDay)) ||
              p.paymentDate.isAtSameMomentAs(endOfDay),
        )
        .fold(0.0, (sum, payment) => sum + payment.amount);

    final availableBikeCount = bikes
        .where((bike) => bike.status == BikeStatusConstants.available)
        .fold(0, (sum, bike) => sum + bike.quantity);

    return {
      'totalBikes': bikes.length,
      'activeRentals': activeRentalCount,
      'totalRevenue': totalRevenueAmount,
      'availableBikes': availableBikeCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Cần thiết cho CrystalNavigationBar nổi
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar:
          _currentIndex == 0
              ? AppBar(
                elevation: 0,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                title: Stack(
                  alignment: Alignment.center,
                  children: AnimationHelper.staggeredList(
                    children: [
                      Image.asset(
                        'assets/images/main_logo.png',
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/info-company');
                  },
                ),
                actions: [
                  StreamBuilder<List<BikeNotification>>(
                    stream: _notificationService.getAllNotifications(),
                    builder: (context, snapshot) {
                      int unreadCount = 0;
                      if (snapshot.hasData) {
                        final notifications = snapshot.data!;
                        unreadCount =
                            notifications
                                .where((n) => n.isRead == false)
                                .length;
                      }
                      return _buildNotificationIcon(context, unreadCount);
                    },
                  ),

                  //log out
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: Theme.of(context).appBarTheme.foregroundColor,
                    ),
                    onPressed: () {
                      PanaraConfirmDialog.show(
                        context,
                        title: 'auth.logout'.tr(),
                        message: 'auth.logout_confirm'.tr(),
                        confirmButtonText: 'auth.logout'.tr(),
                        cancelButtonText: 'common.cancel'.tr(),
                        textColor:
                            Theme.of(context).textTheme.bodyLarge!.color!,
                        onTapCancel: () {
                          Navigator.pop(context);
                        },
                        onTapConfirm: () {
                          // Đóng dialog trước
                          Navigator.pop(context);

                          // Đăng xuất và chuyển hướng đến màn hình đăng nhập
                          _authService.signOut();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          );
                        },
                        panaraDialogType: PanaraDialogType.custom,
                        color: Theme.of(context).primaryColor,
                        barrierDismissible: false,
                      );
                    },
                  ),
                ],
              )
              : null,

      body: _getBody(),
      bottomNavigationBar:
          _currentIndex != 2
              ? CrystalNavigationBar(
                currentIndex: _currentIndex,
                height: 70,
                unselectedItemColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.7),
                selectedItemColor: Theme.of(context).primaryColor,
                backgroundColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.9),
                enableFloatingNavBar: true,
                borderRadius: 30,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                paddingR: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                borderWidth: 1,
                outlineBorderColor: Theme.of(
                  context,
                ).primaryColor.withOpacity(0.2),
                onTap: (index) {
                  if (_currentIndex != index && mounted) {
                    setState(() {
                      _previousIndex = _currentIndex;
                      _currentIndex = index;
                      if (index == 0) {
                        isLoading = true;
                        _loadAllData();
                        // Không reset biến _isFirstLoad khi chuyển tab để animation không load lại
                      }
                    });
                  }
                },
                items: [
                  /// Home
                  CrystalNavigationBarItem(
                    icon: IconlyBold.home,
                    unselectedIcon: IconlyLight.home,
                    selectedColor: Theme.of(context).primaryColor,
                  ),

                  /// Bikes
                  CrystalNavigationBarItem(
                    icon: IconlyBold.buy,
                    unselectedIcon: IconlyLight.buy,
                    selectedColor: Theme.of(context).primaryColor,
                  ),

                  /// QR Scan
                  CrystalNavigationBarItem(
                    icon: IconlyBold.scan,
                    unselectedIcon: IconlyLight.scan,
                    selectedColor: Theme.of(context).primaryColor,
                  ),

                  /// Users
                  CrystalNavigationBarItem(
                    icon: IconlyBold.profile,
                    unselectedIcon: IconlyLight.profile,
                    selectedColor: Theme.of(context).primaryColor,
                  ),

                  /// Rentals
                  CrystalNavigationBarItem(
                    icon: IconlyBold.activity,
                    unselectedIcon: IconlyLight.activity,
                    selectedColor: Theme.of(context).primaryColor,
                  ),
                ],
              )
              : null,
    );
  }

  Widget _buildNotificationIcon(BuildContext context, int unreadCount) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadAllData();
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return BikeListScreen(showBackButton: false);
      case 2:
        return QRScannerScreen(
          onBack: () {
            if (mounted) {
              setState(
                () => _currentIndex = _previousIndex,
              ); // Quay lại tab trước đó
            }
          },
        );
      case 3:
        return UserListScreen(showBackButton: false);
      case 4:
        return RentalScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final staffName = _authService.currentStaff?.name ?? 'Ní';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          isLoading = true;
          // Không reset biến _isFirstLoad khi refresh để animation không load lại
        });
        await _loadAllData();
      },
      child:
          isLoading
              ? Center(
                child: AnimationHelper.loadingAnimation(
                  width: 150,
                  height: 150,
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child:
                    _isFirstLoad
                        ? AnimationHelper.fadeIn(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: AnimationHelper.staggeredList(
                              children: [
                                _buildHeader(context, staffName),
                                SizedBox(height: 24),
                                _buildStatisticsSection(),
                                SizedBox(height: 24),
                                Text(
                                  'home.main_management'.tr(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 16),
                                SafeArea(
                                  child: AnimationHelper.fadeIn(
                                    child: Column(
                                      children: [_buildFeatureGrid(context)],
                                    ),
                                  ),
                                ),
                              ],
                              initialDelay: const Duration(milliseconds: 300),
                              itemDelay: const Duration(milliseconds: 200),
                              animation: StaggeredAnimation.fadeInUp,
                            ),
                          ),
                          onFinish: (_) {
                            // Đánh dấu đã load animation lần đầu
                            setState(() {
                              _isFirstLoad = false;
                            });
                          },
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, staffName),
                            SizedBox(height: 24),
                            _buildStatisticsSection(),
                            SizedBox(height: 24),
                            Text(
                              'home.main_management'.tr(),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium!.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 16),
                            SafeArea(
                              child: Column(
                                children: [_buildFeatureGrid(context)],
                              ),
                            ),
                          ],
                        ),
              ),
    );
  }

  Widget _buildHeader(BuildContext context, String staffName) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'home.greeting'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    staffName,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'home.today'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Thay CircleAvatar bằng AnalogClock
          SizedBox(
            width: 60, // Tương đương đường kính của CircleAvatar
            height: 60,
            child: AnalogClock(
              isLive: true, // Cập nhật thời gian thực
              showNumbers: true, // Ẩn số để giao diện gọn gàng
              showTicks: true, // Hiển thị vạch để dễ đọc
              showDigitalClock: false, // Ẩn đồng hồ số
              hourHandColor: Theme.of(context).primaryColor,
              minuteHandColor: Theme.of(context).primaryColor,
              secondHandColor: Theme.of(context).colorScheme.secondary,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (dashboardStats == null) return SizedBox();

    return Column(
      children: [
        Row(
          children: [
            Text(
              'home.overview'.tr(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).primaryColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'home.total_bikes'.tr(),
                dashboardStats!['totalBikes'].toString(),
                Icons.motorcycle,
                [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.4),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'home.available_bikes'.tr(),
                dashboardStats!['availableBikes'].toString(),
                Icons.check_circle,
                [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.4),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'home.active_rentals'.tr(),
                dashboardStats!['activeRentals'].toString(),
                Icons.receipt_long,
                [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.4),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'home.today_revenue'.tr(),
                '${NumberFormat('#,##0').format(dashboardStats!['totalRevenue'])} ₫',
                Icons.monetization_on,
                [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.4),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation,
      shape: Theme.of(context).cardTheme.shape,
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              Theme.of(context).cardTheme.shape != null
                  ? (Theme.of(context).cardTheme.shape
                          as RoundedRectangleBorder)
                      .borderRadius
                  : BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ), // Dùng màu đầu tiên của gradient cho icon
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final List<Widget> featureCards = [
      _buildFeatureCard(
        context,
        'home.bike_list'.tr(),
        'home.view_all_bikes'.tr(),
        Icons.motorcycle,
        Theme.of(context).primaryColor,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BikeListScreen()),
        ),
      ),

      _buildFeatureCard(
        context,
        'home.payment'.tr(),
        'home.manage_payments'.tr(),
        Icons.payment,
        Theme.of(context).primaryColor,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PaymentListScreen()),
        ),
      ),
      _buildFeatureCard(
        context,
        'home.statistics'.tr(),
        'home.view_statistics'.tr(),
        Icons.bar_chart,
        Theme.of(context).primaryColor,
        () => Navigator.pushNamed(context, '/statistics'),
      ),
      _buildFeatureCard(
        context,
        'home.customers'.tr(),
        'home.manage_customers'.tr(),
        Icons.person,
        Theme.of(context).primaryColor,
        () => Navigator.pushNamed(context, '/user-list'),
      ),
    ];

    if (isAdmin) {
      // Thêm các tính năng dành cho admin
      featureCards.add(
        _buildFeatureCard(
          context,
          'home.brands'.tr(),
          'home.manage_brands'.tr(),
          Icons.branding_watermark,
          Theme.of(context).primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BrandListScreen()),
          ),
        ),
      );
      featureCards.add(
        _buildFeatureCard(
          context,
          'admin.staff_management'.tr(),
          'admin.staff_management'.tr(),
          Icons.people,
          Theme.of(context).primaryColor,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StaffManagementScreen()),
          ),
        ),
      );
    }

    final isLandscape = ResponsiveHelper.isLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Tính toán số cột dựa trên kích thước màn hình và hướng
    int crossAxisCount = 2; // Mặc định là 2 cột
    double childAspectRatio = 1.1; // Tỷ lệ mặc định

    if (screenWidth > 600) {
      // Tablet hoặc màn hình lớn
      crossAxisCount = isLandscape ? 4 : 3;
      childAspectRatio = isLandscape ? 1.5 : 1.2;
    } else {
      // Điện thoại
      crossAxisCount = isLandscape ? 3 : 2;
      // Điều chỉnh tỷ lệ khi xoay ngang để tránh tràn
      childAspectRatio = isLandscape ? 1.8 : 1.1;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: childAspectRatio,
      children: featureCards,
    );
  }
}

Widget _buildFeatureCard(
  BuildContext context,
  String title,
  String subtitle,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  final isLandscape = ResponsiveHelper.isLandscape(context);
  final theme = Theme.of(context);

  // Tính toán kích thước icon và padding dựa trên kích thước và hướng màn hình
  final double iconSize = ResponsiveHelper.responsiveValue(
    context: context,
    mobile: isLandscape ? 16 : 20,
    tablet: isLandscape ? 20 : 24,
  );

  final double cardPadding = ResponsiveHelper.responsiveValue(
    context: context,
    mobile: isLandscape ? 8 : 12,
    tablet: isLandscape ? 12 : 16,
  );

  final double titleFontSize = ResponsiveHelper.adaptiveFontSize(
    context,
    isLandscape ? 14 : 16,
  );
  final double subtitleFontSize = ResponsiveHelper.adaptiveFontSize(
    context,
    isLandscape ? 10 : 12,
  );

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isLandscape ? 6 : 8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.primaryColor, size: iconSize),
              ),
              Spacer(flex: 1),
              Flexible(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isLandscape ? 2 : 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: subtitleFontSize,
                        color: theme.textTheme.bodyMedium!.color!.withOpacity(
                          0.6,
                        ),
                      ),
                      maxLines: isLandscape ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
