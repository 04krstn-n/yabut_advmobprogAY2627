import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  // lets the user pick DummyJSON or Firebase login for enhancement 2
  LoginType _loginType = LoginType.dummyJson;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (_loginType == LoginType.firebase) {
      await _loginWithFirebase();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _userService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      await _userService.saveUserData(response);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: response, 
       );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  // Firebase login using the FirebaseAuth SDK through UserService.signIn for enhancement 2
  Future<void> _loginWithFirebase() async {
    setState(() => _isLoading = true);

    try {
      await _userService.signIn(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final userData = await _userService.getUserData();

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: userData,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // readable messages for common Firebase login errors for enhancement 2
      String message;
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'Incorrect email or password.';
          break;
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NU_BLUE,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48.h),
              Center(
                child: Container(
                  width: 72.w,
                  height: 72.w,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: FB_LIGHT_PRIMARY,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/nubdexchange_logo.png',
                    fit: BoxFit.contain,
                    // fallback icon in case the asset fails to load
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.storefront_rounded, color: NU_BLUE, size: 36.sp),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              CustomText(
                text: 'Welcome Back',
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
                color: FB_LIGHT_PRIMARY,
              ),
              SizedBox(height: 4.h),
              CustomText(
                text: 'Sign in to continue shopping',
                fontSize: 13.sp,
                textAlign: TextAlign.center,
                color: FB_LIGHT_PRIMARY,
              ),
              SizedBox(height: 28.h),

              // Card containing the form so the branded header stands out from the fields
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // toggle between DummyJSON and Firebase login for enhancement 2
                      SegmentedButton<LoginType>(
                        segments: const [
                          ButtonSegment(
                            value: LoginType.dummyJson,
                            label: Text('DummyJSON'),
                            icon: Icon(Icons.api),
                          ),
                          ButtonSegment(
                            value: LoginType.firebase,
                            label: Text('Firebase'),
                            icon: Icon(Icons.local_fire_department_outlined),
                          ),
                        ],
                        selected: {_loginType},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _loginType = selection.first;
                            _usernameController.clear();
                            _passwordController.clear();
                          });
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: _loginType == LoginType.firebase
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: _loginType == LoginType.firebase ? 'Email' : 'Username',
                          prefixIcon: Icon(
                            _loginType == LoginType.firebase
                                ? Icons.mail_outline
                                : Icons.person_outline,
                            color: NU_BLUE,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return _loginType == LoginType.firebase
                                ? 'Please enter your email'
                                : 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: NU_BLUE),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: NU_BLUE,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        height: 48.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NU_BLUE,
                            foregroundColor: FB_LIGHT_PRIMARY,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      FB_LIGHT_PRIMARY,
                                    ),
                                  ),
                                )
                              : CustomText(
                                  text: 'Login',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: FB_LIGHT_PRIMARY,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    text: "Don't have an account?",
                    fontSize: 13.sp,
                    color: FB_LIGHT_PRIMARY,
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: CustomText(
                      text: 'Sign Up',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: NU_YELLOW,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }
}