import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// made ProfileScreen render the User model so that it can be fetched in home and cart screen for enhancement 3
class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback to local stored user if API request fails
      try {
        final localUser = await _userService.getUser();
        if (mounted) {
          setState(() {
            _user = localUser;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No profile data found'),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          // User Card (Avatar, Full Name, Username)
          Card(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36.r,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: _user!.image.isNotEmpty
                          ? NetworkImage(_user!.image)
                          : null,
                      child: _user!.image.isEmpty
                          ? Icon(Icons.person, size: 36.sp, color: Colors.grey)
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '${_user!.firstName} ${_user!.lastName}'.trim(),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '@${_user!.username}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: NU_BLUE,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // User Details Card (Email, Gender, User ID)
          Card(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.mail_outline,
                    iconColor: NU_BLUE, 
                    label: 'Email',
                    value: _user!.email,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildDetailRow(
                    icon: Icons.people_outline,
                    iconColor: NU_BLUE,
                    label: 'Gender',
                    value: _user!.gender,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    iconColor: NU_BLUE,
                    label: 'User ID',
                    // EDIT FIX (Enhancement 3): confirms the cart shown in the Cart tab
                    // is being fetched for this same userId (widget.userId).
                    value: '#${_user!.id}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5242),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(
                'Log Out',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: iconColor),
          SizedBox(width: 12.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}