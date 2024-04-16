import 'dart:convert';
import 'dart:async';
import 'package:easyroom/models/ReservationModel.dart';
import 'package:easyroom/requests/constant.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:easyroom/models/User.dart';

const storage = FlutterSecureStorage();

class ChatScreen extends StatefulWidget {
  final ReservationModel rdv;
  final User user;

  const ChatScreen({Key? key, required this.rdv, required this.user}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  final String apiUrl = "$BASE_URL/chat";
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _fetchMessages() async {
    final token = await storage.read(key: 'token');
    final response = await http.get(
        Uri.parse("$apiUrl/${widget.rdv.houseId}"),
        headers: {
          'Authorization': 'Bearer $token'
        }
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<ChatMessage> messages = data.map((e) => ChatMessage(
        text: e['message'],
        sender: User.fromJson(e['Sender']),
        receiver: User.fromJson(e['Receiver']),
        connectedUser: widget.user,
      )).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } else {
      print('Failed to fetch messages: ${response.statusCode}');
    }
  }

  void _handleSubmitted(String text) async {
    final token = await storage.read(key: 'token');
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      sender: widget.user,
      receiver: widget.rdv.house.userId,
      connectedUser: widget.user,
    );
    setState(() {
      _messages.insert(0, message);
    });

    final response = await http.post(
      Uri.parse("$apiUrl/add"),
      body: jsonEncode({
        'message': text,
        "house_id": widget.rdv.houseId,
        "receiver_id": widget.rdv.house.userId
      }),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (response.statusCode == 201) {
      // Handle API response if necessary
    } else {
      print('Failed to send message: ${response.statusCode}');
    }
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: "Commencer une discussion",
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discussion"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _messages[index],
              ),
            ),
          ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final User sender;
  final dynamic receiver;
  final User connectedUser;

  const ChatMessage({Key? key, required this.text, required this.sender, required this.receiver, required this.connectedUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isSender = sender.id == connectedUser.id;

    return Container(
      margin: EdgeInsets.only(
        left: isSender ? 64.0 : 8.0,
        right: isSender ? 8.0 : 64.0,
        top: 4.0,
        bottom: 4.0,
      ),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isSender ? Colors.blue[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(sender.name, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4.0),
          Text(text),
        ],
      ),
    );
  }
}
