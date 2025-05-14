import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'quick_match_chat_page.dart'; // Ensure this import points to the correct file
import 'select_location_page.dart';
import 'moving_taxi_page.dart';

class QuickMatchPage extends StatefulWidget {
  final String currentUser;
  final String userName;
  final Function(Map<String, dynamic>) onChatRoomJoined;

  QuickMatchPage({
    required this.currentUser,
    required this.userName,
    required this.onChatRoomJoined,
  });

  @override
  _QuickMatchPageState createState() => _QuickMatchPageState();
}

class _QuickMatchPageState extends State<QuickMatchPage> {
  String _departure = '출발지 선택';
  String _destination = '도착지 선택';
  Position? _currentPosition;
  double? _departureLat;
  double? _departureLng;

  @override
  void initState() {
    super.initState();
    _setMockPosition();
  }

  void _setMockPosition() {
    _currentPosition = Position.fromMap({
      "latitude": 37.401683,
      "longitude": 126.922730,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
      "accuracy": 5.0,
      "altitude": 0.0,
      "heading": 0.0,
      "speed": 0.0,
      "speed_accuracy": 0.0,
    });
    setState(() {});
  }

  void _swapLocations() {
    final temp = _departure;
    _departure = _destination;
    _destination = temp;

    final tempLat = _departureLat;
    _departureLat = _departureLng;
    _departureLng = tempLat;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EB),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 1), // 간격 추가 필요시 수정 가능
                Transform.translate(
                  offset: const Offset(0, -10), // 이미지 위로 10px 이동
                  child: Center(
                    child: Image.asset(
                      'assets/quick_match_logo.png',
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: 160, // Adjusted height for visibility, 원래는 160
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 1), // 간격 조절 필요시 수정 가능
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '출발지',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'CrimsonText',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 92, 90, 85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _showMovingTaxiPage,
                      child: const Text(
                        '주변 택시 보기',
                        style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'CrimsonText',
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final locationData = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectLocationPage(title: '출발지 선택'),
                      ),
                    );
                    if (locationData != null && locationData['title'] != null) {
                      setState(() {
                        _departure = locationData['title'];
                        _departureLat =
                            double.tryParse(locationData['latitude']);
                        _departureLng =
                            double.tryParse(locationData['longitude']);
                      });
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        _departure,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'CrimsonText',
                          color: Color.fromARGB(255, 54, 53, 53),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Divider(color: Colors.grey, thickness: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '도착지',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'CrimsonText',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final locationData = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SelectLocationPage(title: '도착지 선택'),
                          ),
                        );
                        if (locationData != null &&
                            locationData['title'] != null) {
                          setState(() {
                            _destination = locationData['title'];
                          });
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            _destination,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'CrimsonText',
                              color: Color.fromARGB(255, 54, 53, 53),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Divider(color: Colors.grey, thickness: 1),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 0, 0, 0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _departure != '출발지 선택' && _destination != '도착지 선택'
                        ? _startMatching
                        : () => _showErrorSnackbar('출발지와 도착지를 모두 선택해주세요.'),
                    child: const Text(
                      '매칭 시작',
                      style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'CrimsonText',
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startMatching() async {
    if (!_isUserNearDeparture()) {
      _showErrorSnackbar('출발지에서 150미터 이내에 있어야 합니다.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse(
            'http://35.238.24.244:8000/quick_chat/match_or_create_room/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.currentUser,
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'departure': _departure,
          'destination': _destination,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('error') &&
            data['error'] == 'Recruitment is complete') {
          _showRecruitmentCompleteMessage();

          final newRoomResponse = await http.post(
            Uri.parse('http://35.238.24.244:8000/quick_chat/create_new_room/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': widget.currentUser,
              'user_name': widget.userName,
              'departure': _departure,
              'destination': _destination,
            }),
          );

          if (newRoomResponse.statusCode == 200) {
            final newRoomData = jsonDecode(newRoomResponse.body);
            final newRoomId = newRoomData['room_id'];

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuickMatchChatPage(
                  currentUser: widget.currentUser,
                  userName: widget.userName,
                  roomId: newRoomId,
                  departure: _departure,
                  destination: _destination,
                  onChatRoomJoined: widget.onChatRoomJoined,
                ),
              ),
            );
          } else {
            _showErrorSnackbar('Failed to create a new room.');
          }
        } else {
          final roomId = data['room_id'];
          if (roomId != null && roomId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuickMatchChatPage(
                  currentUser: widget.currentUser,
                  userName: widget.userName,
                  roomId: roomId,
                  departure: _departure,
                  destination: _destination,
                  onChatRoomJoined: widget.onChatRoomJoined,
                ),
              ),
            );
          }
        }
      } else {
        _showErrorSnackbar('Matching failed. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred. Please try again: $e');
    }
  }

  void _showMovingTaxiPage() {
    if (_departureLat != null && _departureLng != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovingTaxiPage(
            departureLat: _departureLat!,
            departureLng: _departureLng!,
          ),
        ),
      );
    } else {
      _showErrorSnackbar('Please select a departure location first.');
    }
  }

  bool _isUserNearDeparture() {
    if (_currentPosition == null ||
        _departureLat == null ||
        _departureLng == null) {
      return false;
    }

    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _departureLat!,
      _departureLng!,
    );

    return distance <= 150;
  }

  void _showRecruitmentCompleteMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content:
              Text('Recruitment is complete. No new participants allowed.')),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
