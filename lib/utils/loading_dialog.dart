import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import 'package:easy_localization/easy_localization.dart';

/// A simple loading dialog utility class
/// This replaces the LoadingOverlay class with a simpler implementation
class LoadingDialog {
  /// Show a loading dialog with optional custom message
  static void show(BuildContext context, {String? message}) {
    final displayMessage = message ?? 'common.loading'.tr();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLoadingIndicator(
                  size: 40,
                  type: LoadingIndicatorType.lottieAnimation,
                ),
                const SizedBox(height: 16),
                Text(
                  displayMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );
  }

  /// Hide the currently displayed loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show a loading dialog, execute a future, then hide the dialog
  static Future<T> during<T>(
    BuildContext context,
    Future<T> future, {
    String? message,
  }) async {
    show(context, message: message);
    try {
      final result = await future;
      if (context.mounted) hide(context);
      return result;
    } catch (e) {
      if (context.mounted) hide(context);
      rethrow;
    }
  }
}
