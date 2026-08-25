import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

// custom-designed SplashScreen UI for enhancement 1
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();

  // simple fade/scale-in animation so the custom splash UI for enhancement 1
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // // added a persistent-authentication check — looks up the saved token/user in SharedPreferences for enhancement 1
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NU_BLUE,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: FB_LIGHT_PRIMARY,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.storefront_rounded, color: NU_BLUE, size: 48.sp),
                ),
              ),
              SizedBox(height: 20.h),
              CustomText(
                text: 'Bulldogs Exchange',
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                color: FB_LIGHT_PRIMARY,
              ),
              SizedBox(height: 6.h),
              CustomText(
                text: 'Shop smarter, checkout faster',
                fontSize: 13.sp,
                fontStyle: FontStyle.italic,
                textAlign: TextAlign.center,
                color: FB_LIGHT_PRIMARY, 
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: 28.w,
                height: 28.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(FB_LIGHT_PRIMARY),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}