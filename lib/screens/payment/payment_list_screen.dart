import 'package:bike_rental_app/models/payment.dart';
import 'package:bike_rental_app/screens/payment/create_payment_screen.dart';
import 'package:bike_rental_app/services/payment_service.dart';
import 'package:bike_rental_app/widgets/payment_item.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  _PaymentListScreenState createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  final PaymentService _paymentService = PaymentService();
  late Future<List<Payment>> _payments;
  String _filterStatus = 'All';
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  // Date range filter
  DateTime? _startDate;
  DateTime? _endDate;

  // Sorting
  String _sortBy =
      'date_desc'; // Options: date_desc, date_asc, amount_desc, amount_asc

  @override
  void initState() {
    super.initState();
    _loadPayments();

    // Add listener to search controller
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPayments() {
    setState(() {
      _payments = _paymentService.getPayments();
    });
  }

  // Check if any filters are active
  bool _hasActiveFilters() {
    return _filterStatus != 'All' ||
        _startDate != null ||
        _endDate != null ||
        _searchQuery.isNotEmpty;
  }

  // Build a filter chip widget
  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveValue(
          context: context,
          mobile: 8,
          tablet: 12,
        ),
        vertical: isLandscape ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 12),
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Icon(
              Icons.close,
              size: isLandscape ? 14 : 16,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Show filter dialog
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String tempStatus = _filterStatus;
        DateTime? tempStartDate = _startDate;
        DateTime? tempEndDate = _endDate;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('payment.filter_payments'.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filter
                    Text(
                      '${'payment.status'.tr()}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterOption(
                          'payment.all'.tr(),
                          'All',
                          tempStatus,
                          (value) {
                            setState(() => tempStatus = value);
                          },
                        ),
                        _buildFilterOption(
                          'payment.completed'.tr(),
                          PaymentStatusConstants.completed,
                          tempStatus,
                          (value) {
                            setState(() => tempStatus = value);
                          },
                        ),
                        _buildFilterOption(
                          'payment.pending'.tr(),
                          PaymentStatusConstants.pending,
                          tempStatus,
                          (value) {
                            setState(() => tempStatus = value);
                          },
                        ),
                        _buildFilterOption(
                          'payment.failed'.tr(),
                          PaymentStatusConstants.failed,
                          tempStatus,
                          (value) {
                            setState(() => tempStatus = value);
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Date range filter
                    Text(
                      '${'payment.date_range'.tr()}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tempStartDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => tempStartDate = date);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tempStartDate != null
                                    ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(tempStartDate!)
                                    : 'payment.from_date'.tr(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: tempEndDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now().add(
                                  Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setState(() => tempEndDate = date);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tempEndDate != null
                                    ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(tempEndDate!)
                                    : 'payment.to_date'.tr(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _filterStatus = tempStatus;
                      _startDate = tempStartDate;
                      _endDate = tempEndDate;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('payment.apply'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build a filter option for the dialog
  Widget _buildFilterOption(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              groupValue == value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                groupValue == value
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Show sort dialog
  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String tempSortBy = _sortBy;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('payment.sort_payments'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSortOption(
                    'payment.newest'.tr(),
                    'date_desc',
                    tempSortBy,
                    (value) {
                      setState(() => tempSortBy = value);
                    },
                  ),
                  _buildSortOption(
                    'payment.oldest'.tr(),
                    'date_asc',
                    tempSortBy,
                    (value) {
                      setState(() => tempSortBy = value);
                    },
                  ),
                  _buildSortOption(
                    'payment.highest_value'.tr(),
                    'amount_desc',
                    tempSortBy,
                    (value) {
                      setState(() => tempSortBy = value);
                    },
                  ),
                  _buildSortOption(
                    'payment.lowest_value'.tr(),
                    'amount_asc',
                    tempSortBy,
                    (value) {
                      setState(() => tempSortBy = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _sortBy = tempSortBy;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('payment.apply'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Build a sort option for the dialog
  Widget _buildSortOption(
    String label,
    String value,
    String groupValue,
    Function(String) onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (newValue) => onChanged(newValue!),
      activeColor: Theme.of(context).colorScheme.primary,
      dense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title:
            _showSearch
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'payment.search_payments'.tr(),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.primary.withAlpha(179),
                    ),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: theme.colorScheme.primary),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _showSearch = false;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.primary),
                  cursorColor: theme.colorScheme.primary,
                  autofocus: true,
                )
                : Text(
                  'payment.payments'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
        actions: [
          // Search button
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off : Icons.search,
              color: theme.colorScheme.primary,
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
          // Filter button
          IconButton(
            icon: Icon(Icons.filter_list, color: theme.colorScheme.primary),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          // Sort button
          IconButton(
            icon: Icon(Icons.sort, color: theme.colorScheme.primary),
            onPressed: () {
              _showSortDialog(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_hasActiveFilters() ? 48.0 : 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show active filters
              if (_hasActiveFilters())
                Container(
                  height: ResponsiveHelper.isLandscape(context) ? 40 : 48,
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.responsiveValue(
                      context: context,
                      mobile: 16,
                      tablet: 24,
                    ),
                    vertical: ResponsiveHelper.isLandscape(context) ? 4 : 8,
                  ),
                  width: double.infinity,
                  color: theme.colorScheme.primaryContainer.withAlpha(77),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_filterStatus != 'All')
                          _buildFilterChip(
                            'payment.status_filter'.tr(
                              args: ['$_filterStatus'],
                            ),
                            () => setState(() => _filterStatus = 'All'),
                          ),
                        if (_startDate != null)
                          _buildFilterChip(
                            'payment.from_filter'.tr(
                              args: [
                                DateFormat('dd/MM/yyyy').format(_startDate!),
                              ],
                            ),
                            () => setState(() => _startDate = null),
                          ),
                        if (_endDate != null)
                          _buildFilterChip(
                            'payment.to_filter'.tr(
                              args: [
                                DateFormat('dd/MM/yyyy').format(_endDate!),
                              ],
                            ),
                            () => setState(() => _endDate = null),
                          ),
                        if (_searchQuery.isNotEmpty)
                          _buildFilterChip(
                            'payment.search_filter'.tr(
                              namedArgs: {'query': _searchQuery},
                            ),
                            () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          ),
                        SizedBox(width: 8),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              _filterStatus = 'All';
                              _startDate = null;
                              _endDate = null;
                              _searchController.clear();
                              _searchQuery = '';
                              _sortBy = 'date_desc';
                            });
                          },
                          child: Text('common.clear_all'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.primary.withAlpha(51),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: Container(
        decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
        child: RefreshIndicator(
          onRefresh: () async {
            _loadPayments();
          },
          child: FutureBuilder<List<Payment>>(
            future: _payments,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppLoadingIndicator(
                  color: theme.colorScheme.primary,
                  message: 'common.loading'.tr(),
                );
              } else if (snapshot.hasError) {
                return AppErrorWidget(
                  message: 'common.error'.tr() + ': ${snapshot.error}',
                  onRetry: _loadPayments,
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 80,
                        color: theme.colorScheme.secondary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'payment.no_payments'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Apply filters
                List<Payment> filteredPayments = snapshot.data!;

                // Filter by status
                if (_filterStatus != 'All') {
                  filteredPayments =
                      filteredPayments
                          .where((payment) => payment.status == _filterStatus)
                          .toList();
                }

                // Filter by date range
                if (_startDate != null) {
                  filteredPayments =
                      filteredPayments
                          .where(
                            (payment) =>
                                payment.paymentDate.isAfter(_startDate!) ||
                                payment.paymentDate.isAtSameMomentAs(
                                  _startDate!,
                                ),
                          )
                          .toList();
                }

                if (_endDate != null) {
                  // Add one day to include the end date fully
                  final endDatePlusOne = _endDate!.add(Duration(days: 1));
                  filteredPayments =
                      filteredPayments
                          .where(
                            (payment) =>
                                payment.paymentDate.isBefore(endDatePlusOne),
                          )
                          .toList();
                }

                // Filter by search query
                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  filteredPayments =
                      filteredPayments
                          .where(
                            (payment) =>
                                payment.id.toLowerCase().contains(query) ||
                                payment.rentalId.toLowerCase().contains(
                                  query,
                                ) ||
                                payment.paymentMethod.toLowerCase().contains(
                                  query,
                                ),
                          )
                          .toList();
                }

                // Apply sorting
                filteredPayments.sort((a, b) {
                  switch (_sortBy) {
                    case 'date_asc':
                      return a.paymentDate.compareTo(b.paymentDate);
                    case 'amount_desc':
                      return b.amount.compareTo(a.amount);
                    case 'amount_asc':
                      return a.amount.compareTo(b.amount);
                    case 'date_desc':
                    default:
                      return b.paymentDate.compareTo(a.paymentDate);
                  }
                });

                if (filteredPayments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 80,
                          color: theme.colorScheme.secondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'payment.no_matching_payments'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPayments.length,
                  itemBuilder: (context, index) {
                    Payment payment = filteredPayments[index];
                    return AnimationHelper.fadeInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: Duration(milliseconds: 100 * index),
                      child: PaymentItem(
                        payment: payment,
                        onRefresh: _loadPayments,
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: AnimationHelper.bounce(
        child: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreatePaymentScreen()),
            ).then((_) {
              _loadPayments();
            });
          },
        ),
      ),
    );
  }
}
