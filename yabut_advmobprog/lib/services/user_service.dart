import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart' as model;
import 'package:firebase_auth/firebase_auth.dart';
// EDIT FIX + Enhancement 1: Firestore is used to register every Firebase account in the "Users" collection
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

// added this to tell the Profile screen which account type is logged in for enhancement 1
enum LoginType { dummyJson, firebase, none }

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      await saveUserData(data);
      await saveLoginType(LoginType.dummyJson);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    // make it use model.User because of the firebase_auth name conflict for enhancement 2
    final user = model.User.fromJson(userData);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);

    if (userData.containsKey('token')) {
      await prefs.setString('token', userData['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? prefs.getString('accessToken') ?? '',
      // added extra signup fields + login type for the Profile screen for enhancement 3
      'age': prefs.getInt('age') ?? 0,
      'contactNo': prefs.getString('contactNo') ?? '',
      'loginType': prefs.getString('loginType') ?? LoginType.none.name,
    };
  }

  // make it use model.User because of the firebase_auth name conflict for enhancement 2
  Future<model.User> getUser() async {
    final userData = await getUserData();
    return model.User.fromJson(userData);
  }

  Future<bool> isLoggedIn() async {
    // make it read a Firebase session and count as logged in for enhancement 2
    if (firebaseAuth.currentUser != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      // make it sign out of Firebase so Logout ends any login type for enhancement 1
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to log out: $e');
    }
  }

  // make it use model.User because of the firebase_auth name conflict for enhancement 2
  Future<model.User> getUserById(int userId) async {
    final response = await get(Uri.parse('$host/users/$userId'));

    if (response.statusCode == 200) {
      return model.User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user data');
    }
  }

  // make it save which login was used (DummyJSON or Firebase) for enhancement 3
  Future<void> saveLoginType(LoginType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loginType', type.name);
  }

  // make it read the login type so the Profile screen knows what to show for enhancement 3
  Future<LoginType> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('loginType');
    return LoginType.values.firstWhere(
      (t) => t.name == saved,
      orElse: () => LoginType.none,
    );
  }

  // added the Firebase code(sign in, store account, create account, sign out, delete account, etc.) for enhancement 1 
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession(credential.user);
    return credential;
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _saveFirebaseSession(credential.user);
    return credential;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> updateUsername({required String username}) async {
    await currentUser!.updateDisplayName(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }

  Future<String?> refreshFirebaseToken() async {
    final token = await currentUser?.getIdToken(true);
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('accessToken', token);
    }
    return token;
  }

  // make it save the extra signup_screen fields (fName, lName, age, contactNo, username) for enhancement 2
  Future<void> saveSignupDetails({
    required String firstName,
    required String lastName,
    required int age,
    required String contactNo,
    required String username,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setInt('age', age);
    await prefs.setString('contactNo', contactNo);
    await prefs.setString('username', username);
    await currentUser?.updateDisplayName(username);

    // EDIT FIX + Enhancement 1: stores the signup details in the "Users" collection so the chat list can show and search the user's name
    final user = currentUser;
    if (user != null) {
      try {
        await _saveUserToFirestore(user, {
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
        });
      } catch (_) {}
    }
  }

  // added shared helper that saves Firebase user info + token + login type for enhancement 2
  Future<void> _saveFirebaseSession(User? user) async {
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = await user.getIdToken();

    await prefs.setString('email', user.email ?? '');
    await prefs.setString('username', user.displayName ?? '');
    await prefs.setString('token', token ?? '');
    await prefs.setString('accessToken', token ?? '');
    await saveLoginType(LoginType.firebase);

    // EDIT FIX + Enhancement 1: makes sure every Firebase account (even ones created before this fix) is listed in "Users" when it signs in
    try {
      await _saveUserToFirestore(user);
    } catch (_) {}
  }

  // EDIT FIX + Enhancement 1: creates/merges the user's doc in the "Users" collection (doc id = Firebase uid)
  Future<void> _saveUserToFirestore(
    User user, [
    Map<String, dynamic> extra = const {},
  ]) async {
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      ...extra,
    }, SetOptions(merge: true));
  }
}