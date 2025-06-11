import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double paddingTop(BuildContext context) =>
      MediaQuery.of(context).padding.top;

  static double paddingBottom(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  // Trả về giá trị dựa trên kích thước màn hình
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // Trả về giá trị dựa trên hướng màn hình
  static T orientationValue<T>({
    required BuildContext context,
    required T portrait,
    required T landscape,
  }) {
    return isLandscape(context) ? landscape : portrait;
  }

  // Tính toán kích thước dựa trên phần trăm chiều rộng màn hình
  static double widthPercent(BuildContext context, double percent) {
    return screenWidth(context) * percent / 100;
  }

  // Tính toán kích thước dựa trên phần trăm chiều cao màn hình
  static double heightPercent(BuildContext context, double percent) {
    return screenHeight(context) * percent / 100;
  }

  // Tính toán font size dựa trên kích thước màn hình
  static double adaptiveFontSize(BuildContext context, double size) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Điều chỉnh font size dựa trên chiều rộng màn hình
    if (screenWidth > 600) {
      return size * 1.2; // Tăng font size cho tablet
    } else if (screenWidth < 320) {
      return size * 0.8; // Giảm font size cho màn hình nhỏ
    }
    return size;
  }

  // Tính toán padding dựa trên kích thước màn hình
  static EdgeInsets adaptivePadding(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );
  }

  // Tính toán số cột trong grid dựa trên kích thước màn hình
  static int adaptiveGridCount(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 2,
      tablet: 3,
      desktop: 4,
    );
  }

  // Tính toán child aspect ratio cho grid dựa trên kích thước màn hình
  static double adaptiveChildAspectRatio(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 0.75,
      tablet: 0.8,
      desktop: 0.85,
    );
  }
}
