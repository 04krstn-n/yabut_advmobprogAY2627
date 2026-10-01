import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yabut_advmobprog/models/messages.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = Map<String, dynamic>.from(doc.data());
        if ((user['uid'] ?? '').toString().isEmpty) {
          user['uid'] = doc.id;
        }
        return user;
      }).toList();
    });
  }

  // send message
  Future<void> sendMessage(String receiverId, message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String? currentUserEmail = _firebaseAuth.currentUser!.email;
    final Timestamp timestamp = Timestamp.now();
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? "",
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // construct chat room ID for the two users (sorted to ensure uniqueness)
    String chatRoomID = _chatRoomId(currentUserId, receiverId);
    // add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // get message
  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    String chatRoomID = _chatRoomId(userID, otherUserID);

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  Future<void> markMessagesAsSeen(List<DocumentReference> refs) async {
    if (refs.isEmpty) return;
    final batch = _firestore.batch();
    for (final ref in refs) {
      batch.update(ref, {'seen': true, 'seenAt': Timestamp.now()});
    }
    await batch.commit();
  }

  // sort the ids (this ensure the chatroomID is the same for any 2 people)
  String _chatRoomId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join("_");
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    // Ensure your Users doc actually stores the Firebase Auth UID in a field `uid`
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}