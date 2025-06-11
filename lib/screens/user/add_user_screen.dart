import 'dart:io';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/user.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';
import 'package:bike_rental_app/widgets/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String idCard = '';
  DateTime dateOfBirth = DateTime.now().subtract(
    const Duration(days: 365 * 18),
  ); // Mặc định là 18 tuổi trước
  bool _isLoading = false;
  File? _imageFile;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final String fileName =
          'users/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String downloadUrl = await _storageService.uploadFile(
        _imageFile!,
        fileName,
      );
      return downloadUrl;
    } catch (e) {
      if (!mounted) return null;

      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'common.error'.tr(),
          message: 'user.image_upload_error'.tr(),
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: context.locale,
    );
    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
      });
    }
  }

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra trùng lặp dữ liệu
      final validationResult = await _userService.validateUserData(
        email: email,
        phone: phone,
        idCard: idCard,
      );

      if (!mounted) return;

      // Nếu có lỗi bắt buộc (ID Card hoặc Email trùng)
      if (!validationResult['isValid']) {
        final errors = validationResult['errors'] as List<String>;
        _showErrorDialog('Dữ liệu không hợp lệ', errors.join('\n'));
        return;
      }

      // Nếu có cảnh báo về số điện thoại
      final warnings = validationResult['warnings'] as List<String>;
      if (warnings.isNotEmpty) {
        final shouldContinue = await _showWarningDialog(
          'Cảnh báo',
          warnings.first,
        );
        if (!shouldContinue) return;
      }

      final String? imageUrl = await _uploadImage();

      if (!mounted) return;

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        phone: phone,
        imageUrl: imageUrl,
        address: address,
        idCard: idCard,
        dateOfBirth: dateOfBirth,
      );

      await _userService.addUser(user);

      if (!mounted) return;

      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'common.success'.tr(),
          message: 'user.add_success'.tr(),
          contentType: ContentType.success,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'common.error'.tr(),
          message: 'user.add_error'.tr(),
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Hiển thị dialog lỗi
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Đóng',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog cảnh báo với tùy chọn tiếp tục
  Future<bool> _showWarningDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Tiếp tục',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Widget cho form thêm người dùng
  Widget _buildUserForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'user.user_information'.tr(),
            style: TextStyle(
              fontSize: ResponsiveHelper.adaptiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Profile image
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    backgroundImage:
                        _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : const AssetImage(
                              'assets/images/default_avatar.jpg',
                            ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.camera_alt,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          CustomTextFormField(
            label: 'user.full_name'.tr(),
            prefixIcon: Icons.person,
            onChanged: (val) => setState(() => name = val),
            validator: (val) => val!.isEmpty ? 'user.name_required'.tr() : null,
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            label: 'user.email'.tr(),
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) => setState(() => email = val),
            validator: (val) {
              if (val!.isEmpty) {
                return 'user.email_required'.tr();
              }
              bool emailValid = RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(val);
              return emailValid ? null : 'user.invalid_email'.tr();
            },
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            label: 'user.phone'.tr(),
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            onChanged: (val) => setState(() => phone = val),
            validator: (val) {
              if (val!.isEmpty) {
                return 'user.phone_required'.tr();
              }
              bool phoneValid = RegExp(r'^\+?[0-9]{10,12}$').hasMatch(val);
              return phoneValid ? null : 'user.invalid_phone'.tr();
            },
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            label: 'user.address'.tr(),
            prefixIcon: Icons.location_on,
            onChanged: (val) => setState(() => address = val),
            validator:
                (val) => val!.isEmpty ? 'user.address_required'.tr() : null,
          ),
          const SizedBox(height: 16),

          CustomTextFormField(
            label: 'user.id_card'.tr(),
            prefixIcon: Icons.credit_card,
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => idCard = val),
            validator: (val) {
              if (val!.isEmpty) {
                return 'user.id_card_required'.tr();
              }
              bool idCardValid = RegExp(r'^[0-9]{9,12}$').hasMatch(val);
              return idCardValid ? null : 'user.invalid_id_card'.tr();
            },
          ),
          const SizedBox(height: 16),

          // Date of birth picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'user.date_of_birth'.tr(),
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(dateOfBirth),
                    style: TextStyle(
                      fontSize: ResponsiveHelper.adaptiveFontSize(context, 16),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _isLoading ? null : _addUser,
            child:
                _isLoading
                    ? LoadingAnimationWidget.fourRotatingDots(
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    )
                    : Text(
                      'user.add_user'.tr(),
                      style: TextStyle(
                        fontSize: ResponsiveHelper.adaptiveFontSize(
                          context,
                          16,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = ResponsiveHelper.isLandscape(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'user.add_new_user'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.primary.withAlpha(51),
            height: 1.0,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.onPrimary,
              Theme.of(context).colorScheme.primary,
            ],
            stops: const [0.0, 0.9],
          ),
        ),
        child: SafeArea(
          child: ResponsiveLayout(
            mobile: SingleChildScrollView(
              padding: ResponsiveHelper.adaptivePadding(context),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: ResponsiveHelper.adaptivePadding(context),
                  child: _buildUserForm(),
                ),
              ),
            ),
            tablet: Center(
              child: SizedBox(
                width: isLandscape ? 700 : 500,
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.adaptivePadding(context),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: ResponsiveHelper.adaptivePadding(context),
                      child: _buildUserForm(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
