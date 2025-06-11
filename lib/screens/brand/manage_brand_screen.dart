import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/brand.dart';
import 'package:bike_rental_app/services/brand_service.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:country_picker/country_picker.dart';

class ManageBrandScreen extends StatefulWidget {
  final Brand? brand;

  const ManageBrandScreen({super.key, this.brand});

  @override
  _ManageBrandScreenState createState() => _ManageBrandScreenState();
}

class _ManageBrandScreenState extends State<ManageBrandScreen> {
  final _formKey = GlobalKey<FormState>();
  final BrandService _brandService = BrandService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _logoUrlController;
  late TextEditingController _countryController;

  bool _isLoading = false;
  bool _isSubmitting = false;
  File? _selectedImage;
  bool _showUrlField = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.brand?.description ?? '',
    );
    _logoUrlController = TextEditingController(
      text: widget.brand?.logoUrl ?? '',
    );
    _countryController = TextEditingController(
      text: widget.brand?.country ?? '',
    );

    // Hiển thị URL field nếu đã có URL
    _showUrlField =
        widget.brand?.logoUrl != null && widget.brand!.logoUrl!.isNotEmpty;

    // Nếu có dữ liệu country, sử dụng giá trị text
    // Country sẽ được chọn khi người dùng sử dụng country picker
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'admin.brand.image_error'.tr(),
          message: 'admin.brand.image_error_message'.tr().replaceAll(
            '{error}',
            e.toString(),
          ),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? takenImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (takenImage != null) {
        setState(() {
          _selectedImage = File(takenImage.path);
        });
      }
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'admin.brand.camera_error'.tr(),
          message: 'admin.brand.camera_error_message'.tr().replaceAll(
            '{error}',
            e.toString(),
          ),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'admin.brand.select_logo'.tr(),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library, color: Colors.blue),
                  ),
                  title: Text('admin.brand.from_gallery'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.green),
                  ),
                  title: Text('admin.brand.take_photo'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.link, color: Colors.purple),
                  ),
                  title: Text('admin.brand.enter_url'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _showUrlField = true;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveBrand() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        String? logoUrl = _logoUrlController.text;

        // Upload image if selected
        if (_selectedImage != null) {
          final String brandId = widget.brand?.id ?? Uuid().v4();
          final String fileName =
              'brand_logo_${brandId}_${DateTime.now().millisecondsSinceEpoch}';
          logoUrl = await _storageService.uploadFile(_selectedImage!, fileName);
        }

        Brand brand = Brand(
          id: widget.brand?.id ?? Uuid().v4(),
          name: _nameController.text,
          description: _descriptionController.text,
          logoUrl: logoUrl.isEmpty ? null : logoUrl,
          country: _countryController.text,
        );

        if (widget.brand == null) {
          await _brandService.addBrand(brand);
          _showSuccessSnackBar('admin.brand.add_success'.tr());
        } else {
          await _brandService.updateBrand(brand);
          _showSuccessSnackBar('admin.brand.update_success'.tr());
        }
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('${'admin.error'.tr()}: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'admin.success'.tr(),
        message: message,
        contentType: ContentType.success,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  void _showErrorSnackBar(String message) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'admin.error'.tr(),
        message: message,
        contentType: ContentType.failure,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.brand == null
              ? 'admin.brand.add_brand'.tr()
              : 'admin.brand.update_brand'.tr(),
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          if (widget.brand != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showDeleteConfirmation();
              },
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: AppLoadingIndicator(color: theme.primaryColor, size: 30),
              )
              : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image picker section
                          Center(
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _showImagePickerOptions,
                                  child: Container(
                                    height: 120,
                                    width: 120,
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    child:
                                        (_selectedImage != null ||
                                                (widget.brand?.logoUrl !=
                                                        null &&
                                                    widget
                                                        .brand!
                                                        .logoUrl!
                                                        .isNotEmpty))
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child:
                                                  _selectedImage != null
                                                      ? Image.file(
                                                        _selectedImage!,
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Image.network(
                                                        widget.brand!.logoUrl!,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null)
                                                            return child;
                                                          return Center(
                                                            child: CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                              .expectedTotalBytes !=
                                                                          null
                                                                      ? loadingProgress
                                                                              .cumulativeBytesLoaded /
                                                                          loadingProgress
                                                                              .expectedTotalBytes!
                                                                      : null,
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 40,
                                                              color:
                                                                  theme
                                                                      .hintColor,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                            )
                                            : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_photo_alternate,
                                                  size: 40,
                                                  color: theme.hintColor,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'admin.brand.add_logo'.tr(),
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: theme.hintColor,
                                                      ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextButton.icon(
                                  icon: Icon(Icons.photo_camera),
                                  label: Text('admin.brand.choose_image'.tr()),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
                                  ),
                                  onPressed: _showImagePickerOptions,
                                ),
                              ],
                            ),
                          ),

                          if (_showUrlField)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 10),
                                Text(
                                  'admin.brand.logo_url'.tr(),
                                  style: theme.textTheme.titleSmall,
                                ),
                                SizedBox(height: 6),
                                Stack(
                                  children: [
                                    CustomTextFormField(
                                      label: 'admin.brand.logo_url'.tr(),
                                      controller: _logoUrlController,
                                      hintText:
                                          'admin.brand.enter_logo_url'.tr(),
                                      prefixIcon: Icons.link,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _logoUrlController.text = '';
                                            _showUrlField = false;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                          SizedBox(height: 20),
                          Text(
                            'admin.brand.basic_info'.tr(),
                            style: theme.textTheme.titleLarge,
                          ),

                          SizedBox(height: 16),
                          Text(
                            'admin.brand.brand_name'.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          SizedBox(height: 6),
                          CustomTextFormField(
                            label: 'admin.brand.brand_name'.tr(),
                            controller: _nameController,
                            hintText: 'admin.brand.enter_brand_name'.tr(),
                            prefixIcon: Icons.business,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'admin.brand.brand_name_required'.tr();
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16),
                          Text(
                            'admin.brand.country'.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              showCountryPicker(
                                context: context,
                                showPhoneCode: false,
                                countryListTheme: CountryListThemeData(
                                  flagSize: 25,
                                  backgroundColor:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                  ),
                                  bottomSheetHeight: 500,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20.0),
                                    topRight: Radius.circular(20.0),
                                  ),
                                  inputDecoration: InputDecoration(
                                    labelText: 'admin.brand.search'.tr(),
                                    hintText: 'admin.brand.search_country'.tr(),
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withAlpha(50),
                                      ),
                                    ),
                                  ),
                                ),
                                onSelect: (Country country) {
                                  setState(() {
                                    _countryController.text = country.name;
                                  });
                                },
                              );
                            },
                            child: AbsorbPointer(
                              child: CustomTextFormField(
                                controller: _countryController,
                                label: 'admin.brand.country_origin'.tr(),
                                hintText: 'admin.brand.enter_country'.tr(),
                                prefixIcon: Icons.public,
                                filled: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'admin.brand.country_required'.tr();
                                  }
                                  return null;
                                },
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16),
                          Text(
                            'admin.brand.description'.tr(),
                            style: theme.textTheme.titleSmall,
                          ),
                          SizedBox(height: 6),
                          CustomTextFormField(
                            controller: _descriptionController,
                            label: 'admin.brand.brand_description'.tr(),
                            hintText: 'admin.brand.enter_description'.tr(),
                            filled: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'admin.brand.description_required'.tr();
                              }
                              return null;
                            },
                            maxLines: 4,
                          ),

                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _saveBrand,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  _isSubmitting
                                      ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: AppLoadingIndicator(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              size: 20,
                                              type:
                                                  LoadingIndicatorType
                                                      .fourRotatingDots,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'admin.brand.processing'.tr(),
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onPrimary,
                                                ),
                                          ),
                                        ],
                                      )
                                      : Text(
                                        widget.brand == null
                                            ? 'admin.brand.add_brand'.tr()
                                            : 'admin.brand.update_brand'.tr(),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
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

  void _showDeleteConfirmation() {
    PanaraConfirmDialog.show(
      context,
      title: "admin.brand.confirm_delete".tr(),
      message: "admin.brand.confirm_delete_message".tr().replaceAll(
        '{name}',
        widget.brand?.name ?? '',
      ),
      confirmButtonText: "admin.brand.delete".tr(),
      cancelButtonText: "admin.brand.cancel".tr(),
      textColor: Theme.of(context).primaryColor,
      onTapCancel: () {
        Navigator.pop(context);
      },
      onTapConfirm: () async {
        Navigator.pop(context);
        setState(() {
          _isLoading = true;
        });
        try {
          await _brandService.deleteBrand(widget.brand!.id);
          Navigator.of(context).pop();
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'admin.brand.deleted'.tr(),
              message: 'admin.brand.deleted_message'.tr().replaceAll(
                '{name}',
                widget.brand!.name,
              ),
              contentType: ContentType.success,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          final snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
              title: 'admin.error'.tr(),
              message: 'admin.brand.delete_error'.tr(),
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        }
      },
      panaraDialogType: PanaraDialogType.custom,
      color: Theme.of(context).primaryColor,
      barrierDismissible: false,
    );
  }
}
