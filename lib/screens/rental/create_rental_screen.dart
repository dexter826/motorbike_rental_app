import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/models/rental.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/services/rental_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class CreateRentalScreen extends StatefulWidget {
  final String bikeId;
  final String userId;
  final bool isExtension;
  final Rental? existingRental;

  const CreateRentalScreen({
    super.key,
    required this.bikeId,
    required this.userId,
    this.isExtension = false,
    this.existingRental,
  });

  @override
  _CreateRentalScreenState createState() => _CreateRentalScreenState();
}

class _CreateRentalScreenState extends State<CreateRentalScreen> {
  final RentalService _rentalService = RentalService();
  final BikeService _bikeService = BikeService();
  final BrandService _brandService = BrandService();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();

  // Ngày bắt đầu - cho rental mới là hôm nay, cho extension là ngày kết thúc hiện tại
  late Timestamp startTime;
  Timestamp? endTime;
  int quantity = 1;
  Timestamp? createdAt = Timestamp.now();
  double totalAmount = 0;
  double extensionAmount = 0; // Phí gia hạn riêng biệt
  Bike? bike;
  Brand? bikeBrand;
  String userName = '';
  bool _isLoading = true;
  bool _isSubmitting = false;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.isExtension && widget.existingRental != null) {
      // Chế độ gia hạn: ngày bắt đầu là ngày kết thúc hiện tại
      startTime = Timestamp.fromDate(widget.existingRental!.endTime);
      quantity = widget.existingRental!.quantity;
    } else {
      // Chế độ tạo mới: ngày bắt đầu là hôm nay
      startTime = Timestamp.fromDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final loadedBike = await _bikeService.getBikeById(widget.bikeId);
      final user = await _userService.getUserById(widget.userId);

      Brand? brand;
      try {
        // Lấy thông tin Brand từ BrandService
        brand = await _brandService.getBrandById(loadedBike.brandId);
      } catch (e) {
        print('Error fetching brand: $e');
      }

      setState(() {
        bike = loadedBike;
        bikeBrand = brand;
        userName = user?.name ?? 'Người dùng';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          contentType: ContentType.failure,
          title: 'common.error'.tr(),
          message: 'rental.load_error'.tr(),
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  void _calculateTotalAmount() {
    if (endTime != null && bike != null) {
      final days = endTime!.toDate().difference(startTime.toDate()).inDays;
      if (days > 0) {
        setState(() {
          if (widget.isExtension) {
            // Chế độ gia hạn: chỉ tính phí cho thời gian gia hạn
            extensionAmount = quantity * bike!.price * days;
            totalAmount = extensionAmount;
          } else {
            // Chế độ tạo mới: tính tổng phí thuê
            totalAmount = quantity * bike!.price * days;
          }
        });
      } else {
        final snackBar = SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            contentType: ContentType.warning,
            title: 'common.notification'.tr(),
            message:
                widget.isExtension
                    ? 'rental.extension_date_after_current'.tr()
                    : 'rental.end_date_after_today'.tr(),
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.isExtension
              ? 'rental.extend_rental'.tr()
              : 'rental.add_rental'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.primaryColor,
                  size: 30,
                ),
              )
              : bike == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'rental.bike_not_found'.tr(),
                      style: theme.textTheme.bodyLarge,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.back'.tr()),
                    ),
                  ],
                ),
              )
              : Container(
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Bike and User Info Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.motorcycle,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'rental.bike_info'.tr(),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  _infoRow(
                                    '${'bike.bike_name'.tr()}:',
                                    bike!.name,
                                  ),
                                  _infoRow(
                                    '${'bike.bike_brand'.tr()}:',
                                    bikeBrand!.name,
                                  ),
                                  _infoRow(
                                    '${'bike.bike_type'.tr()}:',
                                    BikeTypeConstants.getTranslationKey(
                                      bike!.type,
                                    ).tr(),
                                  ),
                                  _infoRow(
                                    '${'rental.rental_price'.tr()}:',
                                    currencyFormat.format(bike!.price),
                                  ),
                                  _infoRow(
                                    '${'bike.available_quantity'.tr()}:',
                                    bike!.quantity.toString(),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: theme.colorScheme.primary,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'rental.customer_info'.tr(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  _infoRow(
                                    '${'rental.customer_name'.tr()}:',
                                    userName,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Rental Form Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.edit_document,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          size: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'rental.rental_details'.tr(),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Divider(),
                                    SizedBox(height: 8),

                                    // Quantity Field - chỉ hiển thị cho chế độ tạo mới
                                    if (!widget.isExtension) ...[
                                      CustomTextFormField(
                                        label: 'rental.quantity'.tr(),
                                        prefixIcon: Icons.numbers,
                                        controller: null,
                                        keyboardType: TextInputType.number,
                                        initialValue: '1',
                                        onChanged: (val) {
                                          setState(() {
                                            quantity = int.tryParse(val) ?? 1;
                                            _calculateTotalAmount();
                                          });
                                        },
                                        validator: (val) {
                                          int? q = int.tryParse(val ?? '');
                                          if (q == null || q <= 0) {
                                            return 'rental.quantity_must_be_positive'
                                                .tr();
                                          }
                                          if (q > bike!.quantity) {
                                            return 'rental.quantity_exceeds_available'
                                                .tr(
                                                  namedArgs: {
                                                    '0': '${bike!.quantity}',
                                                  },
                                                );
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16),
                                    ] else ...[
                                      // Hiển thị thông tin số lượng đã thuê cho extension mode
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 128),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 77),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.numbers,
                                              color: theme.colorScheme.primary,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '${'rental.quantity'.tr()}: $quantity',
                                                style: TextStyle(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                    ],

                                    // Thông tin ngày bắt đầu
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(
                                              alpha: 128,
                                            ), // 50% opacity
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(
                                                alpha: 77,
                                              ), // 30% opacity
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info,
                                            color: theme.colorScheme.primary,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.isExtension
                                                  ? '${'rental.current_end_date'.tr()}: ${DateFormat('dd/MM/yyyy').format(startTime.toDate())}'
                                                  : '${'rental.start_date'.tr()}: ${DateFormat('dd/MM/yyyy').format(DateTime.now())} (${'rental.today'.tr()})',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 16),

                                    // Chọn ngày kết thúc
                                    _datePickerField(
                                      label:
                                          widget.isExtension
                                              ? 'rental.new_end_date'.tr()
                                              : 'rental.end_time'.tr(),
                                      value: endTime?.toDate(),
                                      onTap: () async {
                                        final DateTime minDate =
                                            widget.isExtension
                                                ? startTime.toDate().add(
                                                  Duration(days: 1),
                                                )
                                                : DateTime.now().add(
                                                  Duration(days: 1),
                                                );

                                        final DateTime? picked =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: minDate,
                                              firstDate: minDate,
                                              lastDate: DateTime(2100),
                                            );
                                        if (picked != null) {
                                          setState(() {
                                            endTime = Timestamp.fromDate(
                                              picked,
                                            );
                                            _calculateTotalAmount();
                                          });
                                        }
                                      },
                                    ),

                                    SizedBox(height: 24),

                                    // Total Amount Display
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(
                                              alpha: 128,
                                            ), // 50% opacity
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(
                                                alpha: 77,
                                              ), // 30% opacity
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            widget.isExtension
                                                ? '${'rental.extension_fee'.tr()}:'
                                                : '${'rental.estimated_price'.tr()}:',
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          Text(
                                            currencyFormat.format(totalAmount),
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    SizedBox(height: 24),

                                    // Submit Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            _isSubmitting
                                                ? null
                                                : () async {
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      endTime != null) {
                                                    // So sánh ngày kết thúc với ngày bắt đầu
                                                    final endDate =
                                                        endTime!.toDate();
                                                    final startDate =
                                                        startTime.toDate();

                                                    if (endDate.isBefore(
                                                          startDate,
                                                        ) ||
                                                        endDate
                                                            .isAtSameMomentAs(
                                                              startDate,
                                                            )) {
                                                      final snackBar = SnackBar(
                                                        elevation: 0,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: AwesomeSnackbarContent(
                                                          contentType:
                                                              ContentType
                                                                  .warning,
                                                          title:
                                                              'common.notification'
                                                                  .tr(),
                                                          message:
                                                              'rental.end_date_after_today'
                                                                  .tr(),
                                                        ),
                                                      );
                                                      ScaffoldMessenger.of(
                                                          context,
                                                        )
                                                        ..hideCurrentSnackBar()
                                                        ..showSnackBar(
                                                          snackBar,
                                                        );
                                                      return;
                                                    }

                                                    setState(() {
                                                      _isSubmitting = true;
                                                    });

                                                    try {
                                                      if (widget.isExtension) {
                                                        // Logic gia hạn
                                                        await _rentalService
                                                            .updateRentalEndDate(
                                                              rentalId:
                                                                  widget
                                                                      .existingRental!
                                                                      .id,
                                                              newEndDate:
                                                                  endTime!
                                                                      .toDate(),
                                                              extensionFee:
                                                                  extensionAmount,
                                                            );

                                                        // Hiển thị thông báo gia hạn thành công
                                                        if (mounted) {
                                                          final snackBar = SnackBar(
                                                            elevation: 0,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            content: AwesomeSnackbarContent(
                                                              title:
                                                                  'common.success'
                                                                      .tr(),
                                                              message:
                                                                  'rental.extension_success'
                                                                      .tr(),
                                                              contentType:
                                                                  ContentType
                                                                      .success,
                                                            ),
                                                          );
                                                          ScaffoldMessenger.of(
                                                              context,
                                                            )
                                                            ..hideCurrentSnackBar()
                                                            ..showSnackBar(
                                                              snackBar,
                                                            );

                                                          // Quay về màn hình trước
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        }
                                                      } else {
                                                        // Logic tạo rental mới
                                                        final rental = Rental(
                                                          id:
                                                              UniqueKey()
                                                                  .toString(),
                                                          bikeId: widget.bikeId,
                                                          userId: widget.userId,
                                                          quantity: quantity,
                                                          createdAt:
                                                              createdAt!
                                                                  .toDate(),
                                                          totalAmount:
                                                              totalAmount,
                                                          startTime:
                                                              startTime
                                                                  .toDate(),
                                                          endTime:
                                                              endTime!.toDate(),
                                                          status:
                                                              RentalStatusConstants
                                                                  .ongoing,
                                                          returnedDate: null,
                                                          cancelledAt: null,
                                                        );

                                                        await _rentalService
                                                            .addRental(rental);
                                                        await _bikeService
                                                            .updateBikeQuantity(
                                                              widget.bikeId,
                                                              bike!.quantity -
                                                                  quantity,
                                                            );

                                                        // Hiển thị thông báo tạo thành công
                                                        if (mounted) {
                                                          final snackBar = SnackBar(
                                                            elevation: 0,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            behavior:
                                                                SnackBarBehavior
                                                                    .floating,
                                                            content: AwesomeSnackbarContent(
                                                              title:
                                                                  'common.success'
                                                                      .tr(),
                                                              message:
                                                                  'rental.create_success_no_prepayment'
                                                                      .tr(),
                                                              contentType:
                                                                  ContentType
                                                                      .success,
                                                            ),
                                                          );
                                                          ScaffoldMessenger.of(
                                                              context,
                                                            )
                                                            ..hideCurrentSnackBar()
                                                            ..showSnackBar(
                                                              snackBar,
                                                            );

                                                          // Chuyển về home screen
                                                          Navigator.of(
                                                            context,
                                                          ).pushNamedAndRemoveUntil(
                                                            '/home',
                                                            (route) => false,
                                                          );
                                                        }
                                                      }
                                                    } catch (e) {
                                                      final snackBar = SnackBar(
                                                        elevation: 0,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        content: AwesomeSnackbarContent(
                                                          contentType:
                                                              ContentType
                                                                  .failure,
                                                          title:
                                                              'common.error'
                                                                  .tr(),
                                                          message:
                                                              widget.isExtension
                                                                  ? 'rental.extension_error'
                                                                      .tr()
                                                                  : 'rental.create_error'
                                                                      .tr(),
                                                        ),
                                                      );
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                            context,
                                                          )
                                                          ..hideCurrentSnackBar()
                                                          ..showSnackBar(
                                                            snackBar,
                                                          );
                                                      }
                                                    } finally {
                                                      setState(() {
                                                        _isSubmitting = false;
                                                      });
                                                    }
                                                  } else if (endTime == null) {
                                                    final snackBar = SnackBar(
                                                      elevation: 0,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      behavior:
                                                          SnackBarBehavior
                                                              .floating,
                                                      content: AwesomeSnackbarContent(
                                                        title:
                                                            'common.notification'
                                                                .tr(),
                                                        message:
                                                            'rental.please_select_end_date'
                                                                .tr(),
                                                        contentType:
                                                            ContentType.warning,
                                                      ),
                                                    );
                                                    ScaffoldMessenger.of(
                                                        context,
                                                      )
                                                      ..hideCurrentSnackBar()
                                                      ..showSnackBar(snackBar);
                                                  }
                                                },
                                        child:
                                            _isSubmitting
                                                ? Center(
                                                  child:
                                                      LoadingAnimationWidget.fourRotatingDots(
                                                        color:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .onPrimary,
                                                        size: 30,
                                                      ),
                                                )
                                                : Text(
                                                  widget.isExtension
                                                      ? 'rental.confirm_extension'
                                                          .tr()
                                                      : 'rental.create_rental'
                                                          .tr(),
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            theme
                                                                .colorScheme
                                                                .onPrimary,
                                                      ),
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIconColor: Theme.of(context).colorScheme.primary,
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        child: Text(
          value != null ? dateFormat.format(value) : 'rental.choose_date'.tr(),
          style: TextStyle(
            color:
                value != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: 153,
                    ), // 60% opacity
          ),
        ),
      ),
    );
  }
}
