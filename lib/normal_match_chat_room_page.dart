import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'normal_match_review_page.dart';

class NormalMatchChatRoomPage extends StatefulWidget {
  final String roomId;
  final String currentUser;
  final String userName;
  final String departure;
  final String destination;
  final String departureTime;
  final String kakaopayDeeplink;
  final Future<void> Function() onExit;
  final List<Map<String, dynamic>> initialMessages;

  NormalMatchChatRoomPage({
    required this.roomId,
    required this.currentUser,
    required this.userName,
    required this.departure,
    required this.destination,
    required this.departureTime,
    required this.kakaopayDeeplink,
    required this.onExit,
    required this.initialMessages,
  });

  @override
  _NormalMatchChatRoomPageState createState() => _NormalMatchChatRoomPageState();
}

class _NormalMatchChatRoomPageState extends State<NormalMatchChatRoomPage>
    with WidgetsBindingObserver {
  WebSocketChannel? channel;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final Set<String> _uniqueMessages = {};
  List<Map<String, dynamic>> _participants = [];
  int _participantsCount = 1;
  bool _isConnected = false;
  bool _isLeader = false;
  bool _recruitmentComplete = false;
  bool _leaveEnabled = true;
  bool _settlementComplete = false;
  String? _settlementDeeplink;
  bool _showInfoBox = false;
  bool _isInfoBoxExpanded = false;
  Offset _bellButtonPosition = Offset(16, 150); // 종 버튼의 초기 위치

   @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages.addAll(widget.initialMessages);
    _joinRoom();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_isConnected) {
        _connectToWebSocket();
      }
    }
  }

  void _toggleInfoBox() {
    setState(() {
      _showInfoBox = !_showInfoBox;
      if (!_showInfoBox) _isInfoBoxExpanded = false; // 알림 박스를 숨길 때는 접기
    });
  }

  void _toggleExpandInfoBox() {
  setState(() {
    _isInfoBoxExpanded = !_isInfoBoxExpanded;
  });
}

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _joinRoom() async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://35.238.24.244:8000/chat/join_room/${widget.roomId}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUser,
          'user_name': widget.userName,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _participants = (data['room_data']['participants'] ?? [])
                .map<Map<String, dynamic>>(
                    (participant) => participant as Map<String, dynamic>)
                .toList();
            _participantsCount = _participants.length;
            _isLeader = _participants.any((p) =>
                p['user_id'] == widget.currentUser && p['leader'] == true);
          });
        }

        if (!_isConnected) {
          _connectToWebSocket();
        }
      } else {
        debugPrint('Failed to join room: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error joining room: $e');
    }
  }

  Future<void> _completeRecruitment() async {
    if (!_isLeader || _participantsCount < 2) return;
    try {
      final response = await http.post(
        Uri.parse(
            'http://35.238.24.244:8000/chat/complete_recruitment/${widget.roomId}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': widget.currentUser}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _recruitmentComplete = true;
            _leaveEnabled = false;
          });
        }
        debugPrint('Recruitment completed successfully.');
      } else {
        debugPrint('Failed to complete recruitment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error completing recruitment: $e');
    }
  }

  void _showSettlementDialog() {
    if (!_recruitmentComplete) {
      _showRecruitmentNotCompleteMessage();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _amountController = TextEditingController();
        return AlertDialog(
          backgroundColor: const Color(0xFF5C5B56), // 배경색 검정색
          title: const Text(
            '정산하기',
            style: TextStyle(color: Colors.white), // 제목 글자색 흰색
          ),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white), 
            cursorColor: Colors.white,// Set input text color to white
            decoration: const InputDecoration(
              hintText: '총 금액을 입력하세요',
              hintStyle: TextStyle(color: Colors.white54), // Set hint text color to gray
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Default underline color
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white), // Set focused underline to black
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                '취소',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _settlePayment(_amountController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRecruitmentNotCompleteMessage() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF5C5B56), // Set background color to black
        title: const Text(
          '알림',
          style: TextStyle(color: Colors.white), // Set title text color to white
        ),
        content: const Text(
          '모집이 완료된 후에만 정산을 진행할 수 있습니다.',
          style: TextStyle(color: Colors.white), // Set content text color to white
        ),
        actions: [
          TextButton(
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white), // Set button text color to white
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

  Future<void> _settlePayment(String totalAmount) async {
    if (!_recruitmentComplete || !_isLeader) return;

    try {
      final perPersonAmount = (double.parse(totalAmount) / _participantsCount).round();
      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/chat/settle_payment/${widget.roomId}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUser,
          'total_amount': totalAmount,
          'per_person_amount': perPersonAmount, // 계산된 금액을 전송
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _settlementComplete = true;
            _leaveEnabled = true;
          });
        }
        debugPrint('Settlement completed successfully.');
      } else {
        debugPrint('Failed to complete settlement: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during settlement: $e');
    }
  }

  Future<void> _leaveRoom() async {
    try {
      if (_recruitmentComplete && !_settlementComplete) {
        debugPrint(
            "Recruitment completed. You cannot leave until settlement is done.");
        return;
      }

      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/chat/exit_room/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'room_id': widget.roomId, 'user_id': widget.currentUser}),
      );

      if (response.statusCode == 200) {
        debugPrint('Successfully left the room');
      } else {
        debugPrint('Failed to leave the room: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error while leaving the room: $e');
    }
  }

  Future<void> _exitRoom(BuildContext context) async {
    await _leaveRoom();

    if (_settlementComplete) {
      final finalParticipants = await _fetchFinalParticipants();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => NormalMatchReviewPage(
            currentUser: widget.currentUser,
            roomId: widget.roomId,
            finalParticipants: finalParticipants,
          ),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            currentUser: widget.currentUser,
            userName: widget.userName,
          ),
        ),
        (route) => false,
      );
    }
  }

  void _connectToWebSocket() {
    if (_isConnected) return;

    channel = WebSocketChannel.connect(
      Uri.parse(
          'ws://35.238.24.244:8000/ws/chat/${widget.roomId}/?token=${widget.currentUser}'),
    );

    channel!.stream.listen((message) {
      _handleIncomingMessage(message);
    }, onError: (error) {
      debugPrint('WebSocket Error: $error');
      _disconnectWebSocket();
    }, onDone: () {
      debugPrint('WebSocket connection closed');
      _disconnectWebSocket();
    });

    if (mounted) {
      setState(() {
        _isConnected = true;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchFinalParticipants() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://35.238.24.244:8000/chat/get_final_participants/${widget.roomId}/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['final_participants']);
      } else {
        print('Failed to fetch final participants: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching final participants: $e');
      return [];
    }
  }

  void _handleIncomingMessage(dynamic message) {
    try {
      final decodedMessage = _decodeMessage(message);

      if (decodedMessage is! Map<String, dynamic>) {
        debugPrint(
            "Received a message that is not in the expected format: $decodedMessage");
        return;
      }

      final bool isSystemMessage = decodedMessage['is_system_message'] ?? false;
      final String uniqueKey = isSystemMessage
          ? '${decodedMessage['message']}_${DateTime.now().toIso8601String()}'
          : '${decodedMessage['user_id']}_${decodedMessage['message']}_${decodedMessage['timestamp']}';

      if (!_uniqueMessages.contains(uniqueKey)) {
        _uniqueMessages.add(uniqueKey);

        if (mounted) {
          setState(() {
            if (decodedMessage.containsKey('participants')) {
              _participantsCount = decodedMessage['participants']?.length ?? 0;
              _participants = List<Map<String, dynamic>>.from(
                  decodedMessage['participants'] ?? []);
              _isLeader = _participants.any(
                  (p) => p['user_id'] == widget.currentUser && p['leader']);
            }

            if (decodedMessage.containsKey('message')) {
              _messages.add({
                'user': isSystemMessage ? 'System' : decodedMessage['user'],
                'user_id': decodedMessage['user_id'],
                'message': decodedMessage['message'],
                'timestamp': decodedMessage['timestamp'] ??
                    DateTime.now().toIso8601String(),
              });
            }

            if (decodedMessage.containsKey('block_exit')) {
              _leaveEnabled = false;
            }

            if (decodedMessage.containsKey('deeplink')) {
              _settlementDeeplink = decodedMessage['deeplink'];
              final perPersonAmount = decodedMessage['per_person_amount'];

              _messages.add({
                'user': 'System',
                'message': '결제 하실 금액은 ${perPersonAmount}원입니다!',
                'deeplink': _settlementDeeplink,
                'timestamp': DateTime.now().toIso8601String(),
              });

              _settlementComplete = true;
              _leaveEnabled = true;
            }

            if (decodedMessage.containsKey('allow_exit')) {
              _leaveEnabled = true;
            }
          });
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      debugPrint('Error processing message: $e');
      debugPrint('Original message: $message');
    }
  }

  Map<String, dynamic> _decodeMessage(dynamic message) {
    try {
      if (message is String) {
        return jsonDecode(message);
      } else if (message is List<int>) {
        return jsonDecode(utf8.decode(message));
      } else {
        debugPrint('Unexpected message type received: $message');
        return {};
      }
    } catch (e) {
      debugPrint("Failed to decode message: $message");
      return {};
    }
  }

  Future<void> _disconnectWebSocket() async {
    if (_isConnected && channel != null) {
      await channel!.sink.close(1000);
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && channel != null && _isConnected) {
      final jsonMessage = jsonEncode({
        'user': widget.userName,
        'user_id': widget.currentUser,
        'message': _controller.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint("Sending message: $jsonMessage");
      channel!.sink.add(jsonMessage);
      _controller.clear();
    } else {
      debugPrint(
          'Cannot send message: WebSocket not connected or message is empty.');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    _disconnectWebSocket();
    super.dispose();
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final timestamp = message['timestamp'] ?? DateTime.now().toIso8601String();
    final time = DateFormat('a h:mm', 'ko_KR')
        .format(DateTime.parse(timestamp).toLocal());

    bool isCurrentUser = message['user_id'] == widget.currentUser;
    bool isSystemMessage = message['user'] == 'System';
    bool isConnectMessage = message['user'] == null;

    final messageText = message['message'] ?? '';

    return Align(
      alignment: isConnectMessage
          ? Alignment.center
          : (isSystemMessage
              ? Alignment.center
              : (isCurrentUser ? Alignment.centerRight : Alignment.centerLeft)),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isConnectMessage
              ? Colors.transparent
              : isSystemMessage
                  ? Colors.grey[200]
                  : (isCurrentUser ? const Color(0xFF5C5B56) : Colors.white),
          borderRadius: isConnectMessage ? null : BorderRadius.circular(12.0),
        ),
        child: Column(
          crossAxisAlignment: isConnectMessage
              ? CrossAxisAlignment.center
              : (isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start),
          children: [
            if (!isConnectMessage && !isSystemMessage)
              Text(
                message['user'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
                textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
              ),
            if (!isConnectMessage) const SizedBox(height: 4.0),
            if (message.containsKey('deeplink'))
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(message['deeplink']);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: Text(
                  message['message'], // Display only "결제하실 금액은 n원입니다!"
                  style: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              )
            else
              Text(
                messageText,
                textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black,
                ),
              ),
            if (message.containsKey('perPersonAmount'))
              Text(
                '1인당 금액: ${message['perPersonAmount']}원',
                textAlign: TextAlign.left,
                style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
              ),
            if (!isConnectMessage && !isSystemMessage)
              const SizedBox(height: 4.0),
            if (!isConnectMessage && !isSystemMessage)
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
              ),
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
              style: const TextStyle(color: Colors.white),
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
              enabled: _isConnected,
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _isConnected ? _sendMessage : null,
          ),
        ],
      ),
    );
  }




  Widget _buildCompleteRecruitmentButton() {
    return ElevatedButton(
      onPressed: (_recruitmentComplete || !_isLeader || _participantsCount < 2)
          ? null
          : _completeRecruitment,
      child: const Text('모집 마감하기'),
    );
  }

  Widget _buildSettlementButton() {
    return ElevatedButton(
      onPressed: (_recruitmentComplete && !_settlementComplete)
          ? _showSettlementDialog
          : null,
      child: const Text('정산하기'),
    );
  }

  Widget _buildExitButton(BuildContext context) {
    return ElevatedButton(
      onPressed: _leaveEnabled ? () => _exitRoom(context) : null,
      child: const Text('나가기'),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFFFEF9EB), // Set sidebar background to yellow
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          Container(
            height: 56.0,
            color: const Color(0xFF5C5B56), // Header background color
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              '추가 기능',
              style: TextStyle(color: Colors.white), // Header text color
            ),
          ),
          ListTile(
            leading: const Icon(Icons.group_add, color: const Color(0xFF5C5B56)), // Icon color white
            title: const Text(
              '모집 마감하기',
              style: TextStyle(color: const Color(0xFF5C5B56)), // Text color white
            ),
            onTap: (_recruitmentComplete || !_isLeader || _participantsCount < 2)
                ? null
                : _completeRecruitment,
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: const Color(0xFF5C5B56)), // Icon color white
            title: const Text(
              '정산하기',
              style: TextStyle(color: const Color(0xFF5C5B56)), // Text color white
            ),
            onTap: _settlementComplete ? null : _showSettlementDialog,
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: const Color(0xFF5C5B56)), // Icon color white
            title: const Text(
              '나가기',
              style: TextStyle(color: const Color(0xFF5C5B56)), // Text color white
            ),
            onTap: _leaveEnabled ? () => _exitRoom(context) : null,
          ),
          Container(
            color: const Color(0xFF5C5B56), // Section background color
            child: const ListTile(
              title: Text(
                '참여자 목록',
                style: TextStyle(color: Colors.white), // Section title text color
              ),
            ),
          ),
          ..._participants.map((participant) {
            bool isLeader = participant['leader'] ?? false;
            return ListTile(
              title: Text(
                participant['user_name'] ?? 'Unknown',
                style: const TextStyle(color: const Color(0xFF5C5B56)), // Participant name color white
              ),
              subtitle: isLeader
                  ? const Text(
                      '방장',
                      style: TextStyle(color: const Color(0xFF5C5B56)), // Subtitle color white
                    )
                  : null,
            );
          }).toList(),
        ],
      ),
    );
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          backgroundColor: const Color(0xFF5C5B56),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.departure} → ${widget.destination}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '출발 시간: ${DateFormat('yyyy년 MM월 dd일 HH:mm').format(DateTime.parse(widget.departureTime).toLocal())}',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                Text(
                  '참여 인원: $_participantsCount/4',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: _toggleInfoBox,
            ),
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
      ),
      endDrawer: _buildSidebar(context),
      body: Column(
        children: [
          if (_showInfoBox) _buildInfoBox(), // 채팅창 상단에 알림 박스 배치
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color.fromARGB(255, 218, 218, 218),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '돈이 인원수만큼 나눠지지 않고,',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              IconButton(
                icon: Icon(
                  _isInfoBoxExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: _toggleExpandInfoBox,
              ),
            ],
          ),
          if (_isInfoBoxExpanded)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                '소수점으로 나눠졌을 경우 반올림으로 작동하고 있습니다.\n 추후 수정예정입니다.',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // 정보 버튼과 채팅 입력을 감싸는 위젯
  Widget _buildInfoButtonAndChatInput() {
    return Column(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.black),
          onPressed: _toggleInfoBox,
        ),
        _buildChatInput(),
      ],
    );
  }
}
