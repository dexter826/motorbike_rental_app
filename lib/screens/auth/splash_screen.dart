import 'package:bike_rental_app/screens/auth/login_screen.dart';
import 'package:bike_rental_app/screens/home/home_screen.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:bike_rental_app/utils/animation_helper.dart';
import 'package:bike_rental_app/utils/animation_page_route.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Đợi để animation hiển thị đủ
    await Future.delayed(const Duration(milliseconds: 4000));

    // Kiểm tra trạng thái đăng nhập
    final bool isLoggedIn = await _authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        // Chuyển đến màn hình chính nếu đã đăng nhập
        Navigator.pushReplacement(
          context,
          AnimationPageRoute(
            page: const HomeScreen(),
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        // Navigate to login screen if not logged in
        Navigator.pushReplacement(
          context,
          AnimationPageRoute(
            page: const LoginScreen(),
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 800),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation với hiệu ứng bounce
            AnimationHelper.bounce(
              child: AnimationHelper.bikeAnimation(
                width: double.infinity,
                height: 200,
              ),
            ),

            const SizedBox(height: 20),

            // Loading text với hiệu ứng fadeInUp
            AnimationHelper.fadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Text(
                'app.title'.tr(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Loading indicator với hiệu ứng pulse
            AnimationHelper.fadeIn(
              delay: const Duration(milliseconds: 800),
              child: AnimationHelper.pulse(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).appBarTheme.foregroundColor?.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
