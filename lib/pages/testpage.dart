import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

void main() {
  runApp(TestOnlyPage());
}

class TestOnlyPage extends StatefulWidget {
  @override
  State<TestOnlyPage> createState() => _TestOnlyPageState();
}

class _TestOnlyPageState extends State<TestOnlyPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  Future<void> _fetchImage() async {
    final String imageUrl =
        'http://167.88.160.87/media/uploads/images/20250305161204-77a2cce7e5b247ee8b6b19050cfcc447.jpg';
    final String authToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzQxMTY0MDAwLCJpYXQiOjE3NDExNjA0MDAsImp0aSI6IjFmMGZlMzU5NGZhNjQ1NGM4NWRlYzc0MTVmYzFlYzYyIiwidXNlcl9pZCI6MTI0fQ.siAu-XdhMtkclInDh9QGPJdeTu-9zcws1N3g6eP55AA';

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _imageBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: Text('Image with Auth Token')),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : _hasError
                  ? Icon(Icons.error, size: 50, color: Colors.red)
                  : Image.memory(_imageBytes!),
        ),
      ),
    );
  }
}
