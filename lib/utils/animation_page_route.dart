import 'package:flutter/material.dart';

/// Các loại hiệu ứng chuyển trang
enum PageTransitionType {
  fade,
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
  scale,
  rotate,
  size,
  rightToLeftWithFade,
  leftToRightWithFade,
}

/// Custom PageRoute với các hiệu ứng chuyển trang
class AnimationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final PageTransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;

  AnimationPageRoute({
    required this.page,
    this.type = PageTransitionType.rightToLeft,
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
         pageBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
         ) {
           return page;
         },
         transitionDuration: duration,
         transitionsBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondaryAnimation,
           Widget child,
         ) {
           switch (type) {
             case PageTransitionType.fade:
               return FadeTransition(opacity: animation, child: child);
             case PageTransitionType.rightToLeft:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(1, 0),
                   end: Offset.zero,
                 ).animate(animation),
                 child: child,
               );
             case PageTransitionType.leftToRight:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(-1, 0),
                   end: Offset.zero,
                 ).animate(animation),
                 child: child,
               );
             case PageTransitionType.topToBottom:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(0, -1),
                   end: Offset.zero,
                 ).animate(animation),
                 child: child,
               );
             case PageTransitionType.bottomToTop:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(0, 1),
                   end: Offset.zero,
                 ).animate(animation),
                 child: child,
               );
             case PageTransitionType.scale:
               return ScaleTransition(
                 alignment: alignment,
                 scale: CurvedAnimation(
                   parent: animation,
                   curve: Interval(0.00, 0.50, curve: curve),
                 ),
                 child: child,
               );
             case PageTransitionType.rotate:
               return RotationTransition(
                 turns: animation,
                 child: ScaleTransition(
                   scale: animation,
                   child: FadeTransition(opacity: animation, child: child),
                 ),
               );
             case PageTransitionType.size:
               return Align(
                 alignment: alignment,
                 child: SizeTransition(
                   sizeFactor: CurvedAnimation(parent: animation, curve: curve),
                   child: child,
                 ),
               );
             case PageTransitionType.rightToLeftWithFade:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(1.0, 0.0),
                   end: Offset.zero,
                 ).animate(animation),
                 child: FadeTransition(
                   opacity: animation,
                   child: SlideTransition(
                     position: Tween<Offset>(
                       begin: const Offset(1, 0),
                       end: Offset.zero,
                     ).animate(animation),
                     child: child,
                   ),
                 ),
               );
             case PageTransitionType.leftToRightWithFade:
               return SlideTransition(
                 position: Tween<Offset>(
                   begin: const Offset(-1.0, 0.0),
                   end: Offset.zero,
                 ).animate(animation),
                 child: FadeTransition(
                   opacity: animation,
                   child: SlideTransition(
                     position: Tween<Offset>(
                       begin: const Offset(-1, 0),
                       end: Offset.zero,
                     ).animate(animation),
                     child: child,
                   ),
                 ),
               );
           }
         },
       );
}

/// Extension cho Navigator để dễ dàng sử dụng AnimationPageRoute
extension NavigatorExtension on NavigatorState {
  Future<T?> pushWithAnimation<T extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.rightToLeft,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return push<T>(
      AnimationPageRoute<T>(
        page: page,
        type: type,
        curve: curve,
        alignment: alignment,
        duration: duration,
      ),
    );
  }

  Future<T?>
  pushReplacementWithAnimation<T extends Object?, TO extends Object?>(
    Widget page, {
    PageTransitionType type = PageTransitionType.rightToLeft,
    Curve curve = Curves.easeInOut,
    Alignment alignment = Alignment.center,
    Duration duration = const Duration(milliseconds: 300),
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      AnimationPageRoute<T>(
        page: page,
        type: type,
        curve: curve,
        alignment: alignment,
        duration: duration,
      ),
      result: result,
    );
  }
}
