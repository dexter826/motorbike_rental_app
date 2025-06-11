// ignore_for_file: library_private_types_in_public_api

import 'package:bike_rental_app/models/user.dart';
import 'package:bike_rental_app/screens/rental/create_rental_screen.dart';
import 'package:bike_rental_app/screens/user/add_user_screen.dart';
import 'package:bike_rental_app/screens/user/user_profile_screen.dart';
import 'package:bike_rental_app/screens/user/user_rental_history_screen.dart';
import 'package:bike_rental_app/services/user_service.dart';
import 'package:bike_rental_app/utils/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/widgets/common_widgets.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:easy_localization/easy_localization.dart';

class UserListScreen extends StatefulWidget {
  final String? bikeId;
  final bool showBackButton;

  const UserListScreen({super.key, this.bikeId, this.showBackButton = true});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();
  late Future<List<User>> _users;
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _users = _userService.getUsers();
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchQuery.isEmpty) return users;
    return users
        .where(
          (user) =>
              user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              user.phone.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _handleUserTap(User user) {
    if (widget.bikeId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) =>
                  CreateRentalScreen(bikeId: widget.bikeId!, userId: user.id),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder:
            (context) => Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text('rental.rental_history'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserRentalHistoryScreen(user: user),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.edit,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text('user.edit_user'.tr()),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfileScreen(user: user),
                        ),
                      ).then((_) {
                        setState(() {
                          _users = _userService.getUsers();
                        });
                      });
                    },
                  ),
                ],
              ),
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true, // Cần thiết cho CrystalNavigationBar
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  style: TextStyle(color: theme.colorScheme.primary),
                  decoration: InputDecoration(
                    hintText: 'user.search_users'.tr(),
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
                : Text(
                  'user.users'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: theme.colorScheme.primary.withAlpha(51),
            height: 1.0,
          ),
        ),
        leading:
            widget.showBackButton
                ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _users = _userService.getUsers();
                });
              },
              child: FutureBuilder<List<User>>(
                future: _users,
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
                      onRetry:
                          () => setState(() {
                            _users = _userService.getUsers();
                          }),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 80,
                            color: theme.disabledColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'user.no_users'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add),
                            label: Text('user.add_new_user'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddUserScreen(),
                                ),
                              ).then(
                                (_) => setState(() {
                                  _users = _userService.getUsers();
                                }),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    final filteredUsers = _filterUsers(snapshot.data!);

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: theme.disabledColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'user.no_matching_users'.tr(),
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    // Sử dụng ResponsiveLayout để hiển thị danh sách người dùng khác nhau trên mobile và tablet
                    return ListView.builder(
                      padding: EdgeInsets.only(
                        left: ResponsiveHelper.adaptivePadding(context).left,
                        right: ResponsiveHelper.adaptivePadding(context).right,
                        top: ResponsiveHelper.adaptivePadding(context).top,
                        bottom: 100,
                      ), // Thêm padding ở dưới cùng cho thanh điều hướng
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        User user = filteredUsers[index];
                        return AnimationHelper.fadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: Duration(milliseconds: 100 * index),
                          child: Card(
                            margin: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: AnimationHelper.bounce(
                                child: CircleAvatar(
                                  backgroundColor: theme.primaryColor.withAlpha(
                                    51,
                                  ),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                user.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: ResponsiveHelper.adaptiveFontSize(
                                    context,
                                    theme.textTheme.titleMedium?.fontSize ?? 16,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 16,
                                        color: theme.hintColor,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        user.email,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize:
                                              ResponsiveHelper.adaptiveFontSize(
                                                context,
                                                theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.fontSize ??
                                                    14,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: theme.hintColor,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        user.phone,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize:
                                              ResponsiveHelper.adaptiveFontSize(
                                                context,
                                                theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.fontSize ??
                                                    14,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: theme.hintColor,
                              ),
                              onTap: () => _handleUserTap(user),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimationHelper.bounce(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: 70,
          ), // Thêm padding để tránh bị che khuất bởi thanh điều hướng
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddUserScreen()),
              ).then(
                (_) => setState(() {
                  _users = _userService.getUsers();
                }),
              );
            },
            backgroundColor: theme.primaryColor,
            child: Icon(Icons.person_add, color: theme.colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
