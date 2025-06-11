import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';

/// Widget hiển thị trạng thái loading chung cho toàn bộ ứng dụng
/// Có thể tùy chỉnh kích thước, màu sắc và kiểu loading
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final LoadingIndicatorType type;
  final String? message;

  const AppLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.type = LoadingIndicatorType.fourRotatingDots,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoadingIndicator(indicatorColor),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(Color color) {
    switch (type) {
      case LoadingIndicatorType.fourRotatingDots:
        return LoadingAnimationWidget.fourRotatingDots(
          color: color,
          size: size,
        );
      case LoadingIndicatorType.staggeredDotsWave:
        return LoadingAnimationWidget.staggeredDotsWave(
          color: color,
          size: size,
        );
      case LoadingIndicatorType.lottieAnimation:
        return Lottie.asset(
          'assets/animations/loading_animation.json',
          width: size * 2,
          height: size * 2,
          fit: BoxFit.contain,
        );
      case LoadingIndicatorType.circularProgress:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(color: color, strokeWidth: 2),
        );
    }
  }
}

/// Widget hiển thị trạng thái lỗi chung cho toàn bộ ứng dụng
class AppErrorWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    this.message = '',
    this.icon = Icons.error_outline,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? 'common.error_occurred'.tr() : message,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị trạng thái trống chung cho toàn bộ ứng dụng
class AppEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmptyWidget({
    super.key,
    this.message = '',
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? 'common.no_data'.tr() : message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget hiển thị trạng thái loading trong button
class AppLoadingButton extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const AppLoadingButton({
    super.key,
    required this.isLoading,
    required this.child,
    required this.onPressed,
    this.color,
    this.height = 50,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.primaryColor;

    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: buttonColor.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
        ),
        child:
            isLoading
                ? LoadingAnimationWidget.fourRotatingDots(
                  color: Colors.white,
                  size: 20,
                )
                : child,
      ),
    );
  }
}

/// Widget hiển thị trạng thái loading trong image
class AppLoadingImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppLoadingImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: theme.cardColor,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  strokeWidth: 2,
                  color: theme.primaryColor,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: theme.cardColor,
            child: Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 30,
                color: theme.colorScheme.error.withOpacity(0.7),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Các kiểu loading indicator
enum LoadingIndicatorType {
  fourRotatingDots,
  staggeredDotsWave,
  lottieAnimation,
  circularProgress,
}
