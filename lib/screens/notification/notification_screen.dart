import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/screens/rental/rental_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadNotifications();
  }

  Future<void> _initializeAndLoadNotifications() async {
    // Khởi tạo local notification settings
    await _notificationService.init();
    // Kiểm tra và tạo thông báo cho đơn thuê sắp đến hạn và quá hạn
    await _notificationService.checkDueRentals();
    await _notificationService.checkExpiredRentals();
    // Load danh sách thông báo để hiển thị
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {} catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.error'.tr(),
          message: '${'notification.loading_error'.tr()}: $e',
          contentType: ContentType.failure,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.markAllAsRead();
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.title'.tr(),
          message: 'notification.mark_all_read_success'.tr(),
          contentType: ContentType.success,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.error'.tr(),
          message: '${'notification.mark_all_read_error'.tr()}: $e',
          contentType: ContentType.failure,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.title'.tr(),
          message: 'notification.delete_success'.tr(),
          contentType: ContentType.success,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (e) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'notification.error'.tr(),
          message: '${'notification.delete_error'.tr()}: $e',
          contentType: ContentType.failure,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notification.title'.tr()),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 51), // 20% opacity
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'notification.mark_as_read_tooltip'.tr(),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<BikeNotification>>(
                stream: _notificationService.getAllNotifications(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${'notification.error'.tr()}: ${snapshot.error}',
                      ),
                    );
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Text('notification.no_notifications'.tr()),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _loadNotifications,
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationItem(notification);
                      },
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildNotificationItem(BikeNotification notification) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await _notificationService.markAsRead(notification.id);
          }

          // Nếu là thông báo liên quan đến đơn thuê, chuyển trang chi tiết (nếu cần)
          if (notification.type == 'rental_due' &&
              notification.rentalId.isNotEmpty) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) =>
                          RentalDetailScreen(rentalId: notification.rentalId),
                ),
              );
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                notification.isRead
                    ? theme.cardColor
                    : theme.primaryColor.withValues(
                      alpha: 0.05,
                    ), // Màu nền nhẹ cho thông báo chưa đọc
            border: Border(
              bottom: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                        color:
                            notification.isRead
                                ? theme.textTheme.titleMedium?.color
                                : theme
                                    .primaryColor, // Màu chữ đậm cho thông báo chưa đọc
                      ),
                    ),
                  ),
                  Text(
                    dateFormat.format(notification.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          notification.isRead
                              ? theme.textTheme.bodySmall?.color
                              : theme.primaryColor.withValues(
                                alpha: 0.8,
                              ), // Màu thời gian cho thông báo chưa đọc
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      notification.isRead
                          ? theme.textTheme.bodyMedium?.color
                          : theme.primaryColor.withValues(
                            alpha: 0.9,
                          ), // Màu nội dung cho thông báo chưa đọc
                ),
              ),
              if (!notification.isRead)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
