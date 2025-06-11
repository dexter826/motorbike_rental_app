// ignore_for_file: deprecated_member_use

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:bike_rental_app/screens/auth/reset_password.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  var id = TextEditingController();
  var password = TextEditingController();

  bool notvisible = true;
  bool notVisiblePassword = true;
  Icon passwordIcon = const Icon(Icons.visibility);

  String? emailError;
  String? passError;

  // ================================================Password Visibility function ===========================================
  void passwordVisibility() {
    if (notVisiblePassword) {
      passwordIcon = const Icon(Icons.visibility);
    } else {
      passwordIcon = const Icon(Icons.visibility_off);
    }
  }

  // ================================================Login Function ======================================================
  bool _isLoading = false;

  // Login function
  login() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.loginWithEmailAndPassword(
        email: id.text.toString(),
        password: password.text.toString(),
      );

      setState(() {
        emailError = result['emailError'];
        passError = result['passError'];
      });

      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        String errorMessage = 'auth.login_failed'.tr();
        if (result['emailError'] != null) {
          errorMessage = result['emailError'];
        } else if (result['passError'] != null) {
          errorMessage = result['passError'];
        } else if (result['message'] != null) {
          errorMessage = result['message'];
        }

        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'auth.login_failed'.tr(),
            message: errorMessage,
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================Building The Screen ===================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/info-company');
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/main_logo.png',
                height: 120,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.asset(
                    'assets/images/login.jpg',
                    fit: BoxFit.cover,
                    width: 400,
                  ),
                ),
                // Sized box
                const SizedBox(height: 10),
                // Login Form
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      // Login Text
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'auth.login'.tr(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(
                                icon: const Icon(
                                  Icons.alternate_email_outlined,
                                  color: Colors.black,
                                ),
                                labelText: 'auth.email'.tr(),
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                errorText: emailError,
                              ),
                              controller: id,
                              style: const TextStyle(color: Colors.black),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'auth.please_enter_email'.tr();
                                }
                                return null;
                              },
                            ),
                            TextFormField(
                              obscureText: notvisible,
                              decoration: InputDecoration(
                                icon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.black,
                                ),
                                labelText: 'auth.password'.tr(),
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      notvisible = !notvisible;
                                      notVisiblePassword = !notVisiblePassword;
                                      passwordVisibility();
                                    });
                                  },
                                  icon: Icon(
                                    notVisiblePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                ),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                errorText: passError,
                              ),
                              controller: password,
                              style: const TextStyle(color: Colors.black),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'auth.please_enter_password'.tr();
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Forgot Password
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: GestureDetector(
                            child: Text(
                              'auth.forgot_password'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.black,
                                decorationThickness: 1.5,
                                decorationStyle: TextDecorationStyle.solid,
                                height: 1.5,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return RESETpasswordPage();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      // Login Button
                      ElevatedButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  if (_formKey.currentState!.validate()) {
                                    login();
                                  }
                                },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(
                            const Size.fromHeight(50),
                          ),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          backgroundColor:
                              MaterialStateProperty.resolveWith<Color>((
                                Set<MaterialState> states,
                              ) {
                                if (states.contains(MaterialState.disabled)) {
                                  return const Color.fromARGB(
                                    255,
                                    18,
                                    68,
                                    154,
                                  ).withOpacity(0.5); // Màu khi disabled
                                }
                                return const Color.fromARGB(
                                  255,
                                  18,
                                  68,
                                  154,
                                ); // Màu khi enabled
                              }),
                          foregroundColor: MaterialStateProperty.all(
                            Colors.white,
                          ), // Màu chữ/icon
                        ),
                        child: Center(
                          child:
                              _isLoading
                                  ? LoadingAnimationWidget.fourRotatingDots(
                                    color:
                                        Colors
                                            .white, // Đồng bộ với foregroundColor
                                    size: 20,
                                  )
                                  : Text(
                                    "auth.login".tr(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                      SizedBox(height: 110),
                      // Copyright
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            '© 2025 Smurfs Company Rental. All rights reserved.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
