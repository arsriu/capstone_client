import 'package:flutter/material.dart';
import 'quick_match_page.dart';
import 'normal_match_page.dart';
import 'normal_match_chat_room_page.dart';
import 'my_page.dart';

class HomePage extends StatefulWidget {
  final String currentUser;
  final String userName;
  final Map<String, dynamic>? activeChatRoom;
  final List<Map<String, dynamic>> chatMessages;
  final List<int> userRatings;

  HomePage({
    required this.currentUser,
    required this.userName,
    this.activeChatRoom,
    this.chatMessages = const [],
    this.userRatings = const [],
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _activeChatRoom;
  List<Map<String, dynamic>> _chatMessages = [];
  List<int> _userRatings = [];
  String _userName = '';
  late String _userId;

  @override
  void initState() {
    super.initState();
    _activeChatRoom = widget.activeChatRoom;
    _chatMessages = widget.chatMessages;
    _userRatings = widget.userRatings;
    _userName = widget.userName;
    _userId = widget.currentUser;
  }

  void _onNormalMatchChatRoomJoined(Map<String, dynamic> chatRoom) {
    setState(() {
      _activeChatRoom = chatRoom;
      _selectedIndex = 1;
    });
  }

  void _onQuickMatchChatRoomJoined(Map<String, dynamic> chatRoom) {
    setState(() {
      _selectedIndex = 1;
    });
  }

  Future<void> _onChatRoomExit() async {
    setState(() {
      _activeChatRoom = null;
      _chatMessages = [];
      _selectedIndex = 0;
    });
  }

  List<Widget> _pages(
    BuildContext context,
    String currentUser,
    String userName,
    Map<String, dynamic>? activeChatRoom,
    List<Map<String, dynamic>> chatMessages,
    List<int> userRatings,
    Function(Map<String, dynamic>) onNormalMatchChatRoomJoined,
    Function(Map<String, dynamic>) onQuickMatchChatRoomJoined,
    Future<void> Function() onChatRoomExit,
    Function(String) onUpdateUserName,
  ) {
    return <Widget>[
      DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Color(0xFFFEF9EB),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(150.0), // 높이 유지
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Column(
                children: [
                  const SizedBox(height: 50), // 로고 아래로 이동
                  Image.asset(
                    'assets/goat_logo_home_page.png',
                    height: 50, // 로고 크기 유지
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10), // 로고와 TabBar 사이 간격
                  TabBar(
                    labelColor: Colors.black,
                    indicatorColor: Color.fromARGB(136, 0, 0, 0),
                    tabs: [
                      Tab(
                        child: Text(
                          '빠른매칭',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'CrimsonText',
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          '일반매칭',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'CrimsonText',
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            children: [
              QuickMatchPage(
                currentUser: currentUser,
                userName: userName,
                onChatRoomJoined: onQuickMatchChatRoomJoined,
              ),
              NormalMatchPage(
                currentUser: currentUser,
                userName: userName,
                onChatRoomJoined: onNormalMatchChatRoomJoined,
              ),
            ],
          ),
        ),
      ),
      if (activeChatRoom != null)
        NormalMatchChatRoomPage(
          roomId: activeChatRoom['room_id'].toString(),
          currentUser: currentUser,
          userName: userName,
          departure: activeChatRoom['departure'] ?? '',
          destination: activeChatRoom['destination'] ?? '',
          departureTime: activeChatRoom['departure_time'] ?? '',
          kakaopayDeeplink: activeChatRoom['kakaopay_deeplink'] ?? '',
          onExit: _onChatRoomExit,
          initialMessages: _chatMessages,
        )
      else
        const Center(child: Text('채팅중인 방이 없습니다.')),
      MyPage(
        userId: currentUser,       // 수정된 부분: userName 제거
        userRatings: userRatings,  // userRatings는 그대로 전달
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(
      context,
      widget.currentUser,
      _userName,
      _activeChatRoom,
      _chatMessages,
      _userRatings,
      _onNormalMatchChatRoomJoined,
      _onQuickMatchChatRoomJoined,
      _onChatRoomExit,
      (updatedUserName) {
        setState(() {
          _userName = updatedUserName;
        });
      },
    );

    return Scaffold(
      backgroundColor: Color(0xFFFEF9EB),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 92, 91, 86),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈페이지',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '채팅룸',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: const Color.fromARGB(137, 255, 255, 255),
        selectedLabelStyle: const TextStyle(
          fontFamily: 'CrimsonText',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'CrimsonText',
          fontSize: 14,
        ),
        onTap: (index) {
          if (index == 1 && _activeChatRoom == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '활성화된 채팅룸이 없습니다. 먼저 매칭에 참가하세요.',
                  style: TextStyle(
                    fontFamily: 'CrimsonText', // 글씨체 설정
                  ),
                ),
              ),
            );
            return;
          }
          _onItemTapped(index);
        },
      ),
    );
  }
}
