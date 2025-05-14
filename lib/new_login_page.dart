import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // inputFormatters에 필요

class NewLoginPage extends StatefulWidget {
  @override
  _NewLoginPageState createState() => _NewLoginPageState();
}

class _NewLoginPageState extends State<NewLoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _kakaoPayUrlController = TextEditingController();
  final TextEditingController _newIdController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();
  final TextEditingController _confirmPwController = TextEditingController();

  bool _isIdAvailable = true;
  bool _isDataFetched = false;
  bool _isSubmitting = false; // 중복 확인 중 상태를 저장하는 플래그
  String _selectedDepartment = '';
  String _idAvailabilityMessage = '';
  String _nameValidationMessage = '';
  String _studentIdValidationMessage = '';
  String _kakaoPayUrlValidationMessage = '';

  final List<String> _departments = [
    '안양대학교',
    '00대학교',
    '00대학교',
    '00회사',
    '00회사',
    '00회사'
  ];

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
        backgroundColor: Color(0xFFFEF9EB),
      ),
      backgroundColor: Color(0xFFFEF9EB),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black54),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: '소속기관 선택',
                    labelStyle: TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Color(0xFFFEF9EB),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black), // Focus color set to black
                    ),
                  ),
                  dropdownColor: Color(0xFFFEF9EB),
                  value: _selectedDepartment.isNotEmpty ? _selectedDepartment : null,
                  items: _departments.map((String department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(department),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDepartment = newValue!;
                    });
                  },
                ),
              ),
              TextField(
                controller: _idController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: '소속기관 ID',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
              ),
              TextField(
                controller: _pwController,
                cursorColor: Colors.black54,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '소속기관 Password',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _loginToInstitution();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C5B56),
                  foregroundColor: Colors.white,
                ),
                child: Text('확인하기'),
              ),
              TextField(
                controller: _nameController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: '이름',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(4),
                ],
                onChanged: (text) {
                  setState(() {
                    _nameValidationMessage = text.length < 2 ? '이름은 최소 2글자 이상이어야 합니다.' : '';
                  });
                },
              ),
              Text(
                _nameValidationMessage,
                style: TextStyle(color: Colors.red),
              ),
              TextField(
                controller: _studentIdController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: '학번(사번)',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (text) {
                  setState(() {
                    _studentIdValidationMessage = !_validateStudentIdFormat(text)
                        ? '"2015E7333"의 올바른 형식으로 입력해주세요.'
                        : '';
                  });
                },
              ),
              Text(
                _studentIdValidationMessage,
                style: TextStyle(color: Colors.red),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newIdController,
                      cursorColor: Colors.black54,
                      decoration: InputDecoration(
                        labelText: '해당 앱에서 사용할 아이디',
                        labelStyle: TextStyle(color: Colors.black54),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black), // Focus color set to black
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _checkIdAvailability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5B56),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('중복 확인'),
                  ),
                ],
              ),
              Text(
                _idAvailabilityMessage,
                style: TextStyle(color: _isIdAvailable ? Colors.green : Colors.red),
              ),
              TextField(
                controller: _newPwController,
                cursorColor: Colors.black54,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
              ),
              TextField(
                controller: _confirmPwController,
                cursorColor: Colors.black54,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                ),
              ),
              if (_newPwController.text != _confirmPwController.text)
                Text(
                  '비밀번호가 일치하지 않습니다.',
                  style: TextStyle(color: Colors.red),
                ),
              TextField(
                controller: _kakaoPayUrlController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: '카카오페이 URL',
                  labelStyle: TextStyle(color: Colors.black54),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black), // Focus color set to black
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline),
                    color: Colors.black54,
                    onPressed: _showKakaoPayHelpDialog,
                  ),
                ),
                onChanged: (text) {
                  setState(() {
                    _kakaoPayUrlValidationMessage = !_validateKakaoPayUrl(text)
                        ? '"https://qr.kakaopay.com/"의 형태로 제대로 입력해주세요.'
                        : '';
                  });
                },
              ),
              Text(
                _kakaoPayUrlValidationMessage,
                style: TextStyle(color: Colors.red),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDataFetched &&
                        _newPwController.text == _confirmPwController.text &&
                        _nameController.text.length >= 2 &&
                        _validateStudentIdFormat(_studentIdController.text) &&
                        _validateKakaoPayUrl(_kakaoPayUrlController.text)
                    ? () async {
                        await addTaskToServer(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C5B56), // 버튼 배경색 검정색
                  foregroundColor: Colors.white, // 버튼 글씨 색상 흰색
                ),
                child: Text('회원가입 진행하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }


  bool _validateStudentIdFormat(String studentId) {
    final RegExp studentIdRegExp = RegExp(r'^\d{4}[a-zA-Z]\d{4}$');
    return studentIdRegExp.hasMatch(studentId);
  }

  bool _validateKakaoPayUrl(String url) {
    return url.startsWith("https://qr.kakaopay.com/");
  }

  Future<void> _loginToInstitution() async {
    try {
      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/my/user/crawl/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _idController.text,
          'password': _pwController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isDataFetched = true; // 로그인 성공했음을 나타내는 플래그
        });
        _showLoginSuccessDialog();
      } else {
        print('Failed to login: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during login: $e');
    }
  }

  Future<void> _checkIdAvailability() async {
    setState(() {
      _isSubmitting = true; // 중복 확인 중 비활성화
    });
    try {
      final response = await http.get(
        Uri.parse(
            'http://35.238.24.244:8000/my/user/info/${_newIdController.text}/'),
      );

      if (response.statusCode == 404) {
        setState(() {
          _isIdAvailable = true;
          _idAvailabilityMessage = '사용 가능한 아이디입니다.';
        });
      } else if (response.statusCode == 200) {
        setState(() {
          _isIdAvailable = false;
          _idAvailabilityMessage = '아이디가 이미 사용 중입니다.';
        });
      } else {
        throw Exception('Failed to check ID availability');
      }
    } catch (e) {
      print('Error checking ID availability: $e');
      setState(() {
        _isIdAvailable = false;
        _idAvailabilityMessage = '아이디 중복 확인 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isSubmitting = false; // 중복 확인 완료 후 버튼 활성화
      });
    }
  }

  Future<void> addTaskToServer(BuildContext context) async {
    try {
      var userData = {
        'user_id': _newIdController.text,
        'password': _newPwController.text,
        'name': _nameController.text,
        'studentId': _studentIdController.text,
        'kakaopay_deeplink': _kakaoPayUrlController.text,
      };

      final response = await http.post(
        Uri.parse('http://35.238.24.244:8000/my/user/info/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            backgroundColor: Color(0xFFFEF9EB), // 배경색 노란색
            title: Text(
              '회원가입 성공',
              style: TextStyle(color: Colors.black), // 글씨 색상 검은색
            ),
            content: Text(
              '회원가입이 완료되었습니다.',
              style: TextStyle(color: Colors.black), // 글씨 색상 검은색
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF5C5B56), // 버튼 배경색 검은색
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Text(
                  '확인',
                  style: TextStyle(color: Colors.white), // 버튼 글씨 색상 흰색
                ),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('회원가입 실패'),
            content: Text('회원가입 중 문제가 발생했습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Error posting user info: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: Color(0xFFFEF9EB), // 배경색 노란색
          title: Text(
            '회원가입 실패',
            style: TextStyle(color: Colors.black), // 글씨 색상 검은색
          ),
          content: Text(
            '회원가입 중 문제가 발생했습니다.',
            style: TextStyle(color: Colors.black), // 글씨 색상 검은색
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF5C5B56), // 버튼 배경색 검은색
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.white), // 버튼 글씨 색상 흰색
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showLoginSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFEF9EB), // 배경색 노란색
          title: Text(
            '로그인 성공',
            style: TextStyle(color: Colors.black), // 글씨 색상 검은색
          ),
          content: Text(
            '해당 사이트에 로그인 완료했습니다.',
            style: TextStyle(color: Colors.black), // 글씨 색상 검은색
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF5C5B56), // 버튼 배경색 검은색
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.white), // 버튼 글씨 색상 흰색
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showKakaoPayHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFEF9EB), // 배경색 노란색으로 변경
          title: Text(
            '카카오페이 안내',
            style: TextStyle(color: Colors.black54), // 제목 글씨 색상 검은색으로 변경
          ),
          content: Container(
            width: double.maxFinite,
            height: 300, // 적절한 높이 설정
            child: PageView(
              children: [
                Image.asset('assets/kakaopay_guide_image1.png'),
                Image.asset('assets/kakaopay_guide_image2.png'),
                Image.asset('assets/kakaopay_guide_image3.png'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '확인',
                style: TextStyle(color: Colors.black), // 버튼 글씨 색상 검은색으로 변경
              ),
            ),
          ],
        );
      },
    );
  }
}
