import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

const String baseUrl = 'http://35.238.24.244:8000';

class QuickMatchReviewPage extends StatefulWidget {
  final String currentUser;
  final String roomId;
  final List<Map<String, dynamic>> finalParticipants;

  QuickMatchReviewPage({
    required this.currentUser,
    required this.roomId,
    required this.finalParticipants,
  });

  @override
  _QuickMatchReviewPageState createState() => _QuickMatchReviewPageState();
}

class _QuickMatchReviewPageState extends State<QuickMatchReviewPage> {
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
    _updateAllRatedStatus();
  }

  void _updateRating(String userId, int rating) {
    if (!mounted) return;
    setState(() {
      _ratings[userId] = rating;
      _updateAllRatedStatus();
    });
  }

  void _updateAllRatedStatus() {
    _allRated = _ratings.values.every((rating) => rating > 0);
  }

  Future<void> _submitRatings() async {
    final ratingsList = _ratings.entries
        .map((entry) => {'user_id': entry.key, 'rating': entry.value})
        .toList();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/quick_submit_ratings/'),
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
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['error'] ?? 'Unknown error';
        print('Failed to submit ratings: ${response.statusCode}, $errorMessage');
        _showSnackbar('Failed to submit ratings: $errorMessage');
      }
    } catch (e) {
      print('Error submitting ratings: $e');
      _showSnackbar('Error submitting ratings. Please check your network and try again.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('참여자 평가'),
        backgroundColor: const Color(0xFF5C5B56),
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      ),
      backgroundColor: const Color(0xFFFEF9EB), // Yellow background
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '이용해주셔서 감사합니다.\n참여했던 인원에 대해 평가해주세요!!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20, // 텍스트 크기 설정
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5C5B56),
              ),
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
                  const SizedBox(height: 16), // 간격 추가
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
              onPressed: _allRated ? _submitRatings : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C5B56), // Button background color
                foregroundColor: Colors.white, // Button text color
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 20, // Increase button text size
                ),
              ),
            ),
          ),
        ],
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
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
