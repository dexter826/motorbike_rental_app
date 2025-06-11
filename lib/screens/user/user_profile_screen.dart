import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/user.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;

  UserProfileScreen({required this.user});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _idCardController;
  late DateTime _dateOfBirth;
  File? _imageFile;
  bool _isLoading = false;
  final StorageService _storageService = StorageService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _addressController = TextEditingController(text: widget.user.address);
    _idCardController = TextEditingController(text: widget.user.idCard);
    _dateOfBirth = widget.user.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return widget.user.imageUrl;

    try {
      final String fileName = '${widget.user.id}.jpg';
      return await _storageService.uploadFile(_imageFile!, fileName);
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: AwesomeSnackbarContent(
          title: 'Lỗi',
          message: 'Tải ảnh lên thất bại',
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
      initialDate: _dateOfBirth,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Kiểm tra trùng lặp dữ liệu (loại trừ user hiện tại)
        final validationResult = await _userService.validateUserData(
          email: _emailController.text,
          phone: _phoneController.text,
          idCard: _idCardController.text,
          excludeUserId: widget.user.id, // Loại trừ user hiện tại
        );

        if (!mounted) return;

        // Nếu có lỗi bắt buộc (ID Card hoặc Email trùng)
        if (!validationResult['isValid']) {
          final errors = validationResult['errors'] as List<String>;
          _showErrorDialog('common.invalid_data'.tr(), errors.join('\n'));
          return;
        }

        // Nếu có cảnh báo về số điện thoại
        final warnings = validationResult['warnings'] as List<String>;
        if (warnings.isNotEmpty) {
          final shouldContinue = await _showWarningDialog(
            'common.warning'.tr(),
            warnings.first,
          );
          if (!shouldContinue) return;
        }

        final String? imageUrl = await _uploadImage();

        if (!mounted) return;

        final updatedUser = User(
          id: widget.user.id,
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          imageUrl: imageUrl,
          address: _addressController.text,
          idCard: _idCardController.text,
          dateOfBirth: _dateOfBirth,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.id)
            .update(updatedUser.toJson());

        if (!mounted) return;

        final snackBar = SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'common.success'.tr(),
            message: 'user.profile_updated'.tr(),
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);

        Navigator.pop(context, updatedUser);
      } catch (e) {
        if (!mounted) return;

        final snackBar = SnackBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          behavior: SnackBarBehavior.floating,
          content: AwesomeSnackbarContent(
            title: 'common.error'.tr(),
            message: 'user.update_error'.tr(),
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
                'common.close'.tr(),
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
                  child: Text(
                    'common.cancel'.tr(),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'common.continue'.tr(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'user.user_details'.tr(),
          style: TextStyle(color: theme.colorScheme.primary),
        ),
        backgroundColor: theme.colorScheme.onPrimary,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.primary.withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: LoadingAnimationWidget.fourRotatingDots(
                  color: theme.colorScheme.onPrimary,
                  size: 30,
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!) as ImageProvider
                                      : (widget.user.imageUrl != null &&
                                              widget.user.imageUrl!.isNotEmpty
                                          ? NetworkImage(widget.user.imageUrl!)
                                              as ImageProvider
                                          : AssetImage(
                                                'assets/images/default_avatar.jpg',
                                              )
                                              as ImageProvider),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: theme.colorScheme.surface,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'user.full_name'.tr(),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'user.name_required'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'user.email'.tr(),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'user.email_required'.tr();
                          }
                          if (!value.contains('@')) {
                            return 'user.invalid_email'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'user.phone'.tr(),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'user.phone_required'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'user.address'.tr(),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'user.address_required'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _idCardController,
                        decoration: InputDecoration(
                          labelText: 'user.id_card'.tr(),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: theme.primaryColor),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'user.id_card_required'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'user.date_of_birth'.tr(),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: theme.primaryColor),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_dateOfBirth),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: theme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                          ),
                          child: Text(
                            'user.save_changes'.tr(),
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
