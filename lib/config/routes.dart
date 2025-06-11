import 'package:bike_rental_app/models/bike.dart';
import 'package:bike_rental_app/screens/auth/splash_screen.dart';
import 'package:bike_rental_app/screens/bike/bike_details_screen.dart';
import 'package:bike_rental_app/screens/bike/bike_list_screen.dart';
import 'package:bike_rental_app/screens/home/info_company_screen.dart';
import 'package:bike_rental_app/screens/home/qr_scanner_screen.dart';
import 'package:bike_rental_app/screens/payment/payment_list_screen.dart';
import 'package:bike_rental_app/screens/rental/rental_screen.dart';
import 'package:bike_rental_app/screens/home/statistics_screen.dart';
import 'package:bike_rental_app/screens/admin/staff_management_screen.dart';
import 'package:bike_rental_app/screens/user/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:bike_rental_app/screens/auth/login_screen.dart';
import 'package:bike_rental_app/screens/home/home_screen.dart';
import 'package:bike_rental_app/screens/bike/manage_bike_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String manageBike = '/manage-bike';
  static const String manageRental = '/manage-rental';
  static const String infoCompany = '/info-company';
  static const String qrScanner = '/qr-scanner';
  static const String bikeDetails = '/bike-details';
  static const String statistics = '/statistics';
  static const String bikeList = '/bike-list';
  static const String paymentList = '/payment-list';
  static const String staffManagement = '/staff-management';
  static const String userList = '/user-list';

  static Map<String, WidgetBuilder> get routes {
    return {
      splash: (context) => SplashScreen(),
      login: (context) => LoginScreen(),
      home: (context) => HomeScreen(),
      manageBike: (context) => ManageBikeScreen(),
      manageRental: (context) => RentalScreen(),
      infoCompany: (context) => InfoCompanyScreen(),
      qrScanner: (context) => QRScannerScreen(),
      statistics: (context) => StatisticsScreen(),
      bikeDetails:
          (context) => BikeDetailsScreen(
            bike: ModalRoute.of(context)!.settings.arguments as Bike,
          ),
      bikeList: (context) => BikeListScreen(),
      paymentList: (context) => PaymentListScreen(),
      staffManagement: (context) => StaffManagementScreen(),
      userList: (context) => UserListScreen(),
    };
  }
}
