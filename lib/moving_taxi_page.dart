import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MovingTaxiPage extends StatelessWidget {
  final double departureLat;
  final double departureLng;

  MovingTaxiPage({required this.departureLat, required this.departureLng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEF9EB),
        title: const Text('출발지 주변 택시 화면'),
      ),
      body: WebView(
        backgroundColor: Color(0xFFFEF9EB),
        initialUrl:
            'http://35.238.24.244:8000/taxi/moving_taxi/?lat=$departureLat&lng=$departureLng',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
