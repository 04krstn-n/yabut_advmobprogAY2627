import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;

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
  LoginType _loginType = LoginType.none;
  Map<String, dynamic> _firebaseData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // check LoginType first, Firebase users load from getUserData() for enhancement 3
    _loginType = await _userService.getLoginType();
    if (_loginType == LoginType.firebase) {
      final data = await _userService.getUserData();
      if (mounted) {
        setState(() {
          _firebaseData = data;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final user = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (_) {
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

  Future<List<String>?> _showInputDialog({
    required String title,
    required List<String> labels,
    List<bool>? obscure,
    List<String>? initialValues,
    String confirmText = 'Save',
    bool destructive = false,
    String? message,
  }) {
    final controllers = List.generate(
      labels.length,
      (i) => TextEditingController(text: initialValues?[i] ?? ''),
    );
    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null) ...[
                Text(message),
                SizedBox(height: 12.h),
              ],
              for (int i = 0; i < labels.length; i++) ...[
                TextField(
                  controller: controllers[i],
                  obscureText: obscure?[i] ?? false,
                  decoration: InputDecoration(
                    labelText: labels[i],
                    border: const OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: destructive ? const Color(0xFFFF5242) : NU_BLUE,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(
              dialogContext,
              controllers.map((c) => c.text.trim()).toList(),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // shows a SnackBar message in enhancement 3
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // made email used to re-authenticate the Firebase user enhancement 3
  String get _firebaseEmail =>
      _userService.currentUser?.email ?? (_firebaseData['email'] ?? '');

  // update username through UserService().updateUsername() for enhancement 3
  Future<void> _handleUpdateUsername() async {
    final values = await _showInputDialog(
      title: 'Update Username',
      labels: ['New username'],
      initialValues: [_firebaseData['username'] ?? ''],
    );
    if (values == null) return;
    if (values[0].length < 3) {
      _showMessage('Username must be at least 3 characters');
      return;
    }
    try {
      await _userService.updateUsername(username: values[0]);
      await _loadUserData();
      _showMessage('Username updated');
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Failed to update username');
    } catch (e) {
      _showMessage('Failed to update username: $e');
    }
  }

  Future<void> _handleChangePassword() async {
    final values = await _showInputDialog(
      title: 'Change Password',
      labels: ['Current password', 'New password', 'Confirm new password'],
      obscure: [true, true, true],
    );
    if (values == null) return;
    if (values[1].length < 8) {
      _showMessage('New password must be at least 8 characters');
      return;
    }
    if (values[1] != values[2]) {
      _showMessage('New passwords do not match');
      return;
    }
    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: values[0],
        newPassword: values[1],
        email: _firebaseEmail,
      );
      _showMessage('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      _showMessage(
        (e.code == 'invalid-credential' || e.code == 'wrong-password')
            ? 'Current password is incorrect'
            : (e.message ?? 'Failed to change password'),
      );
    } catch (e) {
      _showMessage('Failed to change password: $e');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final values = await _showInputDialog(
      title: 'Delete Account',
      message: 'This permanently deletes your account. Enter your password to confirm.',
      labels: ['Password'],
      obscure: [true],
      confirmText: 'Delete',
      destructive: true,
    );
    if (values == null) return;
    try {
      await _userService.deleteAccount(
        email: _firebaseEmail,
        password: values[0],
      );
      _showMessage('Account deleted');
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
    } on FirebaseAuthException catch (e) {
      _showMessage(
        (e.code == 'invalid-credential' || e.code == 'wrong-password')
            ? 'Incorrect password'
            : (e.message ?? 'Failed to delete account'),
      );
    } catch (e) {
      _showMessage('Failed to delete account: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Firebase accounts get their own profile layout enhancement 3, while DummyJSON accounts use the existing layout
    if (_loginType == LoginType.firebase) {
      return _buildFirebaseProfile();
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
                    // made the cart shown in the Cart tab be fetched for this same userId (widget.userId) for enhancement 3
                    value: '#${_user!.id}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // made account actions only work for Firebase accounts for enhancement 3
          _buildLoginTypeChip('Signed in with DummyJSON', Icons.api),
          SizedBox(height: 8.h),
          Text(
            'Update username, change password and delete account are available for Firebase accounts.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
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

  // profile layout for Firebase login with update/change/delete actions for enhancement 3
  Widget _buildFirebaseProfile() {
    final fullName =
        '${_firebaseData['firstName'] ?? ''} ${_firebaseData['lastName'] ?? ''}'.trim();
    final username = (_firebaseData['username'] ?? '') as String;
    final age = _firebaseData['age'] ?? 0;
    final contactNo = (_firebaseData['contactNo'] ?? '') as String;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
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
                      child: Icon(Icons.person, size: 36.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      fullName.isNotEmpty ? fullName : 'Firebase User',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      username.isNotEmpty ? '@$username' : '@-',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: NU_BLUE,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _buildLoginTypeChip(
                      'Signed in with Firebase',
                      Icons.local_fire_department_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

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
                    value: _firebaseEmail,
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildDetailRow(
                    icon: Icons.cake_outlined,
                    iconColor: NU_BLUE,
                    label: 'Age',
                    value: age == 0 ? '-' : '$age',
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    iconColor: NU_BLUE,
                    label: 'Contact No.',
                    value: contactNo.isNotEmpty ? contactNo : '-',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          Card(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: NU_BLUE),
                  title: const Text('Update Username', style: TextStyle(color: Colors.black87)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _handleUpdateUsername,
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ListTile(
                  leading: const Icon(Icons.lock_reset, color: NU_BLUE),
                  title: const Text('Change Password', style: TextStyle(color: Colors.black87)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _handleChangePassword,
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFFF5242)),
                  title: const Text(
                    'Delete Account',
                    style: TextStyle(color: Color(0xFFFF5242)),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _handleDeleteAccount,
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

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

  Widget _buildLoginTypeChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: FB_LIGHT_PRIMARY,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: NU_BLUE),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: NU_BLUE,
              fontWeight: FontWeight.w600,
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