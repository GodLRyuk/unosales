import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:unosfa/pages/generalscreens/forcepasswordchange.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';

class Changepasswordotp extends StatefulWidget {
  final String newpassword;
  final String oldpassword;
  final String confirmpassword;
  final  token;


  const Changepasswordotp({
    super.key,
    required this.newpassword,
    required this.oldpassword,
    required this.confirmpassword,
    required this.token,
  });

  @override
  State<Changepasswordotp> createState() => _ChangepasswordotpState();
}

class _ChangepasswordotpState extends State<Changepasswordotp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _start = 120;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        _timer?.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  String get _timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  void _resendOtp() {
    setState(() {
      _start = 120; // Reset the timer
      _otpController.clear(); // Clear the OTP field
    });
    _startTimer(); // Start the timer again
  }

  void _verifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (widget.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Authentication token not found. Please log in again.')),
        );
        return;
      }
       setState(() {
      _isLoading = true;
    });
      try {
        var url = Uri.parse('${AppConfig.baseUrl}api/users/change-password/');
        Map<String, dynamic> mappedData = {
          'old_password': widget.oldpassword,
          'new_password': widget.newpassword,
          'confirm_password': widget.confirmpassword,
        };
        http.Response response = await http.post(
          url,
          body: mappedData,
          headers: {
            'Authorization': 'Bearer ${widget.token}',
          },
        );
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage(loginWith: 'Sal',)),
          );
        } else if (response.statusCode == 400) {
          final data = json.decode(response.body);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String errorMessage;

              if (data['non_field_errors'] is List) {
                // If it's a list, join the messages into a single string
                errorMessage =
                    (data['non_field_errors'] as List<dynamic>).join("\n");
              } else {
                // If it's a string or any other type, just convert it to a string
                errorMessage = data['non_field_errors'].toString();
              }

              return AlertDialog(
                title: Text("Info"),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ForcePasswordChange(),
                        ),
                      );
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      finally {
      setState(() {
        _isLoading = false;
      });
    }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 0, left: 15, right: 15),
                    child: Image(
                      image: AssetImage("images/logo.PNG"),
                      width: MediaQuery.of(context).size.width * 0.70,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.10,
                  ),
                  Text(
                    'Enter OTP sent to your phone',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    _timerText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Form(
                    key: _formKey,
                    child: _buildOtpBox(),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.18,
                            vertical: MediaQuery.of(context).size.height * 0.01,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Verify OTP",
                          style: WidgetSupport.LoginButtonTextColor(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _resendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                MediaQuery.of(context).size.width * 0.04,
                            vertical: MediaQuery.of(context).size.height * 0.00,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          "Resend OTP",
                          style: WidgetSupport.LoginButtonTextColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.transparent,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOtpBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: SizedBox(
        width: 230,
        child: TextFormField(
          controller: _otpController,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: "-   -   -   -",
            hintStyle: TextStyle(color: Colors.grey),
            contentPadding: EdgeInsets.symmetric(vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.purple),
            ),
          ),
          validator: (value) {
            if (value == null || value.length != 4) {
              return 'Please enter a 4-digit OTP';
            }
            return null;
          },
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
    );
  }
}
