import 'package:flutter/material.dart';
import 'dart:async';
import 'main.dart'; // LoginPage 클래스를 불러옴

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool taxiVisible = true;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: Duration(seconds: 3), // 택시가 3초 동안 지나감
      vsync: this,
    );

    _controller.forward(); // 애니메이션 시작

    // 애니메이션이 끝난 후 택시 이미지 숨김
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          taxiVisible = false;
        });
        Timer(Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => LoginPage()), // 스플래시 후 LoginPage로 이동
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery.of(context).size를 build 메서드 내에서 사용하여 오류 방지
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFFEF9EB), // 사용자가 선택한 배경색
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              'assets/goat_logo_splash.png', // 스플래시 로고 이미지
              width: 200,
              height: 200,
            ),
          ),
          taxiVisible // 택시가 보이는 동안에만 움직임
              ? AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Positioned(
                      left: (1 - _controller.value) * screenWidth -
                          100, // 애니메이션 방향을 오른쪽에서 왼쪽으로 설정
                      top: MediaQuery.of(context).size.height / 2 -
                          50, // 화면 중앙 수직 위치
                      child: Image.asset(
                        'assets/taxi_splash.png', // 택시 이미지
                        width: 100,
                        height: 100,
                      ),
                    );
                  },
                )
              : Container(), // 택시 이미지 숨김
        ],
      ),
    );
  }
}
