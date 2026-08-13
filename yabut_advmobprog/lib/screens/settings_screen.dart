import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_text.dart';
import '../constants.dart';

// added settings page to toggle the switch for Light and Dark mode to comply with enhancement 3
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeProvider.isDark ? Colors.grey[900] : NU_BLUE,
        foregroundColor: Colors.white,
        title: CustomText(
          text: 'Settings Screen',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 30.w),
                Icon(
                  themeProvider.isDark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  size: 25.sp,
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: CustomText(
                    text: themeProvider.isDark
                        ? 'Dark Mode Enabled'
                        : 'Light Mode Enabled',
                    fontSize: 18.sp,
                  ),
                ),
                Switch(
                  value: themeProvider.isDark,
                  onChanged: (_) {
                    themeProvider.toggleTheme();
                  },
                ),
                SizedBox(width: 20.w),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
