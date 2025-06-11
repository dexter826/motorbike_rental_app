import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/services/bike_service.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

class ManageBikeScreen extends StatefulWidget {
  final Bike? bike;
  final Function? onBikeUpdated;

  const ManageBikeScreen({super.key, this.bike, this.onBikeUpdated});

  @override
  _ManageBikeScreenState createState() => _ManageBikeScreenState();
}

class _ManageBikeScreenState extends State<ManageBikeScreen> {
  final BikeService _bikeService = BikeService();
  final BrandService _brandService = BrandService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _licensePlateController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  String name = '';
  String brand = '';
  String brandId = '';
  String type = '';
  String licensePlate = '';
  int quantity = 0;
  double price = 0;
  String status = '';
  bool _isLoading = false;
  File? _imageFile;
  String? _currentImageUrl;

  late Future<List<Brand>> _brands;

  List<String> bikeTypes = [];

  @override
  void initState() {
    super.initState();
    _brands = _brandService.getBrands();

    // Initialize status with constant value
    status = BikeStatusConstants.available;

    // Initialize bike types with constant values
    bikeTypes = BikeTypeConstants.getAllTypes();

    _nameController = TextEditingController(text: widget.bike?.name ?? '');
    _licensePlateController = TextEditingController(
      text: widget.bike?.licensePlate ?? '',
    );
    _quantityController = TextEditingController(
      text:
          widget.bike?.quantity == 0
              ? ''
              : widget.bike?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.bike?.price == 0 ? '' : widget.bike?.price.toString() ?? '',
    );

    if (widget.bike != null) {
      name = widget.bike!.name;
      brandId = widget.bike!.brandId;
      _brandService.getBrandById(widget.bike!.brandId).then((brandObj) {
        if (brandObj != null) {
          setState(() {
            brand = brandObj.name;
          });
        }
      });
      type = widget.bike!.type;
      licensePlate = widget.bike!.licensePlate;
      quantity = widget.bike!.quantity;
      price = widget.bike!.price;
      status = widget.bike!.status;
      _currentImageUrl = widget.bike!.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _currentImageUrl;

    try {
      final String fileName =
          'bikes/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String downloadUrl = await _storageService.uploadFile(
        _imageFile!,
        fileName,
      );
      return downloadUrl;
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'admin.error'.tr(),
          message: 'admin.bike.upload_error'.tr(),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
    return null;
  }

  Future<void> _saveBike() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final String? imageUrl = await _uploadImage();

        final bike = Bike(
          id:
              widget.bike?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          brandId: brandId,
          type: type,
          licensePlate: licensePlate,
          quantity: quantity,
          price: price,
          status: status,
          imageUrl: imageUrl ?? _currentImageUrl ?? '',
        );

        if (widget.bike == null) {
          await _bikeService.addBike(bike);
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'admin.success'.tr(),
              message: 'admin.bike.add_success'.tr(),
              contentType: ContentType.success,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        } else {
          await _bikeService.updateBike(bike);
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'admin.success'.tr(),
              message: 'admin.bike.update_success'.tr(),
              contentType: ContentType.success,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }

        if (widget.onBikeUpdated != null) {
          Future.microtask(() => widget.onBikeUpdated!());
        }

        Navigator.pop(context);
      } catch (e) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'admin.error'.tr(),
            message: 'admin.bike.save_error'.tr(),
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licensePlateController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.bike == null
              ? 'admin.bike.add_bike'.tr()
              : 'admin.bike.edit_bike'.tr(),
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.appBarTheme.backgroundColor ?? Colors.black,
              theme.scaffoldBackgroundColor,
            ],
            stops: [0.0, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: FutureBuilder<List<Brand>>(
                future: _brands,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: AppLoadingIndicator(
                        color: theme.progressIndicatorTheme.color!,
                        size: 50,
                        message: 'admin.bike.loading'.tr(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(height: 16),
                          Text(
                            '${'admin.bike.error'.tr()}: ${snapshot.error}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 60,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'admin.bike.no_brand_data'.tr(),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  return Card(
                    elevation: theme.cardTheme.elevation,
                    shape: theme.cardTheme.shape,
                    color: theme.cardTheme.color,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'admin.bike.bike_info'.tr(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),

                            // Image picker
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: theme.inputDecorationTheme.fillColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child:
                                    _imageFile != null
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            _imageFile!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                        : (_currentImageUrl != null &&
                                                _currentImageUrl!.isNotEmpty
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: CachedNetworkImage(
                                                imageUrl: _currentImageUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                placeholder:
                                                    (context, url) => Center(
                                                      child: CircularProgressIndicator(
                                                        color:
                                                            theme
                                                                .progressIndicatorTheme
                                                                .color!,
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            size: 60,
                                                            color: theme
                                                                .colorScheme
                                                                .error
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                        ),
                                              ),
                                            )
                                            : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 60,
                                                  color: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color
                                                      ?.withOpacity(0.6),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'admin.bike.select_image'
                                                      .tr(),
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: theme
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color
                                                            ?.withOpacity(0.6),
                                                      ),
                                                ),
                                              ],
                                            )),
                              ),
                            ),
                            SizedBox(height: 16),

                            CustomTextFormField(
                              label: 'admin.bike.bike_name'.tr(),
                              prefixIcon: Icons.motorcycle,
                              controller: _nameController,
                              onChanged: (val) => setState(() => name = val),
                              validator:
                                  (val) =>
                                      val!.isEmpty
                                          ? 'admin.bike.enter_bike_name'.tr()
                                          : null,
                            ),
                            SizedBox(height: 16),
                            CustomTextFormField(
                              label: 'admin.bike.license_plate'.tr(),
                              prefixIcon: Icons.confirmation_number,
                              controller: _licensePlateController,
                              onChanged:
                                  (val) => setState(() => licensePlate = val),
                              validator:
                                  (val) =>
                                      val!.isEmpty
                                          ? 'admin.bike.enter_license_plate'
                                              .tr()
                                          : null,
                            ),
                            SizedBox(height: 16),
                            CustomTextFormField(
                              label: 'admin.bike.quantity'.tr(),
                              prefixIcon: Icons.numbers,
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (val) => setState(
                                    () => quantity = int.tryParse(val) ?? 0,
                                  ),
                              validator:
                                  (val) =>
                                      val!.isEmpty
                                          ? 'admin.bike.enter_quantity'.tr()
                                          : null,
                            ),
                            SizedBox(height: 16),
                            CustomTextFormField(
                              label: 'admin.bike.price_per_day'.tr(),
                              prefixIcon: Icons.attach_money,
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              onChanged:
                                  (val) => setState(
                                    () => price = double.tryParse(val) ?? 0,
                                  ),
                              validator:
                                  (val) =>
                                      val!.isEmpty
                                          ? 'admin.bike.enter_price'.tr()
                                          : null,
                            ),
                            SizedBox(height: 16),

                            // Brand dropdown
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'admin.bike.brand_label'.tr(),
                                prefixIcon: Icon(
                                  Icons.business,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              value: brandId.isNotEmpty ? brandId : null,
                              hint: Text(
                                'admin.bike.select_brand'.tr(),
                                style: theme.textTheme.bodyMedium,
                              ),
                              items:
                                  snapshot.data!.map((Brand brandItem) {
                                    return DropdownMenuItem<String>(
                                      value: brandItem.id,
                                      child: Text(
                                        brandItem.name,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  brandId = newValue ?? '';
                                  if (newValue != null) {
                                    final selectedBrand = snapshot.data!
                                        .firstWhere(
                                          (b) => b.id == newValue,
                                          orElse: () => Brand(id: '', name: ''),
                                        );
                                    brand = selectedBrand.name;
                                  }
                                });
                              },
                              validator:
                                  (val) =>
                                      val == null
                                          ? 'admin.bike.select_brand'.tr()
                                          : null,
                            ),
                            SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'admin.bike.bike_type_label'.tr(),
                                prefixIcon: Icon(
                                  Icons.category,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              value: type.isEmpty ? null : type,
                              hint: Text(
                                'admin.bike.select_type'.tr(),
                                style: theme.textTheme.bodyMedium,
                              ),
                              items:
                                  bikeTypes.map((String type) {
                                    return DropdownMenuItem<String>(
                                      value: type,
                                      child: Text(
                                        BikeTypeConstants.getTranslationKey(
                                          type,
                                        ).tr(),
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  type = newValue ?? '';
                                });
                              },
                              validator:
                                  (val) =>
                                      val == null
                                          ? 'admin.bike.select_type'.tr()
                                          : null,
                            ),
                            SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'admin.bike.status'.tr(),
                                prefixIcon: Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              value: status,
                              items:
                                  BikeStatusConstants.getAllStatuses().map((
                                    String value,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value == BikeStatusConstants.available
                                            ? 'admin.bike.available'.tr()
                                            : 'admin.bike.unavailable'.tr(),
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  status =
                                      newValue ?? BikeStatusConstants.available;
                                });
                              },
                            ),
                            SizedBox(height: 32),

                            ElevatedButton(
                              style: theme.elevatedButtonTheme.style?.copyWith(
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.symmetric(vertical: 16),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              onPressed: _isLoading ? null : _saveBike,
                              child:
                                  _isLoading
                                      ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        widget.bike == null
                                            ? 'admin.bike.add_bike'.tr()
                                            : 'admin.bike.save'.tr(),
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme
                                                      .elevatedButtonTheme
                                                      .style
                                                      ?.foregroundColor
                                                      ?.resolve({})!,
                                            ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
