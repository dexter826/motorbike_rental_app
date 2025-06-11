import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../services/auth_service.dart';

class RESETpasswordPage extends StatefulWidget {
  const RESETpasswordPage({super.key});

  @override
  State<StatefulWidget> createState() => _RESETpassword();
}

class _RESETpassword extends State<RESETpasswordPage> {
  var email = TextEditingController();
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  Future<void> resetPassword() async {
    final result = await _authService.resetPassword(
      email: email.text.toString(),
    );

    if (!mounted) return;

    if (result['success']) {
      // Hiển thị thông báo thành công
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'auth.reset_success'.tr(),
          message: 'auth.reset_success_message'.tr(),
          contentType: ContentType.success,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);

      Navigator.of(context).pop();
    } else {
      // Hiển thị thông báo lỗi
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'auth.reset_error'.tr(),
          message: result['error'] ?? 'auth.reset_error_message'.tr(),
          contentType: ContentType.failure,
        ),
      );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        //logo công ty
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
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              SizedBox(
                width: 350,
                child: Image.asset('assets/images/reset_password.jpg'),
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'auth.reset_password_title'.tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'auth.reset_password_instruction'.tr(),
                  style: TextStyle(fontSize: 17, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerRight,
                child: Form(
                  child: TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      icon: Icon(
                        Icons.alternate_email_rounded,
                        color: Colors.black,
                      ),
                      label: Text(
                        "auth.email".tr(),
                        style: TextStyle(color: Colors.black),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    isLoading = true;
                  });
                  try {
                    if (email.text.isEmpty) {
                      // Hiển thị thông báo lỗi nếu email trống
                      final snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: AwesomeSnackbarContent(
                          title: 'auth.reset_error'.tr(),
                          message: 'auth.please_enter_email_reset'.tr(),
                          contentType: ContentType.failure,
                        ),
                      );

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                    } else {
                      await resetPassword();
                    }
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Color.fromARGB(255, 0, 85, 154),
                ),
                child: Center(
                  child:
                      isLoading
                          ? LoadingAnimationWidget.fourRotatingDots(
                            color: Colors.white,
                            size: 20,
                          )
                          : Text(
                            'auth.get_code'.tr(),
                            style: const TextStyle(fontSize: 15),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
