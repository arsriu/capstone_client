import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class SelectLocationPage extends StatefulWidget {
  final String title;

  SelectLocationPage({required this.title});

  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  WebViewController? _webViewController;
  Position? _currentPosition;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    // WebView for Android only, because WebView is not supported on Web or macOS by default
    if (!kIsWeb && Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    }

    _getCurrentLocation(); // Fetch the current location
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission and get the current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (_webViewController != null) {
        _sendLocationToWebView();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not get location: $e';
      });
      print('Error: $_errorMessage');
    }
  }

  void _sendLocationToWebView() {
    if (_currentPosition != null && _webViewController != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final jsCode = """
        if (typeof map !== 'undefined') {
          var marker = new google.maps.Marker({
            position: { lat: $lat, lng: $lng },
            map: map,
            title: 'Your Location'
          });
          map.setCenter(marker.getPosition());
        } else {
          console.error('Map is not defined');
        }
      """;
      _webViewController!.runJavascript(jsCode);
    }
  }

  // Inject the meta tag to prevent zooming in on input focus in iOS
  void _injectMetaTag() {
    if (_webViewController != null) {
      _webViewController!.runJavascript("""
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
      """);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFEF9EB), // AppBar 배경색을 노란색으로 설정
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold, // 글씨를 볼드체로 설정
          ),
        ),
      ),
      body: Container(
        color: Color(0xFFFEF9EB), // body 배경색을 노란색으로 설정
        child: SafeArea(
          bottom: false,
          child: _buildWebViewOrError(), // 원래의 내용은 그대로 유지
        ),
      ),
    );
  }

  Widget _buildWebViewOrError() {
    // Check for unsupported platforms (Web or macOS)
    if (kIsWeb || Platform.isMacOS) {
      return Center(
        child: Text(
          'WebView is not supported on this platform.',
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    // For supported platforms like Android and iOS
    return WebView(
      initialUrl: 'http://35.238.24.244:8000/chat/map/',
      javascriptMode: JavascriptMode.unrestricted,
      onWebViewCreated: (WebViewController webViewController) {
        _webViewController = webViewController;
        _injectMetaTag(); // Inject meta tag to prevent zoom on input focus for iOS
        if (_currentPosition != null) {
          _sendLocationToWebView();
        }
      },
      javascriptChannels: <JavascriptChannel>{
        JavascriptChannel(
          name: 'LocationSelected',
          onMessageReceived: (JavascriptMessage message) {
            List<String> locationData = message.message.split(',');

            if (locationData.length >= 3) {
              String title = locationData[0];
              String latitude = locationData[1];
              String longitude = locationData[2];

              Navigator.pop(context, {
                'title': title,
                'latitude': latitude,
                'longitude': longitude,
              });
            } else {
              Navigator.pop(context, {
                'error': 'Invalid location data received.',
              });
            }
          },
        ),
      }.toSet(),
    );
  }
}
