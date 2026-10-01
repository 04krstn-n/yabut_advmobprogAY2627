import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  static String displayNameOf(Map<String, dynamic> user) {
    final first = (user['firstName'] ?? '').toString().trim();
    final last = (user['lastName'] ?? '').toString().trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final username = (user['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;
    final email = (user['email'] ?? '').toString();
    return email.contains('@') ? email.split('@').first : 'Unknown';
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();

  String? _currentUserId;
  String? _currentUserEmail;

  late final Stream<List<Map<String, dynamic>>> _usersStream;

  @override
  void initState() {
    super.initState();
    final firebaseUser = _chatService.currentUser;
    _currentUserId = firebaseUser?.uid;
    _currentUserEmail = firebaseUser?.email;
    _usersStream = _chatService.getUsersStream();
    _searchChatController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: NU_BLUE,
        foregroundColor: FB_LIGHT_PRIMARY,
        title: CustomText(
          text: 'Chats',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _currentUserId == null ? _notFirebaseUser() : _chatList(),
    );
  }

  Widget _notFirebaseUser() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 64.sp, color: Colors.grey),
            SizedBox(height: 12.h),
            CustomText(
              text: 'Chat is available for Firebase accounts.\nSign in with Firebase to start chatting.',
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatList() {
    return Column(
      children: [
        Container(
          color: NU_BLUE,
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 14.h),
          child: TextField(
            controller: _searchChatController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: const TextStyle(color: Colors.black45),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              prefixIcon: const Icon(Icons.search, color: NU_BLUE),
              suffixIcon: _searchChatController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.cancel, color: Colors.black45),
                      onPressed: () {
                        _searchChatController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Users Stream
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              if (snapshot.hasError) {
                return _message('Error loading users');
              }

              final rawUsers = snapshot.data ?? [];

              final otherUsers = rawUsers.where((user) {
                final uid = (user['uid'] ?? '').toString();
                final email = (user['email'] ?? '').toString().toLowerCase();
                return uid != _currentUserId &&
                    email != (_currentUserEmail ?? '').toLowerCase();
              }).toList()
                ..sort((a, b) => ChatScreen.displayNameOf(a)
                    .toLowerCase()
                    .compareTo(ChatScreen.displayNameOf(b).toLowerCase()));

              final query = _searchChatController.text.trim().toLowerCase();
              final users = otherUsers.where((user) {
                if (query.isEmpty) return true;
                final fields = [
                  ChatScreen.displayNameOf(user),
                  user['firstName'],
                  user['lastName'],
                  user['username'],
                  user['email'],
                ].map((f) => (f ?? '').toString().toLowerCase());
                return fields.any((f) => f.contains(query));
              }).toList();

              if (otherUsers.isEmpty) {
                return _message('No other users yet');
              }

              if (users.isEmpty) {
                return _message('No users match "${_searchChatController.text.trim()}"');
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 16.h),
                itemCount: users.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(6.w, 4.h, 6.w, 8.h),
                      child: CustomText(
                        text: query.isEmpty
                            ? '${users.length} user(s)'
                            : '${users.length} result(s)',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    );
                  }
                  final user = users[index - 1];
                  return _userTile(user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _userTile(Map<String, dynamic> user) {
    final name = ChatScreen.displayNameOf(user);
    final uid = (user['uid'] ?? '').toString();

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        onTap: () {
          if (_currentUserEmail == null) return;
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                currentUserEmail: _currentUserEmail!,
                tappedUser: user,
              ),
            ),
          );
        },
        leading: Hero(
          tag: 'chat_avatar_$uid',
          child: CircleAvatar(
            radius: 22.r,
            backgroundColor: NU_BLUE,
            child: CustomText(
              text: name.isNotEmpty ? name[0].toUpperCase() : '?',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: NU_YELLOW,
            ),
          ),
        ),
        title: CustomText(
          text: name,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: CustomText(
          text: (user['email'] ?? 'No email').toString(),
          fontSize: 12.sp,
          fontWeight: FontWeight.w300,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: CustomText(
          text: text,
          fontSize: 16.sp,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}