import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/models/staff.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:bike_rental_app/services/staff_service.dart';
import 'package:bike_rental_app/services/storage_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';

class StaffManagementScreen extends StatefulWidget {
  final bool showBackButton;

  const StaffManagementScreen({super.key, this.showBackButton = true});

  @override
  _StaffManagementScreenState createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final AuthService _authService = AuthService();
  late final StaffService _staffService;
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = true;
  List<Staff> _staffList = [];
  String _searchQuery = '';
  bool _isSearching = false;
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _staffService = StaffService(authService: _authService);
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.isLoggedIn();

    if (mounted) {
      _loadStaffList();
    }
  }

  Future<void> _loadStaffList() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    if (!_authService.isAdmin) {
      if (mounted) {
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'admin.access_denied'.tr(),
            message: 'admin.access_denied_message'.tr(),
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        Navigator.pop(context);
      }
      return;
    }

    try {
      final staffList = await _staffService.getStaffList();
      // Sắp xếp theo thứ tự tạo mới nhất lên đầu
      staffList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _staffList = staffList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'admin.error'.tr(),
            message: '${'admin.error_loading_staff'.tr()}: $e',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
      }
    });
  }

  List<Staff> _getFilteredStaffList() {
    List<Staff> filteredList = List.from(_staffList);

    // Áp dụng tìm kiếm
    if (_searchQuery.isNotEmpty) {
      filteredList =
          filteredList.where((staff) {
            return staff.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                staff.email.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (staff.phoneNumber != null &&
                    staff.phoneNumber!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ));
          }).toList();
    }

    // Áp dụng lọc theo vai trò
    if (_roleFilter != 'all') {
      filteredList =
          filteredList.where((staff) => staff.role == _roleFilter).toList();
    }

    // Áp dụng lọc theo trạng thái
    if (_statusFilter != 'all') {
      filteredList =
          filteredList
              .where(
                (staff) =>
                    (_statusFilter == 'active' && staff.isActive) ||
                    (_statusFilter == 'inactive' && !staff.isActive),
              )
              .toList();
    }

    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title:
            _isSearching
                ? TextField(
                  autofocus: true,
                  style: TextStyle(color: theme.colorScheme.primary),
                  decoration: InputDecoration(
                    hintText: 'admin.search_staff'.tr(),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.primary.withAlpha(200),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                )
                : Text('admin.staff_management'.tr()),
        leading:
            widget.showBackButton
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: AppLoadingIndicator(
                  color: theme.colorScheme.primary,
                  size: 50,
                  message: 'common.loading'.tr(),
                ),
              )
              : Column(
                children: [
                  if (_roleFilter != 'all' || _statusFilter != 'all')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${'admin.filter'.tr()}: ${_roleFilter != 'all' ? (_roleFilter == 'staff' ? 'admin.staff_member'.tr() : 'admin.administrator'.tr()) : ''}${_roleFilter != 'all' && _statusFilter != 'all' ? ' - ' : ''}${_statusFilter != 'all' ? (_statusFilter == 'active' ? 'admin.active_status'.tr() : 'admin.inactive_status'.tr()) : ''}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _roleFilter = 'all';
                                _statusFilter = 'all';
                              });
                            },
                            child: Text('admin.clear_filter'.tr()),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadStaffList,
                      child:
                          _getFilteredStaffList().isEmpty
                              ? AnimationHelper.fadeIn(
                                child: Center(
                                  child: Text(
                                    'admin.no_staff_found'.tr(),
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _getFilteredStaffList().length,
                                itemBuilder: (context, index) {
                                  final staff = _getFilteredStaffList()[index];
                                  return AnimationHelper.fadeInUp(
                                    delay: Duration(milliseconds: 100 * index),
                                    child: StaffListItem(
                                      staff: staff,
                                      onRefresh: _loadStaffList,
                                      authService: _authService,
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ],
              ),
      floatingActionButton: AnimationHelper.scale(
        child: FloatingActionButton(
          onPressed: () {
            _showAddStaffDialog(context);
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AnimationHelper.fadeInUp(
            child: AlertDialog(
              title: Text('admin.filter'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'admin.role'.tr()}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _roleFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('admin.all'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('admin.administrator'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'staff',
                        child: Text('admin.staff_member'.tr()),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _roleFilter = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${'admin.status'.tr()}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('admin.all'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('admin.active_status'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('admin.inactive_status'.tr()),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _roleFilter = 'all';
                      _statusFilter = 'all';
                    });
                    Navigator.pop(context);
                  },
                  child: Text('admin.reset'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('admin.apply'.tr()),
                ),
              ],
            ),
          ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'staff'; // Vai trò mặc định
    File? selectedImage;

    showDialog(
      context: context,
      builder:
          (dialogContext) => AnimationHelper.fadeInUp(
            child: AlertDialog(
              title: Text('admin.add_new_staff'.tr()),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextFormField(
                        controller: nameController,
                        label: 'admin.full_name'.tr(),
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin.please_enter_name'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: emailController,
                        label: 'admin.email'.tr(),
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin.please_enter_email'.tr();
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'admin.please_enter_valid_email'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: passwordController,
                        label: 'admin.password'.tr(),
                        prefixIcon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin.please_enter_password'.tr();
                          }
                          if (value.length < 6) {
                            return 'admin.password_min_length'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: phoneController,
                        label: 'admin.phone'.tr(),
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'admin.please_enter_phone'.tr();
                          }
                          bool phoneValid = RegExp(
                            r'^\+?[0-9]{10,12}$',
                          ).hasMatch(val);
                          return phoneValid ? null : 'admin.invalid_phone'.tr();
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'admin.avatar'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StatefulBuilder(
                              builder: (context, setInnerState) {
                                return Column(
                                  children: [
                                    if (selectedImage != null)
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: FileImage(selectedImage!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.withOpacity(0.7),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final XFile? pickedImage =
                                            await _imagePicker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 80,
                                            );
                                        if (pickedImage != null) {
                                          setInnerState(() {
                                            selectedImage = File(
                                              pickedImage.path,
                                            );
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.photo_library),
                                      label: Text('admin.select_image'.tr()),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'admin.role'.tr(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('admin.administrator'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('admin.staff_member'.tr()),
                          ),
                        ],
                        onChanged: (value) {
                          selectedRole = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('admin.cancel'.tr()),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(
                        dialogContext,
                      ); // Đóng dialog nhập thông tin

                      // Hiển thị dialog tải
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (loadingContext) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      // Tải ảnh lên nếu có
                      String? avatarUrl;
                      if (selectedImage != null) {
                        try {
                          final String fileName =
                              'staff_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          avatarUrl = await _storageService.uploadFile(
                            selectedImage!,
                            fileName,
                          );
                        } catch (e) {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'admin.error'.tr(),
                              message:
                                  '${'admin.error_uploading_staff_image'.tr()}: $e',
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        }
                      }

                      // Thực hiện tạo nhân viên
                      final result = await _staffService.createStaff(
                        email: emailController.text,
                        password: passwordController.text,
                        name: nameController.text,
                        role: selectedRole,
                        phoneNumber: phoneController.text,
                        avatar: avatarUrl,
                      );

                      // Kiểm tra context còn hợp lệ trước khi sử dụng
                      if (!context.mounted) return;

                      // Đóng dialog tải
                      Navigator.pop(context); // Đóng dialog tải

                      if (result['success']) {
                        final snackBar = SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'admin.success'.tr(),
                            message: 'admin.add_staff_success'.tr(),
                            contentType: ContentType.success,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                        _loadStaffList();
                      } else {
                        final snackBar = SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'admin.error'.tr(),
                            message:
                                '${'admin.error_adding_staff'.tr()}: ${result['error']}',
                            contentType: ContentType.failure,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                      }
                    }
                  },
                  child: Text('admin.add'.tr()),
                ),
              ],
            ),
          ),
    );
  }
}

class StaffListItem extends StatelessWidget {
  final Staff staff;
  final Function onRefresh;
  final AuthService authService;
  late final StaffService staffService;

  StaffListItem({
    super.key,
    required this.staff,
    required this.onRefresh,
    required this.authService,
  }) {
    staffService = StaffService(authService: authService);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                staff.avatar != null && staff.avatar!.isNotEmpty
                    ? CircleAvatar(
                      radius: 25,
                      backgroundImage: NetworkImage(staff.avatar!),
                      backgroundColor: Theme.of(context).primaryColor,
                    )
                    : CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        staff.name.isNotEmpty
                            ? staff.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                const SizedBox(width: 16),
                // Staff information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.email,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        staff.role == 'admin'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    staff.role == 'admin'
                        ? 'admin.administrator'.tr().toUpperCase()
                        : 'admin.staff_member'.tr().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: staff.role == 'admin' ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        staff.isActive
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    staff.isActive
                        ? 'admin.active'.tr()
                        : 'admin.inactive'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: staff.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Action buttons in a separate row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    _showEditStaffDialog(context, staff);
                  },
                ),
                // Nút xóa nhân viên - ẩn nút xóa đối với người dùng hiện tại
                if (authService.currentStaff!.id != staff.id)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      PanaraConfirmDialog.show(
                        context,
                        title: 'admin.delete_staff'.tr(),
                        message: 'admin.delete_staff_confirm'.tr(),
                        confirmButtonText: 'common.delete'.tr(),
                        cancelButtonText: 'common.cancel'.tr(),
                        onTapCancel: () {
                          Navigator.pop(context);
                        },
                        onTapConfirm: () async {
                          Navigator.pop(context);
                          final result = await staffService.deleteStaff(
                            staff.id,
                          );

                          if (result['success']) {
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'admin.success'.tr(),
                                message: 'admin.delete_staff_success'.tr(),
                                contentType: ContentType.success,
                              ),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                            onRefresh();
                          } else {
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'admin.error'.tr(),
                                message:
                                    '${'admin.error_deleting_staff'.tr()}: ${result['error']}',
                                contentType: ContentType.failure,
                              ),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                          }
                        },
                        panaraDialogType: PanaraDialogType.normal,
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(
                    staff.isActive ? Icons.block : Icons.check_circle,
                    color: staff.isActive ? Colors.red : Colors.green,
                    size: 22,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                  onPressed: () {
                    PanaraConfirmDialog.show(
                      context,
                      title:
                          staff.isActive
                              ? 'admin.deactivate_staff'.tr()
                              : 'admin.activate_staff'.tr(),
                      message:
                          staff.isActive
                              ? 'admin.confirm_deactivate_staff'.tr()
                              : 'admin.confirm_activate_staff'.tr(),
                      confirmButtonText: 'admin.confirm'.tr(),
                      cancelButtonText: 'admin.cancel'.tr(),
                      onTapCancel: () {
                        Navigator.pop(context);
                      },
                      onTapConfirm: () async {
                        Navigator.pop(context);
                        final updatedStaff = staff.copyWith(
                          isActive: !staff.isActive,
                        );
                        final success = await staffService.updateStaff(
                          updatedStaff,
                        );

                        if (success) {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'admin.success'.tr(),
                              message:
                                  staff.isActive
                                      ? 'admin.deactivate_staff_success'.tr()
                                      : 'admin.activate_staff_success'.tr(),
                              contentType: ContentType.success,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          onRefresh();
                        } else {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'admin.error'.tr(),
                              message: 'admin.error_changing_staff_status'.tr(),
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        }
                      },
                      panaraDialogType: PanaraDialogType.normal,
                    );
                  },
                ),
                if (staff.role != 'admin' ||
                    authService.currentStaff!.id != staff.id)
                  IconButton(
                    icon: Icon(
                      staff.role == 'admin'
                          ? Icons.person
                          : Icons.admin_panel_settings,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                    onPressed: () {
                      PanaraConfirmDialog.show(
                        context,
                        title: 'admin.change_role'.tr(),
                        message:
                            staff.role == 'admin'
                                ? 'admin.change_admin_to_staff'.tr()
                                : 'admin.promote_staff_to_admin'.tr(),
                        confirmButtonText: 'admin.confirm'.tr(),
                        cancelButtonText: 'admin.cancel'.tr(),
                        onTapCancel: () {
                          Navigator.pop(context);
                        },
                        onTapConfirm: () async {
                          Navigator.pop(context);
                          final newRole =
                              staff.role == 'admin' ? 'staff' : 'admin';
                          final updatedStaff = staff.copyWith(role: newRole);
                          final success = await staffService.updateStaff(
                            updatedStaff,
                          );

                          if (success) {
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'admin.success'.tr(),
                                message: 'admin.change_role_success'.tr(),
                                contentType: ContentType.success,
                              ),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                            onRefresh();
                          } else {
                            final snackBar = SnackBar(
                              elevation: 0,
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.transparent,
                              content: AwesomeSnackbarContent(
                                title: 'admin.error'.tr(),
                                message: 'admin.error_changing_role'.tr(),
                                contentType: ContentType.failure,
                              ),
                            );
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(snackBar);
                          }
                        },
                        panaraDialogType: PanaraDialogType.normal,
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, Staff staff) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff.name);
    final phoneController = TextEditingController(
      text: staff.phoneNumber ?? '',
    );
    String selectedRole = staff.role;
    File? selectedImage;
    String? currentAvatarUrl = staff.avatar;
    final StorageService storageService = StorageService();
    final ImagePicker imagePicker = ImagePicker();
    final StaffService editStaffService = StaffService(
      authService: authService,
    );

    showDialog(
      context: context,
      builder:
          (dialogContext) => AnimationHelper.fadeInUp(
            child: AlertDialog(
              title: Text('admin.edit_staff_info'.tr()),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomTextFormField(
                        controller: nameController,
                        label: 'admin.full_name'.tr(),
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'admin.please_enter_name'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: phoneController,
                        label: 'admin.phone'.tr(),
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'admin.please_enter_phone'.tr();
                          }
                          bool phoneValid = RegExp(
                            r'^\+?[0-9]{10,12}$',
                          ).hasMatch(val);
                          return phoneValid ? null : 'admin.invalid_phone'.tr();
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'admin.avatar'.tr(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StatefulBuilder(
                              builder: (context, setInnerState) {
                                return Column(
                                  children: [
                                    if (selectedImage != null)
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: FileImage(selectedImage!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    else if (currentAvatarUrl != null &&
                                        currentAvatarUrl.isNotEmpty)
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              currentAvatarUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.withOpacity(0.2),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.withOpacity(0.7),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final XFile? pickedImage =
                                            await imagePicker.pickImage(
                                              source: ImageSource.gallery,
                                              imageQuality: 80,
                                            );
                                        if (pickedImage != null) {
                                          setInnerState(() {
                                            selectedImage = File(
                                              pickedImage.path,
                                            );
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.photo_library),
                                      label: Text('admin.select_image'.tr()),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          labelText: 'admin.role'.tr(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('admin.administrator'.tr()),
                          ),
                          DropdownMenuItem(
                            value: 'staff',
                            child: Text('admin.staff_member'.tr()),
                          ),
                        ],
                        onChanged: (value) {
                          selectedRole = value!;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('admin.cancel'.tr()),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(
                        dialogContext,
                      ); // Đóng dialog nhập thông tin

                      // Hiển thị dialog tải
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder:
                            (loadingContext) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                      );

                      // Tải ảnh lên nếu có
                      String? avatarUrl = currentAvatarUrl;
                      if (selectedImage != null) {
                        try {
                          final String fileName =
                              'staff_${DateTime.now().millisecondsSinceEpoch}.jpg';
                          avatarUrl = await storageService.uploadFile(
                            selectedImage!,
                            fileName,
                          );
                        } catch (e) {
                          final snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                              title: 'admin.error'.tr(),
                              message:
                                  '${'admin.error_uploading_staff_image'.tr()}: ${e.toString()}',
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        }
                      }

                      // Cập nhật thông tin nhân viên
                      final updatedStaff = staff.copyWith(
                        name: nameController.text,
                        phoneNumber: phoneController.text,
                        avatar: avatarUrl,
                        role: selectedRole,
                      );

                      final success = await editStaffService.updateStaff(
                        updatedStaff,
                      );

                      // Kiểm tra context còn hợp lệ trước khi sử dụng
                      if (!context.mounted) return;

                      // Đóng dialog tải
                      Navigator.pop(context); // Đóng dialog tải

                      if (success) {
                        final snackBar = SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'admin.success'.tr(),
                            message: 'admin.update_staff_success'.tr(),
                            contentType: ContentType.success,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                        onRefresh();
                      } else {
                        final snackBar = SnackBar(
                          elevation: 0,
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          content: AwesomeSnackbarContent(
                            title: 'admin.error'.tr(),
                            message: 'admin.error_updating_staff'.tr(),
                            contentType: ContentType.failure,
                          ),
                        );
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(snackBar);
                      }
                    }
                  },
                  child: Text('common.update'.tr()),
                ),
              ],
            ),
          ),
    );
  }
}
