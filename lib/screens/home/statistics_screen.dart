import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/payment_service.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/services/report_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  final RentalService _rentalService = RentalService();
  final PaymentService _paymentService = PaymentService();
  final ReportService _reportService = ReportService();

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isSaving = false;
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  // Thêm bộ lọc thời gian
  String _timeFilter = 'week'; // 'day', 'week', 'month', 'quarter', 'year'
  DateTime? _startDate;
  DateTime? _endDate;

  // Thêm biến để lưu trữ dữ liệu thống kê
  int _totalRentals = 0;
  double _totalRevenue = 0;
  double _totalCompensation = 0;
  int _completedRentals = 0;
  double _totalLateFee = 0;

  // Thêm biến để lưu trữ dữ liệu so sánh với kỳ trước
  double _revenueGrowth = 0;
  double _rentalGrowth = 0;

  // Thêm biến để lưu trữ dữ liệu thống kê theo phương thức thanh toán
  Map<String, int> _methodCounts = {};
  Map<String, double> _methodRevenues = {};

  Map<DateTime, List<Rental>> _dailyRentals = {};
  Map<DateTime, List<Payment>> _dailyPayments = {};

  // Thêm biến để lưu trữ dữ liệu biểu đồ
  List<FlSpot> _revenueSpots = [];
  List<String> _chartLabels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setTimeFilter('week'); // Mặc định lọc theo tuần
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cập nhật bộ lọc thời gian
  void _setTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;

      // Tính toán khoảng thời gian dựa trên bộ lọc
      final now = DateTime.now();
      switch (filter) {
        case 'day':
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          // Tính ngày đầu tuần (thứ 2)
          final weekDay = now.weekday;
          final daysFromMonday = weekDay - 1; // 0 = Monday, 6 = Sunday
          _startDate = DateTime(now.year, now.month, now.day - daysFromMonday);
          _endDate = DateTime(
            now.year,
            now.month,
            now.day + (6 - daysFromMonday),
            23,
            59,
            59,
          );
          break;
        case 'month':
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case 'quarter':
          final quarter = (now.month - 1) ~/ 3;
          _startDate = DateTime(now.year, quarter * 3 + 1, 1);
          _endDate = DateTime(now.year, (quarter + 1) * 3 + 1, 0, 23, 59, 59);
          break;
        case 'year':
          _startDate = DateTime(now.year, 1, 1);
          _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        default:
          _startDate = DateTime(now.year, now.month, now.day - 7);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });

    // Tải dữ liệu với khoảng thời gian mới
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sử dụng các phương thức mới với bộ lọc thời gian
      final rentals = await _rentalService.getRentals(
        startDate: _startDate,
        endDate: _endDate,
        limit: 1000, // Lấy nhiều hơn để tính toán chính xác
      );

      // Lấy dữ liệu thanh toán (chỉ lấy các thanh toán đã hoàn thành)
      final payments = await _paymentService.getPayments(
        startDate: _startDate,
        endDate: _endDate,
        status: PaymentStatusConstants.completed, // Sử dụng constant
        limit: 1000,
      );

      // Debug: In ra để kiểm tra
      print('Date range: $_startDate to $_endDate');
      print('Payments loaded: ${payments.length}');
      for (var payment in payments) {
        print(
          'Payment: ${payment.id}, Date: ${payment.paymentDate}, Amount: ${payment.amount}, Status: ${payment.status}',
        );
      }

      // Lấy thống kê doanh thu (đã được lọc trong service)
      final revenueStats = await _paymentService.getRevenueStats(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Lấy số lượng đơn hoàn thành
      final completedCount = await _rentalService.getRentalCount(
        startDate: _startDate,
        endDate: _endDate,
        status: RentalStatusConstants.completed,
      );

      // Tính toán tăng trưởng so với kỳ trước
      await _calculateGrowth();

      // Nhóm dữ liệu theo ngày
      _groupByDate(rentals, payments);

      // Cập nhật biếu đồ
      _prepareChartData(payments);

      if (!mounted) return;

      setState(() {
        _totalRentals = rentals.length;
        _completedRentals = completedCount;
        _totalRevenue = revenueStats['totalRevenue'] as double;
        _totalCompensation = revenueStats['totalCompensation'] as double;
        _totalLateFee = revenueStats['totalLateFee'] as double;
        _methodCounts = Map<String, int>.from(
          revenueStats['methodCounts'] as Map,
        );
        _methodRevenues = Map<String, double>.from(
          revenueStats['methodRevenues'] as Map,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          contentType: ContentType.failure,
          message: 'statistics.loading_error'.tr(),
          title: 'statistics.notification'.tr(),
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  // Tính toán tăng trưởng so với kỳ trước
  Future<void> _calculateGrowth() async {
    try {
      // Tính khoảng thời gian của kỳ trước chính xác hơn
      final currentPeriodDuration =
          _endDate!.difference(_startDate!).inDays + 1;
      final previousStartDate = _startDate!.subtract(
        Duration(days: currentPeriodDuration),
      );
      final previousEndDate = _startDate!.subtract(Duration(days: 1));

      // Lấy dữ liệu doanh thu của kỳ trước
      final previousRevenueStats = await _paymentService.getRevenueStats(
        startDate: previousStartDate,
        endDate: previousEndDate,
      );

      // Lấy số lượng đơn thuê của kỳ trước
      final previousRentalCount = await _rentalService.getRentalCount(
        startDate: previousStartDate,
        endDate: previousEndDate,
      );

      // Tính tăng trưởng doanh thu
      final previousRevenue = previousRevenueStats['totalRevenue'] as double;
      if (previousRevenue > 0) {
        _revenueGrowth =
            (_totalRevenue - previousRevenue) / previousRevenue * 100;
      } else {
        _revenueGrowth = _totalRevenue > 0 ? 100 : 0;
      }

      // Tính tăng trưởng số lượng đơn thuê
      if (previousRentalCount > 0) {
        _rentalGrowth =
            (_totalRentals - previousRentalCount) / previousRentalCount * 100;
      } else {
        _rentalGrowth = _totalRentals > 0 ? 100 : 0;
      }
    } catch (e) {
      // Xử lý lỗi khi tính tăng trưởng
      _revenueGrowth = 0;
      _rentalGrowth = 0;
    }
  }

  // Chuẩn bị dữ liệu cho biểu đồ
  void _prepareChartData(List<Payment> payments) {
    _revenueSpots = [];
    _chartLabels = [];

    // Nhóm thanh toán theo ngày
    Map<DateTime, double> dailyRevenue = {};

    // Tạo danh sách các ngày trong khoảng thời gian (sử dụng add để tránh lỗi tháng)
    final days = _endDate!.difference(_startDate!).inDays + 1;
    for (int i = 0; i < days; i++) {
      final date = _startDate!.add(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);
      dailyRevenue[dateKey] = 0;
    }

    // Tính tổng doanh thu theo ngày
    for (var payment in payments) {
      final date = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      if (dailyRevenue.containsKey(date)) {
        dailyRevenue[date] = (dailyRevenue[date] ?? 0) + payment.amount;
      } else {
        // Debug: In ra để kiểm tra
        print(
          'Payment date not in range: $date, Payment amount: ${payment.amount}',
        );
        print('Available dates: ${dailyRevenue.keys.toList()}');
      }
    }

    // Chuyển dữ liệu sang dạng biểu đồ (sắp xếp theo thứ tự thời gian)
    final sortedEntries =
        dailyRevenue.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    int index = 0;
    for (var entry in sortedEntries) {
      _revenueSpots.add(FlSpot(index.toDouble(), entry.value));
      _chartLabels.add('${entry.key.day}/${entry.key.month}');
      index++;
    }

    // Debug: In ra để kiểm tra
    print('Chart data prepared: ${_revenueSpots.length} points');
    print('Revenue spots: $_revenueSpots');
  }

  void _groupByDate(List<Rental> rentals, List<Payment> payments) {
    _dailyRentals = {};
    _dailyPayments = {};

    for (var rental in rentals) {
      final date = DateTime(
        rental.startTime.year,
        rental.startTime.month,
        rental.startTime.day,
      );
      if (!_dailyRentals.containsKey(date)) {
        _dailyRentals[date] = [];
      }
      _dailyRentals[date]!.add(rental);
    }

    for (var payment in payments) {
      final date = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      if (!_dailyPayments.containsKey(date)) {
        _dailyPayments[date] = [];
      }
      _dailyPayments[date]!.add(payment);
    }
  }

  List<Rental> _getRentalsForSelectedDate() {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return _dailyRentals[date] ?? [];
  }

  List<Payment> _getPaymentsForSelectedDate() {
    final date = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return _dailyPayments[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'statistics.title'.tr(),
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          // Nút lưu báo cáo
          _isSaving
              ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(
                  Icons.save_alt,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'statistics.save_report'.tr(),
                onPressed: _saveReport,
              ),
          // Nút xuất báo cáo
          _isExporting
              ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              )
              : IconButton(
                icon: Icon(
                  Icons.visibility,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'statistics.preview_report'.tr(),
                onPressed: _exportReport,
              ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).appBarTheme.foregroundColor,
          unselectedLabelColor: Theme.of(
            context,
          ).appBarTheme.foregroundColor?.withValues(alpha: 179), // 70% opacity
          tabs: [
            Tab(text: 'statistics.overview'.tr()),
            Tab(text: 'statistics.daily_stats'.tr()),
          ],
        ),
      ),
      body: Column(
        children: [
          // Bộ lọc thời gian
          _buildTimeFilter(),

          // Nội dung chính
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: LoadingAnimationWidget.fourRotatingDots(
                        color: Theme.of(context).progressIndicatorTheme.color!,
                        size: 50,
                      ),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildDailyStatisticsTab(),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  // Xây dựng bộ lọc thời gian
  Widget _buildTimeFilter() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 26), // 10% opacity
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFilterChip('statistics.day'.tr(), 'day'),
            SizedBox(width: 8),
            _buildFilterChip('statistics.week'.tr(), 'week'),
            SizedBox(width: 8),
            _buildFilterChip('statistics.month'.tr(), 'month'),
            SizedBox(width: 8),
            _buildFilterChip('statistics.quarter'.tr(), 'quarter'),
            SizedBox(width: 8),
            _buildFilterChip('statistics.year'.tr(), 'year'),
            SizedBox(width: 16),
            // Hiển thị khoảng thời gian đang chọn
            if (_startDate != null && _endDate != null)
              Text(
                '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  // Xây dựng chip lọc
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _timeFilter == value;
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _setTimeFilter(value);
        }
      },
      backgroundColor: theme.cardTheme.color,
      selectedColor: theme.primaryColor.withValues(alpha: 51), // 20% opacity
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Container(
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ thống kê tổng quan
            _buildSummaryCards(),
            SizedBox(height: 24),

            // Thông tin tăng trưởng
            _buildGrowthInfo(),
            SizedBox(height: 24),

            // Biểu đồ doanh thu
            Text(
              'statistics.revenue_over_time'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSimpleRevenueChart(),
            SizedBox(height: 24),

            // Biểu đồ phương thức thanh toán
            Text(
              'statistics.payment_methods'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildPaymentMethodList(),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Xây dựng thông tin tăng trưởng
  Widget _buildGrowthInfo() {
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Xác định layout dựa trên hướng màn hình
    final useRowLayout = isLandscape || MediaQuery.of(context).size.width > 600;

    // Tạo các thẻ tăng trưởng
    final revenueGrowthCard = _buildGrowthCard(
      title: 'statistics.revenue_growth'.tr(),
      value: _revenueGrowth,
      icon: Icons.trending_up,
    );

    final rentalGrowthCard = _buildGrowthCard(
      title: 'statistics.rental_growth'.tr(),
      value: _rentalGrowth,
      icon: Icons.trending_up,
    );

    // Hiển thị theo hàng hoặc cột tùy theo hướng màn hình
    if (useRowLayout) {
      return Row(
        children: [
          Expanded(child: revenueGrowthCard),
          SizedBox(width: 16),
          Expanded(child: rentalGrowthCard),
        ],
      );
    } else {
      return Column(
        children: [revenueGrowthCard, SizedBox(height: 16), rentalGrowthCard],
      );
    }
  }

  // Xây dựng thẻ tăng trưởng
  Widget _buildGrowthCard({
    required String title,
    required double value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isPositive = value >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final iconData = isPositive ? Icons.trending_up : Icons.trending_down;

    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: color, size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 153,
                    ), // 60% opacity
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${value.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'statistics.compared_to_previous'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 153,
                    ), // 60% opacity
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Tính toán số cột dựa trên kích thước màn hình và hướng
    int crossAxisCount = 2; // Mặc định là 2 cột

    if (screenWidth > 600) {
      // Tablet hoặc màn hình lớn
      crossAxisCount = isLandscape ? 4 : 2;
    } else {
      // Điện thoại
      crossAxisCount = isLandscape ? 4 : 2;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: ResponsiveHelper.responsiveValue(
        context: context,
        mobile: 12,
        tablet: 16,
      ),
      mainAxisSpacing: ResponsiveHelper.responsiveValue(
        context: context,
        mobile: 12,
        tablet: 16,
      ),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: List.generate(
        5,
        (index) => AnimationHelper.fadeInUp(
          duration: Duration(milliseconds: 500),
          delay: Duration(milliseconds: index * 100),
          child:
              [
                _buildSummaryCard(
                  title: 'statistics.total_rentals'.tr(),
                  value: '$_totalRentals',
                  icon: Icons.directions_bike,
                  color: Theme.of(context).primaryColor,
                ),
                _buildSummaryCard(
                  title: 'statistics.revenue'.tr(),
                  value: NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(_totalRevenue),
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                _buildSummaryCard(
                  title: 'statistics.compensation'.tr(),
                  value: NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(_totalCompensation),
                  icon: Icons.healing,
                  color: Colors.orange,
                ),
                _buildSummaryCard(
                  title: 'statistics.late_fee'.tr(),
                  value: NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(_totalLateFee),
                  icon: Icons.timer_off,
                  color: Colors.amber[700]!,
                ),
                _buildSummaryCard(
                  title: 'statistics.completed_rentals'.tr(),
                  value: '$_completedRentals',
                  icon: Icons.check_circle,
                  color: Colors.purple,
                ),
                _buildSummaryCard(
                  title: 'statistics.total_all_revenue'.tr(),
                  value: NumberFormat.currency(
                    locale: 'vi_VN',
                    symbol: '₫',
                  ).format(_totalRevenue + _totalCompensation + _totalLateFee),
                  icon: Icons.account_balance_wallet,
                  color: Colors.teal,
                ),
              ][index],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    Key? key,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final theme = Theme.of(context);

    // Tính toán kích thước icon và padding dựa trên hướng màn hình
    final double iconSize = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: isLandscape ? 30 : 40,
      tablet: isLandscape ? 36 : 48,
    );

    final double cardPadding = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: isLandscape ? 12 : 16,
      tablet: isLandscape ? 14 : 20,
    );

    final double titleFontSize = ResponsiveHelper.adaptiveFontSize(
      context,
      isLandscape ? 12 : 14,
    );

    final double valueFontSize = ResponsiveHelper.adaptiveFontSize(
      context,
      isLandscape ? 16 : 18,
    );

    return Card(
      key: key,
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimationHelper.bounce(
              duration: Duration(milliseconds: 800),
              child: Icon(icon, size: iconSize, color: color),
            ),
            SizedBox(height: isLandscape ? 4 : 8),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 153,
                ), // 60% opacity
                fontSize: titleFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isLandscape ? 4 : 8),
            AnimationHelper.scale(
              duration: Duration(milliseconds: 600),
              child: Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleRevenueChart() {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final theme = Theme.of(context);

    // Điều chỉnh chiều cao của biểu đồ dựa trên hướng màn hình
    final chartHeight = ResponsiveHelper.responsiveValue(
      context: context,
      mobile: isLandscape ? 180.0 : 220.0,
      tablet: isLandscape ? 200.0 : 250.0,
    );

    // Kiểm tra nếu không có dữ liệu
    if (_revenueSpots.isEmpty) {
      return SizedBox(
        height: chartHeight,
        child: Center(
          child: Text(
            'statistics.no_revenue_data'.tr(),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Tìm giá trị lớn nhất để đặt tỷ lệ trục Y
    double maxY = 0;
    for (var spot in _revenueSpots) {
      if (spot.y > maxY) maxY = spot.y;
    }

    // Đảm bảo maxY luôn lớn hơn 0
    maxY =
        maxY <= 0 ? 1000 : maxY * 1.2; // Thêm 20% để có khoảng trống phía trên

    return AnimationHelper.fadeInUp(
      duration: Duration(milliseconds: 800),
      child: SizedBox(
        height: chartHeight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 5,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withValues(
                      alpha: 77,
                    ), // 30% opacity
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withValues(
                      alpha: 77,
                    ), // 30% opacity
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < _chartLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _chartLabels[value.toInt()],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: ResponsiveHelper.adaptiveFontSize(
                                context,
                                isLandscape ? 9 : 11,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY / 5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        NumberFormat.compact().format(value),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: ResponsiveHelper.adaptiveFontSize(
                            context,
                            isLandscape ? 9 : 11,
                          ),
                        ),
                        textAlign: TextAlign.left,
                      );
                    },
                    reservedSize: 40,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                  left: BorderSide(color: theme.dividerColor, width: 1),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              minX: 0,
              maxX: _revenueSpots.length.toDouble() - 1,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  spots: _revenueSpots,
                  isCurved: true,
                  color: theme.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: theme.primaryColor,
                        strokeWidth: 2,
                        strokeColor: theme.cardTheme.color!,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.primaryColor.withValues(
                      alpha: 51,
                    ), // 20% opacity
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor:
                      (touchedSpot) =>
                          theme.cardTheme.color!.withValues(alpha: 230),
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      final value = barSpot.y;
                      return LineTooltipItem(
                        '${_chartLabels[index]}\n',
                        TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: NumberFormat.currency(
                              locale: 'vi_VN',
                              symbol: '₫',
                            ).format(value),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodList() {
    final theme = Theme.of(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Sử dụng dữ liệu từ _methodCounts đã được tính toán trong _loadData
    if (_methodCounts.isEmpty) {
      return Center(
        child: Text(
          'statistics.no_payment_data'.tr(),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    // Tính tổng số giao dịch
    final totalTransactions = _methodCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    // Tạo danh sách các mục cho biểu đồ tròn
    List<PieChartSectionData> sections = [];
    List<Widget> indicators = [];

    // Tạo màu sắc cho từng phương thức thanh toán
    _methodCounts.forEach((method, count) {
      final color = _getColorForPaymentMethod(method);
      final percentage =
          totalTransactions > 0 ? (count / totalTransactions * 100) : 0.0;

      // Thêm phần cho biểu đồ tròn
      sections.add(
        PieChartSectionData(
          color: color,
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      // Thêm chỉ báo cho biểu đồ
      indicators.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getPaymentMethodDisplayName(method),
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '$count ${'statistics.transactions'.tr()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    });

    // Xây dựng layout khác nhau cho màn hình ngang và dọc
    if (isLandscape || MediaQuery.of(context).size.width > 600) {
      // Layout ngang cho màn hình rộng
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Biểu đồ tròn
          Expanded(
            flex: 3,
            child: AspectRatio(
              aspectRatio: 1,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),

          // Chỉ báo
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: indicators,
              ),
            ),
          ),
        ],
      );
    } else {
      // Layout dọc cho màn hình hẹp
      return Column(
        children: [
          // Biểu đồ tròn
          AspectRatio(
            aspectRatio: 1.3,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),

          // Chỉ báo
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: indicators,
            ),
          ),
        ],
      );
    }
  }

  // Lấy tên hiển thị cho phương thức thanh toán
  String _getPaymentMethodDisplayName(String method) {
    if (method == PaymentMethodConstants.cash) {
      return 'payment.cash'.tr();
    } else if (method == PaymentMethodConstants.vnpay) {
      return 'payment.vnpay'.tr();
    } else {
      return method;
    }
  }

  Color _getColorForPaymentMethod(String method) {
    // So sánh trực tiếp với constants thay vì dịch
    if (method == PaymentMethodConstants.cash) {
      return Colors.green;
    } else if (method == PaymentMethodConstants.vnpay) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  Widget _buildDailyStatisticsTab() {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final rentals = _getRentalsForSelectedDate();
    final payments = _getPaymentsForSelectedDate();

    double dailyRevenue = payments.fold(
      0,
      (sum, payment) => sum + payment.amount,
    );
    double dailyCompensation = payments.fold(
      0,
      (sum, payment) => sum + (payment.damageCompensation ?? 0),
    );

    // Xác định bố cục dựa trên kích thước và hướng màn hình
    final bool useGridLayout = isLandscape || screenWidth > 600;

    // Tính toán chiều cao tối đa cho danh sách đơn thuê
    final double listViewHeight =
        isLandscape
            ? MediaQuery.of(context).size.height *
                0.3 // Chiều cao nhỏ hơn khi xoay ngang
            : MediaQuery.of(context).size.height *
                0.5; // Chiều cao lớn hơn khi xoay dọc

    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context: context,
          mobile: 12,
          tablet: 16,
        ),
      ),
      // Bọc Column trong SingleChildScrollView để tránh tràn màn hình
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateSelector(),
            SizedBox(height: isLandscape ? 16 : 24),
            if (useGridLayout)
              // Hiển thị dạng lưới cho màn hình ngang hoặc tablet
              GridView.count(
                crossAxisCount: isLandscape ? 4 : 2,
                crossAxisSpacing: ResponsiveHelper.responsiveValue(
                  context: context,
                  mobile: 12,
                  tablet: 16,
                ),
                mainAxisSpacing: ResponsiveHelper.responsiveValue(
                  context: context,
                  mobile: 12,
                  tablet: 16,
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildSummaryCard(
                    title: 'statistics.rental_count'.tr(),
                    value: '${rentals.length}',
                    icon: Icons.directions_bike,
                    color: Theme.of(context).primaryColor,
                  ),
                  _buildSummaryCard(
                    title: 'statistics.revenue'.tr(),
                    value: NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                    ).format(dailyRevenue),
                    icon: Icons.monetization_on,
                    color: Colors.green,
                  ),
                  _buildSummaryCard(
                    title: 'statistics.compensation'.tr(),
                    value: NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '₫',
                    ).format(dailyCompensation),
                    icon: Icons.healing,
                    color: Colors.orange,
                  ),
                  _buildSummaryCard(
                    title: 'statistics.completed_rentals'.tr(),
                    value:
                        '${rentals.where((r) => r.status == RentalStatusConstants.completed).length}',
                    icon: Icons.check_circle,
                    color: Colors.purple,
                  ),
                ],
              )
            else
              // Hiển thị dạng cột cho màn hình dọc
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'statistics.rental_count'.tr(),
                          value: '${rentals.length}',
                          icon: Icons.directions_bike,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'statistics.revenue'.tr(),
                          value: NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                          ).format(dailyRevenue),
                          icon: Icons.monetization_on,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'statistics.compensation'.tr(),
                          value: NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                          ).format(dailyCompensation),
                          icon: Icons.healing,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'statistics.compensation_rate'.tr(),
                          value:
                              dailyRevenue > 0
                                  ? '${(dailyCompensation / dailyRevenue * 100).toStringAsFixed(1)}%'
                                  : '0%',
                          icon: Icons.assessment,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (!useGridLayout) SizedBox(height: 24),
            Text(
              'statistics.rental_details'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: ResponsiveHelper.adaptiveFontSize(
                  context,
                  isLandscape ? 16 : 18,
                ),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // Thay thế Expanded bằng SizedBox có chiều cao cố định
            SizedBox(
              height: rentals.isEmpty ? 50 : listViewHeight,
              child:
                  rentals.isEmpty
                      ? Center(
                        child: Text(
                          'statistics.no_rentals_for_day'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                      : ListView.builder(
                        itemCount: rentals.length,
                        itemBuilder: (context, index) {
                          final rental = rentals[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            elevation: Theme.of(context).cardTheme.elevation,
                            shape: Theme.of(context).cardTheme.shape,
                            color: Theme.of(context).cardTheme.color,
                            child: ListTile(
                              title: Text(
                                '${'statistics.rental_id'.tr()}${rental.id.substring(0, 8)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                '${'statistics.rental_date'.tr()}: ${DateFormat('dd/MM/yyyy').format(rental.startTime)}\n'
                                '${'statistics.status'.tr()}: ${rental.status}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'vi_VN',
                                  symbol: '₫',
                                ).format(rental.totalAmount),
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
            ),
            // Thêm padding ở dưới cùng để tránh nội dung bị che khuất
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(Duration(days: 1));
            });
          },
        ),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).primaryColor.withAlpha(26), // 10% opacity (255 * 0.1 = 25.5)
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).primaryColor,
          ),
          onPressed:
              DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                  ).isBefore(
                    DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      DateTime.now().day,
                    ),
                  )
                  ? () {
                    setState(() {
                      _selectedDate = _selectedDate.add(Duration(days: 1));
                    });
                  }
                  : null,
        ),
      ],
    );
  }

  // Lưu báo cáo PDF
  Future<void> _saveReport() async {
    try {
      setState(() {
        _isSaving = true;
      });

      // Xác định loại báo cáo dựa trên tab hiện tại
      final currentTab = _tabController.index;

      if (currentTab == 0) {
        // Lưu báo cáo tổng quan
        final pdfData = await _reportService.generateOverviewReport(
          startDate: _startDate!,
          endDate: _endDate!,
          totalRentals: _totalRentals,
          totalRevenue: _totalRevenue,
          totalCompensation: _totalCompensation,
          totalLateFee: _totalLateFee,
          completedRentals: _completedRentals,
          methodCounts: _methodCounts,
          methodRevenues: _methodRevenues,
          revenueGrowth: _revenueGrowth,
          rentalGrowth: _rentalGrowth,
        );

        // Lưu báo cáo
        await _reportService.saveReport(
          pdfData,
          'BaoCaoTongQuan_${DateFormat('ddMMyyyy').format(_startDate!)}_${DateFormat('ddMMyyyy').format(_endDate!)}.pdf',
        );
      } else {
        // Lưu báo cáo theo ngày
        final rentals = _getRentalsForSelectedDate();
        final payments = _getPaymentsForSelectedDate();

        // Tính tổng doanh thu và tiền đền bù trong ngày
        double dailyRevenue = 0;
        double dailyCompensation = 0;

        for (var payment in payments) {
          dailyRevenue += payment.amount;
          dailyCompensation += payment.damageCompensation ?? 0;
        }

        final pdfData = await _reportService.generateDailyReport(
          selectedDate: _selectedDate,
          rentals: rentals,
          payments: payments,
          dailyRevenue: dailyRevenue,
          dailyCompensation: dailyCompensation,
        );

        // Lưu báo cáo
        await _reportService.saveReport(
          pdfData,
          'BaoCaoNgay_${DateFormat('ddMMyyyy').format(_selectedDate)}.pdf',
        );
      }

      // Hiển thị thông báo thành công
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            contentType: ContentType.success,
            message: 'statistics.save_success'.tr(),
            title: 'statistics.success'.tr(),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            contentType: ContentType.failure,
            message: '${'statistics.save_error'.tr()}: $e',
            title: 'statistics.error'.tr(),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Xuất báo cáo PDF (Preview)
  Future<void> _exportReport() async {
    try {
      setState(() {
        _isExporting = true;
      });

      // Xác định loại báo cáo dựa trên tab hiện tại
      final currentTab = _tabController.index;

      if (currentTab == 0) {
        // Xuất báo cáo tổng quan
        final pdfData = await _reportService.generateOverviewReport(
          startDate: _startDate!,
          endDate: _endDate!,
          totalRentals: _totalRentals,
          totalRevenue: _totalRevenue,
          totalCompensation: _totalCompensation,
          totalLateFee: _totalLateFee,
          completedRentals: _completedRentals,
          methodCounts: _methodCounts,
          methodRevenues: _methodRevenues,
          revenueGrowth: _revenueGrowth,
          rentalGrowth: _rentalGrowth,
        );

        // Hiển thị báo cáo
        await _reportService.showReport(
          pdfData,
          '${'statistics.overview_report'.tr()} ${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
        );
      } else {
        // Xuất báo cáo theo ngày
        final rentals = _getRentalsForSelectedDate();
        final payments = _getPaymentsForSelectedDate();

        // Tính tổng doanh thu và tiền đền bù trong ngày
        double dailyRevenue = 0;
        double dailyCompensation = 0;

        for (var payment in payments) {
          dailyRevenue += payment.amount;
          dailyCompensation += payment.damageCompensation ?? 0;
        }

        final pdfData = await _reportService.generateDailyReport(
          selectedDate: _selectedDate,
          rentals: rentals,
          payments: payments,
          dailyRevenue: dailyRevenue,
          dailyCompensation: dailyCompensation,
        );

        // Hiển thị báo cáo
        await _reportService.showReport(
          pdfData,
          '${'statistics.daily_report'.tr()} ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
        );
      }
    } catch (e) {
      // Hiển thị thông báo lỗi
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            contentType: ContentType.failure,
            message: '${'statistics.export_error'.tr()}: $e',
            title: 'statistics.error'.tr(),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
