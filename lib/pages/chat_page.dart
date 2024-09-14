import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;

  ChatPage({required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendMessage() async {
    var user = _auth.currentUser;
    if (user != null && _messageController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('chats').doc(user.uid).collection('messages').add({
        'senderId': user.uid,
        'receiverId': widget.receiverId,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isSeen': false,
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(user!.uid)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                var messages = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSender = message['senderId'] == user.uid;
                    return ListTile(
                      title: Text(message['message']),
                      subtitle: Text("${message['timestamp'].toDate()}"),
                      trailing: message['isSeen'] ? Icon(Icons.check) : null,
                      contentPadding: EdgeInsets.all(10),
                      tileColor: isSender ? Colors.blue[100] : Colors.grey[200],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(labelText: 'Escribe un mensaje'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
