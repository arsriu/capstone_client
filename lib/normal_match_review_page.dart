import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

const String baseUrl = 'http://35.238.24.244:8000';

class NormalMatchReviewPage extends StatefulWidget {
  final String currentUser;
  final String roomId;
  final List<Map<String, dynamic>> finalParticipants;

  NormalMatchReviewPage({
    required this.currentUser,
    required this.roomId,
    required this.finalParticipants,
  });

  @override
  _NormalMatchReviewPageState createState() => _NormalMatchReviewPageState();
}

class _NormalMatchReviewPageState extends State<NormalMatchReviewPage> {
  Map<String, int> _ratings = {};
  bool _allRated = false;

  @override
  void initState() {
    super.initState();
    for (var participant in widget.finalParticipants) {
      if (participant['user_id'] != widget.currentUser) {
        _ratings[participant['user_id']] = 0;
      }
    }
    _allRated = _ratings.values.every((rating) => rating > 0);
  }

  void _updateRating(String userId, int rating) {
    if (!mounted) return;
    setState(() {
      _ratings[userId] = rating;
      _allRated = _ratings.values.every((rating) => rating > 0);
    });
  }

  Future<void> _submitRatings() async {
    final ratingsList = _ratings.entries
        .map((entry) => {'user_id': entry.key, 'rating': entry.value})
        .toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/submit_ratings/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_user_id': widget.currentUser,
          'room_id': widget.roomId,
          'ratings': ratingsList,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              currentUser: widget.currentUser,
              userName: widget.finalParticipants.firstWhere(
                      (p) => p['user_id'] == widget.currentUser,
                      orElse: () => {'user_name': 'Unknown'})['user_name'] ?? 
                  'Unknown',
              activeChatRoom: null,
              chatMessages: [],
              userRatings: [],
            ),
          ),
        );
      } else {
        print('평가 제출 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('평가 제출에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('평가 제출 중 오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('평가 제출에 오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFfdf9ec), // 배경색을 노란색으로 설정
      child: Scaffold(
        backgroundColor: Colors.transparent, // Scaffold 배경을 투명으로 설정
        appBar: AppBar(
          backgroundColor: const Color(0xFF5C5B56), // AppBar 배경을 검정색으로 설정
          title: const Text(
            '참여자 평가',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // AppBar 제목 색을 흰색으로 설정
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '이용해주셔서 감사합니다.\n참여했던 인원에 대해 평가해주세요!!',
                style: TextStyle(
                  fontSize: 20, // 텍스트 크기 설정
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5C5B56),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '이용자를 평가해주세요.',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    const SizedBox(height: 16), // 제목과 참가자 리스트 사이 간격 추가
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: widget.finalParticipants.map((participant) {
                        if (participant['user_id'] == widget.currentUser) {
                          return const SizedBox.shrink(); // 현재 사용자는 숨김
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 사용자 이름 텍스트 크기 증가
                              Text(
                                participant['user_name'] ?? '알 수 없음',
                                style: const TextStyle(
                                  fontSize: 24, // 사용자 이름 텍스트 크기 증가
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 16), // 이름과 별점 사이 간격
                              RatingBar(
                                initialRating: _ratings[participant['user_id']] ?? 0,
                                onRatingChanged: (rating) {
                                  _updateRating(participant['user_id'], rating);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C5B56), // 버튼 배경을 검정색으로 설정
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
                ),
                onPressed: _allRated ? _submitRatings : null,
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white, // 버튼 텍스트를 흰색으로 설정
                    fontSize: 20, // 버튼 텍스트 크기 증가
                  ), 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RatingBar extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;

  RatingBar({
    this.initialRating = 0,
    required this.onRatingChanged,
  });

  @override
  _RatingBarState createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32, // 별 크기 증가
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1;
            });
            widget.onRatingChanged(_rating);
          },
        );
      }),
    );
  }
}
