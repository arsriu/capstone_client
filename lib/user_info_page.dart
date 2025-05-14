import 'package:flutter/material.dart';

class UserInfoPage extends StatelessWidget {
  final String message;

  UserInfoPage({
    required this.message, // Now accepting a message instead of name and studentId
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Text(
                message, // Display the message
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 24.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true); // Pass a confirmation result
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('확인되었습니다!'),
                    ),
                  );
                },
                child: Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
