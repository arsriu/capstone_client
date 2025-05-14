import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'main.dart'; // 로그인 페이지로 돌아가기 위해 필요

class MyPage extends StatefulWidget {
  final String userId;
  final List<int> userRatings; // 사용자가 받은 점수들 리스트

  MyPage({
    required this.userId,
    required this.userRatings, // userRatings 초기화 추가
  });

  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with AutomaticKeepAliveClientMixin {
  String? userName; // 서버에서 가져온 사용자 이름
  double? averageRating;

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // 사용자 이름 가져오기
    _fetchAverageRating(); // 평균 점수 가져오기
  }

  // 서버에서 사용자 이름 가져오기
  Future<void> _fetchUserName() async {
    final url = 'http://35.238.24.244:8000/my/user/info/${widget.userId}/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedResponse);
        setState(() {
          userName = data['user_name']; // 서버에서 가져온 사용자 이름 저장
        });
      } else {
        print('Failed to load user name: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  // 서버에서 평균 점수 가져오기
  Future<void> _fetchAverageRating() async {
    final url = 'http://35.238.24.244:8000/reviews/average_rating/${widget.userId}/';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          averageRating = data['average_rating'];
        });
      } else {
        print('Failed to load average rating: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching average rating: $e');
    }
  }

  // 모든 채팅방에서 나가기
  Future<void> _leaveAllChatRooms() async {
    final url = 'http://35.238.24.244:8000/chat/leave_all/${widget.userId}/';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Successfully left all chat rooms');
      } else {
        print('Failed to leave chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error leaving chat rooms: $e');
    }
  }

  // 로그아웃 처리
  Future<void> _logout(BuildContext context) async {
    await _leaveAllChatRooms(); // 모든 채팅방에서 나가기
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    ); // 로그인 페이지로 이동
  }

  // 외부 문의 양식 열기
  Future<void> _launchInquiryForm() async {
    final url = Uri.parse('https://forms.gle/hd7YPLSWZ2qnk2qf6');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  bool get wantKeepAlive => true; // 상태 유지 활성화

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin을 적용하기 위해 필요
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9EB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                'assets/goat_logo_home_page.png',
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                '마이페이지',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'CrimsonText',
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.person,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                userName ?? '이름 불러오는 중...', // 사용자 이름 출력
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'CrimsonText',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '@${widget.userId}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'CrimsonText',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '내 평균 점수',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'CrimsonText',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                averageRating != null
                    ? averageRating!.toStringAsFixed(2)
                    : '불러오는 중...',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'CrimsonText',
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchInquiryForm,
                        icon: const Icon(Icons.email, color: Colors.white),
                        label: const Text(
                          '문의하기',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 86, 86, 92),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _logout(context), // 로그아웃 호출
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          '로그아웃',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C5B56),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
