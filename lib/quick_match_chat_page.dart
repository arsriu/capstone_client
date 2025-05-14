import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import 'quick_match_chat_room_page.dart';

class QuickMatchChatPage extends StatefulWidget {
  final String currentUser;
  final String userName;
  final String roomId;
  final String departure;
  final String destination;
  final Function(Map<String, dynamic>) onChatRoomJoined;

  QuickMatchChatPage({
    required this.currentUser,
    required this.userName,
    required this.roomId,
    required this.departure,
    required this.destination,
    required this.onChatRoomJoined,
  });

  @override
  _QuickMatchChatPageState createState() => _QuickMatchChatPageState();
}

class _QuickMatchChatPageState extends State<QuickMatchChatPage> {
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  WebSocketChannel? _channel;
  int _secondsLeft = 30;
  bool _isConnected = false;
  bool _recruitmentComplete = false;
  bool _showMatchingComplete = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (widget.roomId.isNotEmpty) {
      _joinRoom();
      _initializeWebSocket();
    } else {
      _showErrorSnackbar('유효하지 않은 방 ID입니다. 다시 시도해주세요.');
    }
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _exitRoom();
    super.dispose();
  }

  Future<bool> _disableBackButton() async {
    return false; // Disable back button functionality
  }

  void _initializeWebSocket() {
    if (_isConnected) return; // Prevent redundant connections

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
            'ws://35.238.24.244:8000/ws/quick_chat/${widget.roomId}/?user_id=${widget.currentUser}'),
      );

      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);
          if (!mounted) return;

          switch (data['type']) {
            case 'participants_update':
              _updateParticipants(data['participants']);
              break;
            case 'timer_update':
              _updateCountdown(data['countdown']);
              break;
            case 'matching_complete':
              _handleMatchingComplete(data);
              break;
            case 'chat_start':
              _handleChatStart(data);
              break;
            default:
              // Unknown message types are ignored instead of showing an error snackbar
              debugPrint('Unknown WebSocket message type: ${data['type']}');
          }
        },
        onError: (error) {
          _showErrorSnackbar('WebSocket Error: $error');
          _reconnectWebSocket();
        },
        onDone: () {
          if (!_isNavigating) _reconnectWebSocket();
        },
      );

      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to connect WebSocket: $e');
    }
  }

  void _reconnectWebSocket() {
    if (!_isConnected) {
      Future.delayed(Duration(seconds: 5), () {
        if (!_isConnected && mounted) {
          _initializeWebSocket();
        }
      });
    }
  }

  Future<void> _disconnectWebSocket() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close(1000); // Close WebSocket with normal closure code
        _channel = null;
      } catch (e) {
        _showErrorSnackbar('Error closing WebSocket: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isConnected = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://35.238.24.244:8000/quick_chat/quick_join_room/${widget.roomId}/'),
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
            _participants =
                List<Map<String, dynamic>>.from(data['participants'] ?? []);
            _isLoading = false;
            _recruitmentComplete = data['recruitment_complete'] ?? false;
          });
        }

        widget.onChatRoomJoined(data);
      } else {
        _showErrorSnackbar('Failed to join room: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error joining room: $e');
    }
  }

  Future<void> _exitRoom() async {
    if (!mounted) return;

    try {
      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/quick_chat/quick_exit_room/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_id': widget.roomId,
          'user_id': widget.currentUser,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'room_deleted' && mounted) {
          Navigator.pop(context);
        } else {
          _showErrorSnackbar('You have left the room');
          if (mounted) Navigator.pop(context);
        }
      } else {
        _showErrorSnackbar('Failed to exit room: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error exiting room: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _handleMatchingComplete(Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      _showMatchingComplete = true;
      _participants =
          List<Map<String, dynamic>>.from(data['participants'] ?? []);
    });
  }

  void _handleChatStart(Map<String, dynamic> data) async {
    if (!mounted) return;

    final updatedParticipants =
        List<Map<String, dynamic>>.from(data['participants'] ?? []);
    setState(() {
      _participants = updatedParticipants;
      _recruitmentComplete = true;
      _showMatchingComplete = false;
    });

    await Future.delayed(Duration(seconds: 2));
    _navigateToChatRoom();
  }

  void _updateParticipants(dynamic participants) {
    if (!mounted) return;

    setState(() {
      _participants = List<Map<String, dynamic>>.from(participants);

      if (_participants.length == 4 &&
          _participants.every((p) => p['ready'] == true)) {
        _recruitmentComplete = true;
      } else if (_participants.length < 2) {
        _secondsLeft = 30;
      }
    });
  }

  void _updateCountdown(int countdown) {
    if (_recruitmentComplete || !mounted) return;

    setState(() {
      _secondsLeft = countdown;
    });
  }

  void _navigateToChatRoom() {
    if (!mounted) return;

    setState(() {
      _isNavigating = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuickMatchChatRoomPage(
          roomId: widget.roomId,
          currentUser: widget.currentUser,
          userName: widget.userName,
          departure: widget.departure,
          destination: widget.destination,
          participants: _participants,
        ),
      ),
    ).then((_) {
      setState(() {
        _isNavigating = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _disableBackButton,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFFEF9EB),
          automaticallyImplyLeading: false,
        ),
        backgroundColor: const Color(0xFFFEF9EB),
        body: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('참가자를 찾는중입니다...', style: TextStyle(fontSize: 16)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '출발지 : ${widget.departure}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '도착지: ${widget.destination}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: 250,
                      height: 250,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _buildParticipantSlot(index);
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_showMatchingComplete)
                      Text('매칭이 완료되었습니다!',
                          style: TextStyle(fontSize: 18, color: Colors.green)),
                    if (!_recruitmentComplete && _secondsLeft > 0)
                      Text('매칭까지 남은 시간: $_secondsLeft 초',
                          style: TextStyle(fontSize: 18, color: Colors.red)),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (mounted) {
              _exitRoom();
            }
          },
          backgroundColor: const Color(0xFF5C5B56),
          child: Icon(Icons.exit_to_app, color: Colors.white),
          tooltip: 'Exit Room',
        ),
      ),
    );
  }

  Widget _buildParticipantSlot(int index) {
    if (index < _participants.length) {
      final participant = _participants[index];
      final userName = participant['user_name'] ?? 'Unknown';
      final ready = participant['ready'] ?? false;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 50,
            color: ready ? const Color.fromARGB(255, 109, 109, 109) : const Color.fromARGB(255, 0, 0, 0),
          ),
          SizedBox(height: 8),
          Text(userName, style: TextStyle(fontSize: 16)),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 50, color: Colors.grey),
          SizedBox(height: 8),
          Text('대기중...', style: TextStyle(fontSize: 16)),
        ],
      );
    }
  }
}
