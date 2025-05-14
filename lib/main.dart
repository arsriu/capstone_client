import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'new_login_page.dart';
import 'home_page.dart';
import 'splash_screen.dart'; // 스플래시 화면 추가
import 'package:intl/date_symbol_data_local.dart'; // 로케일 데이터 초기화용
import 'package:flutter_localizations/flutter_localizations.dart'; // localization 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // 날짜 형식 초기화 (한국어 등 다국어 지원)
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale('ko', 'KR'), // 기본 로케일을 한국어로 설정
      supportedLocales: [
        const Locale('ko', 'KR'), // 한국어 지원
        const Locale('en', 'US'), // 영어 지원 (필요 시)
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Cupertino 위젯도 로컬라이제이션 적용
      ],
      debugShowCheckedModeBanner: false, // 디버그 모드 배너 제거
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'CrimsonText', // 전체 앱에 기본 글꼴 설정
      ),
      home: SplashScreen(), // 첫 화면을 스플래시 화면으로 설정
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  bool _isPasswordVisible = false; // 비밀번호 표시 여부 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF9EB), // 배경색을 #fef9eb로 설정
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 로고 이미지
              Image.asset(
                'assets/goat_logo.png', // 로고 이미지 경로 설정
                height: 100,
              ),
              SizedBox(height: 20),

              // 인사말 텍스트
              Text(
                "안녕하세요. GoAT입니다.",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'CrimsonText',
                ),
              ),

              SizedBox(height: 8),

              // 안내 텍스트
              Text(
                "회원 서비스 이용을 위해 로그인을 진행해주세요.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'CrimsonText',
                ),
              ),

              SizedBox(height: 32),

              // 아이디 입력 필드
              TextField(
                controller: _idController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: "아이디",
                  labelStyle: TextStyle(fontFamily: 'CrimsonText', color: Colors.black54),
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54), // Set the focused color to black
                  ), // 밑줄 스타일로 변경
                ),
              ),

              SizedBox(height: 16),

              // 비밀번호 입력 필드
              TextField(
                controller: _pwController,
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  labelText: "비밀번호",
                  labelStyle: TextStyle(fontFamily: 'CrimsonText', color: Colors.black54),
                  border: UnderlineInputBorder(),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black54), // Set the focused color to black
                  ), // 밑줄 스타일로 변경
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible, // 상태에 따라 비밀번호 표시 여부 변경
              ),

              SizedBox(height: 24),

              // 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  _login(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(136, 0, 0, 0),
                  foregroundColor: Colors.white, // 글씨색을 흰색으로 설정
                  minimumSize: Size(double.infinity, 48), // 버튼 크기 설정
                ),
                child: Text(
                  "로그인",
                  style: TextStyle(fontFamily: 'CrimsonText'),
                ),
              ),

              SizedBox(height: 24),

              // 회원가입 버튼만 남김
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // 회원가입 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewLoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      "회원가입",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'CrimsonText',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login(BuildContext context) async {
    try {
      final response = await http.post(
        Uri.http('35.238.24.244:8000', '/my/login/'),
        body: jsonEncode({
          'user_id': _idController.text,
          'password': _pwController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8로 디코딩
        print('Login successful, userName: ${data['user_name']}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              currentUser: _idController.text,
              userName: data['user_name'], // 서버로부터 받은 사용자 이름 사용
            ),
          ),
        );
      } else {
        print('Failed to login: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.',
              style: TextStyle(fontFamily: 'CrimsonText'),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '로그인 중 오류가 발생했습니다. 다시 시도해주세요.',
            style: TextStyle(fontFamily: 'CrimsonText'),
          ),
        ),
      );
    }
  }
}
