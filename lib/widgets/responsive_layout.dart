import 'package:flutter/material.dart';

/// Widget giúp xử lý responsive layout dựa trên kích thước màn hình
///
/// Sử dụng widget này để hiển thị các layout khác nhau cho mobile, tablet và desktop
class ResponsiveLayout extends StatelessWidget {
  /// Widget hiển thị trên màn hình mobile (< 650px)
  final Widget mobile;

  /// Widget hiển thị trên màn hình tablet (>= 650px và < 1100px)
  final Widget? tablet;

  /// Widget hiển thị trên màn hình desktop (>= 1100px)
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng LayoutBuilder để lấy kích thước hiện tại của widget
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lấy chiều rộng của màn hình
        final width = constraints.maxWidth;

        // Hiển thị layout desktop nếu có và màn hình đủ rộng
        if (width >= 1100 && desktop != null) {
          return desktop!;
        }

        // Hiển thị layout tablet nếu có và màn hình đủ rộng
        if (width >= 650 && tablet != null) {
          return tablet!;
        }

        // Mặc định hiển thị layout mobile
        return mobile;
      },
    );
  }
}

/// Widget giúp xử lý responsive layout dựa trên hướng màn hình
///
/// Sử dụng widget này để hiển thị các layout khác nhau cho portrait và landscape
class OrientationResponsiveLayout extends StatelessWidget {
  /// Widget hiển thị khi màn hình ở chế độ portrait
  final Widget portrait;

  /// Widget hiển thị khi màn hình ở chế độ landscape
  final Widget landscape;

  const OrientationResponsiveLayout({
    super.key,
    required this.portrait,
    required this.landscape,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng OrientationBuilder để phát hiện hướng màn hình
    return OrientationBuilder(
      builder: (context, orientation) {
        // Hiển thị layout landscape nếu màn hình ở chế độ landscape
        if (orientation == Orientation.landscape) {
          return landscape;
        }

        // Mặc định hiển thị layout portrait
        return portrait;
      },
    );
  }
}

/// Widget giúp xử lý responsive layout dựa trên kích thước và hướng màn hình
///
/// Sử dụng widget này để hiển thị các layout khác nhau cho các kích thước và hướng màn hình khác nhau
class AdvancedResponsiveLayout extends StatelessWidget {
  /// Widget hiển thị trên màn hình mobile ở chế độ portrait
  final Widget mobilePortrait;

  /// Widget hiển thị trên màn hình mobile ở chế độ landscape
  final Widget? mobileLandscape;

  /// Widget hiển thị trên màn hình tablet ở chế độ portrait
  final Widget? tabletPortrait;

  /// Widget hiển thị trên màn hình tablet ở chế độ landscape
  final Widget? tabletLandscape;

  /// Widget hiển thị trên màn hình desktop
  final Widget? desktop;

  const AdvancedResponsiveLayout({
    super.key,
    required this.mobilePortrait,
    this.mobileLandscape,
    this.tabletPortrait,
    this.tabletLandscape,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            // Lấy chiều rộng của màn hình
            final width = constraints.maxWidth;

            // Kiểm tra xem màn hình có phải là desktop không
            if (width >= 1100 && desktop != null) {
              return desktop!;
            }

            // Kiểm tra xem màn hình có phải là tablet không
            if (width >= 650) {
              // Kiểm tra hướng màn hình
              if (orientation == Orientation.landscape &&
                  tabletLandscape != null) {
                return tabletLandscape!;
              }

              if (tabletPortrait != null) {
                return tabletPortrait!;
              }
            }

            // Mặc định hiển thị layout mobile
            if (orientation == Orientation.landscape &&
                mobileLandscape != null) {
              return mobileLandscape!;
            }

            return mobilePortrait;
          },
        );
      },
    );
  }
}
