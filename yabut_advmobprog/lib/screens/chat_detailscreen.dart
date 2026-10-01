import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yabut_advmobprog/widgets/custom_text.dart';

import 'package:yabut_advmobprog/constants.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

final ChatService chatService = ChatService();

enum MessageStatus { sending, delivered, seen }

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late final String? _currentUserId;
  late final String _tappedUserId;
  late final Stream<QuerySnapshot> _messagesStream;

  final Set<String> _knownIds = {};
  bool _initialLoadDone = false;

  final Set<String> _markingSeen = {};

  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = chatService.currentUser?.uid;
    _tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    if (_currentUserId != null) {
      _messagesStream = chatService.getMessage(_currentUserId!, _tappedUserId);
    }
    _msgCtrl.addListener(() {
      final hasText = _msgCtrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _msgCtrl.clear();
    _msgFocus.requestFocus();

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    try {
      await chatService.sendMessage(_tappedUserId, text);
    } catch (e) {
      if (!mounted) return;
      if (_msgCtrl.text.isEmpty) _msgCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  void _markIncomingAsSeen(List<QueryDocumentSnapshot> docs) {
    final refs = <DocumentReference>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isIncoming = (data['receiverId'] ?? '').toString() == _currentUserId;
      if (isIncoming &&
          data['seen'] != true &&
          !doc.metadata.hasPendingWrites &&
          _markingSeen.add(doc.id)) {
        refs.add(doc.reference);
      }
    }
    if (refs.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatService.markMessagesAsSeen(refs).catchError((_) {
        for (final r in refs) {
          _markingSeen.remove(r.id);
        }
      });
    });
  }

  MessageStatus _statusOf(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    if (doc.metadata.hasPendingWrites) return MessageStatus.sending;
    if (data['seen'] == true) return MessageStatus.seen;
    return MessageStatus.delivered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tappedUserName = ChatScreen.displayNameOf(widget.tappedUser);
    final tappedEmail = (widget.tappedUser['email'] ?? '').toString();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101114) : const Color(0xFFF2F3F8),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [NU_BLUE, Color(0xFF4F5BC4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'chat_avatar_$_tappedUserId',
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: NU_YELLOW,
                child: CustomText(
                  text: tappedUserName.isNotEmpty
                      ? tappedUserName[0].toUpperCase()
                      : '?',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: NU_BLUE,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: tappedUserName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tappedEmail.isNotEmpty)
                    CustomText(
                      text: tappedEmail,
                      fontSize: 11.sp,
                      color: Colors.white70,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _currentUserId == null
          ? const Center(child: Text('Sign in with a Firebase account to chat'))
          : Column(
              children: [
                Expanded(child: _messageList(isDark, tappedUserName)),
                _composer(isDark),
              ],
            ),
    );
  }

  Widget _messageList(bool isDark, String tappedUserName) {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading messages: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final newIds = <String>{};
        if (!_initialLoadDone) {
          _knownIds.addAll(docs.map((d) => d.id));
          _initialLoadDone = true;
        } else {
          for (final d in docs) {
            if (_knownIds.add(d.id)) newIds.add(d.id);
          }
        }

        _markIncomingAsSeen(docs);

        if (docs.isEmpty) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - v)),
                child: child,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.waving_hand_rounded, size: 56.sp, color: NU_YELLOW),
                  SizedBox(height: 12.h),
                  CustomText(
                    text: 'Say hi to $tappedUserName!',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  SizedBox(height: 4.h),
                  CustomText(
                    text: 'No messages yet',
                    fontSize: 12.sp,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollCtrl,
          reverse: true,
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
          itemCount: docs.length,
          findChildIndexCallback: (key) {
            if (key is! ValueKey<String>) return null;
            final i = docs.indexWhere((d) => d.id == key.value);
            return i < 0 ? null : i;
          },
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final msgText = (data['message'] ?? '').toString();
            final senderId = (data['senderId'] ?? '').toString();
            final isMe = senderId == _currentUserId;
            final time = _toDate(data['timestamp']);

            final newerSender = index > 0
                ? ((docs[index - 1].data() as Map<String, dynamic>)['senderId'] ?? '')
                    .toString()
                : null;
            final olderData = index < docs.length - 1
                ? docs[index + 1].data() as Map<String, dynamic>
                : null;
            final isLastInGroup = newerSender != senderId;
            final isFirstInGroup =
                olderData == null || (olderData['senderId'] ?? '').toString() != senderId;

            final olderTime = olderData == null ? null : _toDate(olderData['timestamp']);
            final showDate = olderTime == null || !_sameDay(olderTime, time);

            return Column(
              key: ValueKey(doc.id),
              children: [
                if (showDate) _dateChip(time, isDark),
                AnimatedMessageBubble(
                  animate: newIds.contains(doc.id),
                  isMe: isMe,
                  child: _bubble(
                    text: msgText,
                    isMe: isMe,
                    time: time,
                    status: isMe ? _statusOf(doc, data) : null,
                    isDark: isDark,
                    isFirstInGroup: isFirstInGroup,
                    isLastInGroup: isLastInGroup,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _bubble({
    required String text,
    required bool isMe,
    required DateTime time,
    required MessageStatus? status,
    required bool isDark,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    final big = Radius.circular(18.r);
    final small = Radius.circular(4.r);
    final textColor = isMe
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1C1C28));
    final metaColor = isMe
        ? Colors.white70
        : (isDark ? Colors.white54 : Colors.black45);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 8.h : 2.h,
          left: isMe ? 48.w : 0,
          right: isMe ? 0 : 48.w,
        ),
        padding: EdgeInsets.fromLTRB(14.w, 9.h, 10.w, 6.h),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [NU_BLUE, Color(0xFF5562C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe ? null : (isDark ? const Color(0xFF24252B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: isMe || isFirstInGroup ? big : small,
            topRight: !isMe || isFirstInGroup ? big : small,
            bottomLeft: isMe || isLastInGroup ? big : small,
            bottomRight: !isMe || isLastInGroup ? big : small,
          ).copyWith(
            bottomRight: isMe && isLastInGroup ? small : null,
            bottomLeft: !isMe && isLastInGroup ? small : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: CustomText(
                text: text.isNotEmpty ? text : '[empty]',
                fontSize: 14.sp,
                color: textColor,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomText(
                  text: _formatTime(time),
                  fontSize: 10.sp,
                  color: metaColor,
                ),
                if (status != null) ...[
                  SizedBox(width: 4.w),
                  _statusIcon(status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(MessageStatus status) {
    late final Widget icon;
    switch (status) {
      case MessageStatus.sending:
        icon = Row(
          key: const ValueKey('sending'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 12.sp, color: Colors.white70),
            SizedBox(width: 2.w),
            CustomText(text: 'sending...', fontSize: 9.sp, color: Colors.white70),
          ],
        );
        break;
      case MessageStatus.delivered:
        icon = Icon(Icons.done, key: const ValueKey('delivered'),
            size: 14.sp, color: Colors.white70);
        break;
      case MessageStatus.seen:
        icon = Icon(Icons.done_all, key: const ValueKey('seen'),
            size: 14.sp, color: NU_YELLOW);
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: icon,
    );
  }

  Widget _dateChip(DateTime time, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: CustomText(
          text: _formatDay(time),
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  Widget _composer(bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF17181C) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF24252B) : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(fontFamily: 'Poppins'),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            AnimatedScale(
              scale: _hasText ? 1.0 : 0.85,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hasText ? NU_BLUE : Colors.grey.shade400,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: _hasText ? _send : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _toDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    return DateTime.now();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(DateTime t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  String _formatDay(DateTime t) {
    final now = DateTime.now();
    if (_sameDay(t, now)) return 'Today';
    if (_sameDay(t, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[t.month - 1]} ${t.day}, ${t.year}';
  }
}

class AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool animate;
  final bool isMe;

  const AnimatedMessageBubble({
    super.key,
    required this.child,
    required this.animate,
    required this.isMe,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.isMe ? 0.3 : -0.3, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}