import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class AnimationHelper {
  /// Tạo hiệu ứng FadeIn cho widget
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return FadeIn(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng FadeInUp cho widget
  static Widget fadeInUp({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return FadeInUp(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng FadeInDown cho widget
  static Widget fadeInDown({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return FadeInDown(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng FadeInLeft cho widget
  static Widget fadeInLeft({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return FadeInLeft(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng FadeInRight cho widget
  static Widget fadeInRight({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return FadeInRight(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng Bounce cho widget
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return Bounce(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng Pulse cho widget
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return Pulse(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      infinite: true,
      child: child,
    );
  }

  /// Tạo hiệu ứng loading animation
  static Widget loadingAnimation({
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.asset(
      'assets/animations/loading_animation.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Tạo hiệu ứng success animation
  static Widget successAnimation({
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.contain,
    bool repeat = false,
    Function()? onFinish,
  }) {
    return Lottie.asset(
      'assets/animations/success_animation.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      onLoaded: (composition) {
        Future.delayed(composition.duration, () {
          if (onFinish != null) {
            onFinish();
          }
        });
      },
    );
  }

  /// Tạo hiệu ứng bike animation
  static Widget bikeAnimation({
    double width = 200,
    double height = 200,
    BoxFit fit = BoxFit.contain,
    bool repeat = true,
  }) {
    return Lottie.asset(
      'assets/animations/bike_animation.json',
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
    );
  }

  /// Tạo hiệu ứng scale
  static Widget scale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    Duration delay = Duration.zero,
    Function(AnimateDoDirection)? onFinish,
  }) {
    return ZoomIn(
      duration: duration,
      delay: delay,
      onFinish: onFinish,
      child: child,
    );
  }

  /// Tạo hiệu ứng staggered list
  static List<Widget> staggeredList({
    required List<Widget> children,
    Duration initialDelay = Duration.zero,
    Duration itemDelay = const Duration(milliseconds: 100),
    StaggeredAnimation animation = StaggeredAnimation.fadeInUp,
  }) {
    List<Widget> animatedChildren = [];

    for (int i = 0; i < children.length; i++) {
      final delay = initialDelay + (itemDelay * i);

      switch (animation) {
        case StaggeredAnimation.fadeIn:
          animatedChildren.add(fadeIn(child: children[i], delay: delay));
          break;
        case StaggeredAnimation.fadeInUp:
          animatedChildren.add(fadeInUp(child: children[i], delay: delay));
          break;
        case StaggeredAnimation.fadeInDown:
          animatedChildren.add(fadeInDown(child: children[i], delay: delay));
          break;
        case StaggeredAnimation.fadeInLeft:
          animatedChildren.add(fadeInLeft(child: children[i], delay: delay));
          break;
        case StaggeredAnimation.fadeInRight:
          animatedChildren.add(fadeInRight(child: children[i], delay: delay));
          break;
      }
    }

    return animatedChildren;
  }
}

enum StaggeredAnimation {
  fadeIn,
  fadeInUp,
  fadeInDown,
  fadeInLeft,
  fadeInRight,
}
