import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/cupertino.dart';
import 'select_location_page.dart';

class NormalMatchPage extends StatefulWidget {
  final String currentUser;
  final String userName;
  final Function(Map<String, dynamic>) onChatRoomJoined;

  NormalMatchPage({
    required this.currentUser,
    required this.userName,
    required this.onChatRoomJoined,
  });

  @override
  _NormalMatchPageState createState() => _NormalMatchPageState();
}

class _NormalMatchPageState extends State<NormalMatchPage> {
  List<dynamic> chatRooms = [];
  String _selectedDeparture = '';
  String _selectedDestination = '';
  DateTime? selectedDateTime;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;
  bool _showContent = false; // 이미지 표시 여부를 제어하는 변수

  @override
  void initState() {
    super.initState();
    _initializeDateFormatting();
    _fetchChatRooms();

    // Show content (image and text) after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _showContent = true;
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeDateFormatting() async {
    await initializeDateFormatting('ko_KR', null);
  }

  Future<void> _fetchChatRooms() async {
    try {
      final response = await http.get(
        Uri.parse('http://35.238.24.244:8000/chat/get_chat_rooms/'),
      );

      if (response.statusCode == 200) {
        setState(() {
          chatRooms =
              jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방 목록을 불러오는 데 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네트워크 오류가 발생했습니다.')),
      );
    }
  }

  Future<void> _createRoom() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFFFEF9EB),
              title: const Text(
                '방 만들기',
                style: TextStyle(fontFamily: 'CrimsonText'),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLocationRow(
                    title: '출발지',
                    selectedLocation: _selectedDeparture,
                    onTap: () async {
                      final locationData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SelectLocationPage(title: '출발지 선택'),
                        ),
                      );
                      if (locationData != null) {
                        setState(() {
                          _selectedDeparture = "${locationData['title']}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLocationRow(
                    title: '도착지',
                    selectedLocation: _selectedDestination,
                    onTap: () async {
                      final locationData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SelectLocationPage(title: '도착지 선택'),
                        ),
                      );
                      if (locationData != null) {
                        setState(() {
                          _selectedDestination = "${locationData['title']}";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDateTimeRow(setState),
                  Text(
                    selectedDateTime != null
                        ? DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR')
                            .format(selectedDateTime!.toLocal())
                        : '시간을 선택하세요',
                    style: const TextStyle(
                        fontSize: 16, fontFamily: 'CrimsonText'),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C5B56), // 배경색 회색으로 설정
                  ),
                  child: const Text('취소',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'CrimsonText')), // 글씨 색깔 흰색
                ),
                TextButton(
                  onPressed: () => _submitRoomCreation(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF5C5B56), // 배경색 회색으로 설정
                  ),
                  child: const Text('확인',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'CrimsonText')), // 글씨 색깔 흰색
                ),
              ],
            );
          },
        );
      },
    );
  }

  Row _buildLocationRow({
    required String title,
    required String selectedLocation,
    required Function() onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$title: ', style: TextStyle(fontFamily: 'CrimsonText')),
        GestureDetector(
          onTap: onTap,
          child: Text(
            selectedLocation.isEmpty ? '$title 선택' : selectedLocation,
            style: const TextStyle(
              color: Color.fromARGB(255, 54, 53, 53),
              decoration: TextDecoration.underline,
              fontFamily: 'CrimsonText',
            ),
          ),
        ),
      ],
    );
  }
  Row _buildDateTimeRow(StateSetter setState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('출발 예정 시간:', style: TextStyle(fontFamily: 'CrimsonText')),
        ElevatedButton(
          onPressed: () async {
            final pickedDateTime = await showDateTimePicker();
            if (pickedDateTime != null) {
              setState(() {
                selectedDateTime = pickedDateTime;
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C5B56), // 배경색 회색으로 설정
            foregroundColor: Colors.white, // 글씨 색깔을 흰색으로 설정
          ),
          child:
              const Text('시간 선택', style: TextStyle(fontFamily: 'CrimsonText')),
        ),
      ],
    );
  }

  Future<void> _submitRoomCreation() async {
    if (selectedDateTime == null ||
        _selectedDeparture.isEmpty ||
        _selectedDestination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('출발지, 도착지, 시간을 모두 선택하세요.',
                style: TextStyle(fontFamily: 'CrimsonText'))),
      );
      return;
    }

    final utcDepartureTime = selectedDateTime!.toUtc().toIso8601String();

    try {
      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/chat/create_room/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'room_name': '일반방',
          'departure': _selectedDeparture,
          'destination': _selectedDestination,
          'departure_time': utcDepartureTime,
          'participants': [],
          'user_id': widget.currentUser,
          'user_name': widget.userName,
        }),
      );

      if (response.statusCode == 201) {
        Navigator.of(context).pop();
        final roomData =
            jsonDecode(utf8.decode(response.bodyBytes))['room_data'];
        widget.onChatRoomJoined(roomData);
        await _fetchChatRooms();
        _resetInputs();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('방을 생성할 수 없습니다.',
                  style: TextStyle(fontFamily: 'CrimsonText'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('방 생성 중 오류가 발생했습니다.',
                style: TextStyle(fontFamily: 'CrimsonText'))),
      );
    }
  }

  void _resetInputs() {
    setState(() {
      _selectedDeparture = '';
      _selectedDestination = '';
      selectedDateTime = null;
    });
  }

  Future<DateTime?> showDateTimePicker() async {
    DateTime? tempPickedDateTime = DateTime.now();
    await showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: const Color(0xFFfdf9ec),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text('출발 예정 시간 선택',
                  style: TextStyle(fontSize: 18, fontFamily: 'CrimsonText')),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: DateTime.now(),
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDateTime) {
                    tempPickedDateTime = newDateTime;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(tempPickedDateTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF5C5B56), // 버튼 배경색을 검정색으로 설정
                    foregroundColor: Colors.white, // 버튼 글씨 색깔을 흰색으로 설정
                  ),
                  child: const Text('확인',
                      style: TextStyle(fontFamily: 'CrimsonText')),
                ),
              ),
            ],
          ),
        );
      },
    );
    return tempPickedDateTime;
  }
  @override
  Widget build(BuildContext context) {
    // Filter and sort recruiting rooms based on the search term
    List<dynamic> recruitingRooms = chatRooms
        .where((room) => room['recruitment_complete'] == false &&
            (_selectedDeparture.isEmpty ||
                room['departure'].contains(_selectedDeparture)))
        .toList();
    recruitingRooms.sort((a, b) {
      String departureA = a['departure'] ?? '';
      String departureB = b['departure'] ?? '';
      return departureA.compareTo(departureB);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFfdf9ec),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 1),
            TextField(
              focusNode: _searchFocusNode,
              cursorColor: Colors.black54,
              decoration: InputDecoration(
                labelText: _searchFocusNode.hasFocus ? '' : '출발지를 검색해주세요!',
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                labelStyle: const TextStyle(fontFamily: 'CrimsonText'),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 24,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
              onChanged: (text) {
                setState(() {
                  _selectedDeparture = text;
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: recruitingRooms.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_showContent)
                          Image.asset(
                            'assets/no_rooms.png',
                            width: 150,
                            height: 150,
                          ),
                        if (_showContent) const SizedBox(height: 4),
                        if (_showContent)
                          const Text(
                            '방을 생성해주세요..',
                            style: TextStyle(
                              fontSize: 25,
                              fontFamily: 'CrimsonText',
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: recruitingRooms.length,
                      itemBuilder: (context, index) {
                        final room = recruitingRooms[index];
                        final roomName =
                            "${room['departure']} -> ${room['destination']}";
                        final departureTimeString = room['departure_time'] ?? '';
                        DateTime? departureTime;

                        try {
                          departureTime =
                              DateTime.parse(departureTimeString).toLocal();
                        } catch (e) {
                          print('날짜 형식 오류: $e');
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          color: const Color(0xFF5C5B56),
                          child: ListTile(
                            title: const Text(
                              '[모집중]',
                              style: TextStyle(
                                fontFamily: 'CrimsonText',
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(roomName,
                                    style: const TextStyle(
                                      fontFamily: 'CrimsonText',
                                      color: Colors.white,
                                    )),
                                Text(
                                  departureTime != null
                                      ? '출발 시간: ${DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR').format(departureTime)}'
                                      : '출발 시간: 정보 없음',
                                  style: const TextStyle(
                                    fontFamily: 'CrimsonText',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                widget.onChatRoomJoined({
                                  'room_id': room['room_id'],
                                  'departure': room['departure'],
                                  'destination': room['destination'],
                                  'departure_time': room['departure_time'],
                                });
                                await _fetchChatRooms();
                              },
                              child: const Text(
                                '참여하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'CrimsonText',
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createRoom,
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.grey,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
