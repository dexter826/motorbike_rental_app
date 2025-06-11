// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:bike_rental_app/services/auth_service.dart';
import 'package:bike_rental_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class InfoCompanyScreen extends StatefulWidget {
  const InfoCompanyScreen({super.key});

  @override
  State<InfoCompanyScreen> createState() => _InfoCompanyScreenState();
}

class _InfoCompanyScreenState extends State<InfoCompanyScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr(), style: theme.textTheme.titleLarge),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.foregroundColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Company Header
            Container(
              padding: EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                image: DecorationImage(
                  image: AssetImage('assets/images/company_bg.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.7),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/company_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'settings.company_name'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'app.title'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompanyInfo(theme),
                  SizedBox(height: 24),
                  _buildContactInfo(theme),
                  SizedBox(height: 24),
                  _buildBusinessHours(theme),
                  SizedBox(height: 24),
                  _buildAppSettings(context, theme),
                  SizedBox(height: 32),
                  _buildLogoutButton(context, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'settings.about'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'settings.company_description'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.contact'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on,
              'settings.address'.tr(),
              'settings.address_value'.tr(),
              theme,
            ),
            _buildInfoRow(
              Icons.phone,
              'settings.hotline'.tr(),
              'settings.hotline_value'.tr(),
              theme,
            ),
            _buildInfoRow(
              Icons.email,
              'settings.email'.tr(),
              'settings.email_value'.tr(),
              theme,
            ),
            _buildInfoRow(
              Icons.language,
              'settings.website'.tr(),
              'settings.website_value'.tr(),
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessHours(ThemeData theme) {
    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.business_hours'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'settings.monday_friday'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'settings.saturday'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'settings.sunday'.tr(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'settings.monday_friday_hours'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'settings.saturday_hours'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'settings.sunday_hours'.tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildAppSettings(BuildContext context, ThemeData theme) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Card(
      elevation: theme.cardTheme.elevation,
      shape: theme.cardTheme.shape,
      color: theme.cardTheme.color,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings.app_settings'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            // Dark mode toggle
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.primaryColor,
              ),
              title: Text(
                themeProvider.isDarkMode
                    ? 'settings.dark_mode'.tr()
                    : 'settings.light_mode'.tr(),
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
                activeColor: theme.primaryColor,
              ),
            ),
            Divider(),
            // Language selector
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.language, color: theme.primaryColor),
              title: Text(
                'settings.language'.tr(),
                style: theme.textTheme.bodyMedium,
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButton<Locale>(
                  value: context.locale,
                  underline: SizedBox(),
                  icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                  items:
                      context.supportedLocales.map((Locale locale) {
                        return DropdownMenuItem<Locale>(
                          value: locale,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                locale.languageCode == 'vi' ? '🇻🇳' : '🇬🇧',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(width: 8),
                              Text(
                                locale.languageCode == 'vi'
                                    ? 'settings.vietnamese'.tr()
                                    : 'settings.english'.tr(),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (Locale? locale) {
                    if (locale != null) {
                      context.setLocale(locale);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.logout),
        label: Text('auth.logout'.tr()),
        style: theme.elevatedButtonTheme.style?.copyWith(
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 16),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: MaterialStateProperty.all(theme.colorScheme.error),
          foregroundColor: MaterialStateProperty.all(theme.colorScheme.onError),
        ),
        onPressed: () {
          PanaraConfirmDialog.show(
            context,
            title: 'auth.logout'.tr(),
            message: 'auth.logout_confirm'.tr(),
            confirmButtonText: 'auth.logout'.tr(),
            cancelButtonText: 'common.cancel'.tr(),
            textColor: theme.textTheme.bodyLarge!.color!,
            onTapCancel: () {
              Navigator.pop(context);
            },
            onTapConfirm: () async {
              final authService = AuthService();
              final navigatorContext = context;
              await authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  navigatorContext,
                  '/login',
                  (route) => false,
                );
              }
            },
            panaraDialogType: PanaraDialogType.custom,
            color: theme.primaryColor,
            barrierDismissible: false,
          );
        },
      ),
    );
  }
}
