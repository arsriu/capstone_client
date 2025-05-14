import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'home_page.dart';
import 'quick_match_review_page.dart'; // Import the review page

const String baseUrl = 'http://35.238.24.244:8000';

class QuickMatchChatRoomPage extends StatefulWidget {
  final String roomId;
  final String currentUser;
  final String userName;
  final String departure;
  final String destination;
  final List<Map<String, dynamic>> participants;

  QuickMatchChatRoomPage({
    required this.roomId,
    required this.currentUser,
    required this.userName,
    required this.departure,
    required this.destination,
    required this.participants,
  });

  @override
  _QuickMatchChatRoomPageState createState() => _QuickMatchChatRoomPageState();
}

class _QuickMatchChatRoomPageState extends State<QuickMatchChatRoomPage> {
  WebSocketChannel? channel;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _participants = [];
  bool _isCalculationSent = false;
  bool _canExitRoom = false;
  final ScrollController _scrollController = ScrollController();
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _participants = widget.participants;
    _connectToWebSocket();
    _addSystemMessage('모집이 완료되었습니다. 방장을 정하고 목적지 도착 후 정산하기를 이용해주세요.');
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _updateTime());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _currentTime = TimeOfDay.now().format(context);
    });
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _controller.dispose();
    _totalAmountController.dispose();
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchKakaoPayDeeplink() async {
    String totalAmount = _totalAmountController.text;
    int amount = int.tryParse(totalAmount) ?? 0;

    final response = await http.post(
      Uri.parse('$baseUrl/quick_chat/calculate_and_deeplink/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': widget.currentUser,
        'room_id': widget.roomId,
        'total_amount': amount,
        'participants_count': _participants.length,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final kakaopayLink = data['deeplink'];

      setState(() {
        _messages.add({
          'user_name': widget.userName,
          'message': '정산을 완료하였습니다. 위의 링크로 결제를 진행하고 나가기를 진행해주세요.',
          'timestamp': DateTime.now().toIso8601String(),
        });
        _scrollToBottom();
        _canExitRoom = true;
        _isCalculationSent = true;
      });

      if (channel != null) {
        channel!.sink.add(jsonEncode({
          'type': 'settlement_complete',
          'message': '정산을 완료하였습니다. 위의 링크로 결제를 진행하고 나가기를 진행해주세요.',
        }));
      }
    } else {
      _showErrorSnackbar("오류가 발생했습니다. 다시 한번 시도해주세요.");
    }
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://35.238.24.244:8000/ws/quickquick_chat/${widget.roomId}/?user_id=${widget.currentUser}'),
    );

    channel!.stream.listen(
      (message) {
        final decodedMessage = jsonDecode(message);
        if (decodedMessage['type'] == 'settlement_complete') {
          setState(() {
            _canExitRoom = true;
            _isCalculationSent = true;
          });
          if (decodedMessage.containsKey('deeplink')) {
            setState(() {
              _messages.add({
                'user_name': 'System',
                'message': decodedMessage['message'],
                'timestamp': DateTime.now().toIso8601String(),
                'link': decodedMessage['deeplink']
              });
              _scrollToBottom();
            });
          }
        } else if (decodedMessage['user_name'] != widget.userName) {
          _handleIncomingMessage(decodedMessage);
        }
      },
      onError: (error) {
        print('WebSocket Error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );
  }

  void _disconnectWebSocket() {
    if (channel != null) {
      channel!.sink.close(status.normalClosure);
      channel = null;
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && channel != null) {
      final jsonMessage = jsonEncode({
        'user_name': widget.userName,
        'user_id': widget.currentUser,
        'message': _controller.text,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _messages.add({
          'user_name': widget.userName,
          'user_id': widget.currentUser,
          'message': _controller.text,
          'timestamp': DateTime.now().toIso8601String(),
        });
      });

      channel!.sink.add(jsonMessage);
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    setState(() {
      _messages.add(message);
      _scrollToBottom();
    });
  }

  void _calculateAndSend() {
    if (_isCalculationSent) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF5C5B56),
          title: Text('정산하기', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _totalAmountController,
                cursorColor: const Color(0xFF5C5B56),
                decoration: InputDecoration(
                  labelText: '총 금액을 입력하세요',
                  labelStyle: TextStyle(color: const Color(0xFF5C5B56)),
                  filled: true,
                  fillColor: const Color(0xFFFEF9EB),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF5C5B56)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF5C5B56)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: const Color(0xFF5C5B56)),
                  ),
                ),
                style: TextStyle(color: const Color(0xFF5C5B56)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEF9EB),
                foregroundColor: const Color(0xFF5C5B56),
              ),
              onPressed: () {
                _fetchKakaoPayDeeplink();
                Navigator.of(context).pop();
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _exitRoom() async {
    if (!_canExitRoom) {
      _showErrorSnackbar('정산이 완료되어야 나가실 수 있습니다.');
      return;
    }

    _disconnectWebSocket();

    final response = await http.post(
      Uri.parse('$baseUrl/quick_chat/quickquick_exit_room/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_id': widget.roomId,
        'user_id': widget.currentUser,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final reviewParticipants = data['review_participants'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuickMatchReviewPage(
            currentUser: widget.currentUser,
            roomId: widget.roomId,
            finalParticipants: reviewParticipants.cast<Map<String, dynamic>>(),
          ),
        ),
      );
    } else {
      _showErrorSnackbar("방을 나가실 수 없습니다. 다시한번 시도해주세요.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _addSystemMessage(String message) {
    setState(() {
      _messages.add({
        'user_name': 'System',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      _scrollToBottom();
    });
  }

  Widget _buildParticipantIcon(Map<String, dynamic> participant) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 50, color: const Color(0xFF5C5B56)),
        SizedBox(height: 8),
        Text(
          participant['user_name'] ?? '대기중...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildWaitingIcon() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person, size: 50, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          '대기중...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final user = message['user_name'];
    final messageText = message['message'] ?? '';
    final link = message['link'];

    Alignment alignment;
    Color messageColor;
    String displayUserName = '';

    if (user == widget.userName) {
      alignment = Alignment.centerRight;
      messageColor = const Color(0xFF5C5B56);
    } else if (user == 'System' || user == null) {
      alignment = Alignment.center;
      messageColor = const Color.fromARGB(255, 122, 122, 122);
    } else {
      alignment = Alignment.centerLeft;
      messageColor = Colors.grey[100]!;
      displayUserName = user ?? '';
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: messageColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: GestureDetector(
          onTap: link != null && link.isNotEmpty
              ? () async {
                  final uri = Uri.tryParse(link);
                  if (uri != null) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayUserName.isNotEmpty)
                Text(
                  displayUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              Text(
                messageText,
                style: TextStyle(
                  color: link != null
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : (user == widget.userName || user == 'System' || user == null)
                          ? Colors.white
                          : Colors.black,
                  decoration: link != null ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF5C5B56),
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${widget.departure} → ${widget.destination}',
                  style: TextStyle(color: Colors.white)),
              Text(
                '참여 인원: ${_participants.length}/4  |  $_currentTime',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.calculate, color: Colors.white),
              onPressed: _isCalculationSent ? null : _calculateAndSend,
              tooltip: '정산하기',
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: _exitRoom,
              tooltip: '나가기',
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFEF9EB),
        body: Column(
          children: [
            SizedBox(
              height: 100,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return index < _participants.length
                        ? _buildParticipantIcon(_participants[index])
                        : _buildWaitingIcon();
                  }),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      color: const Color(0xFF5C5B56),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                labelText: '메시지 입력...',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
