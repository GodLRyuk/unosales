import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import 'package:unosfa/pages/generalscreens/registration.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:http/http.dart' as http;
import 'package:unosfa/pages/config/config.dart';

class RegistrationOtpPage extends StatefulWidget {
  final String loginWith;
  final String firstName;
  final String lastName;
  final String emailId;
  final String offic;
  final String phoneNumber;
  final dynamic kyc_id_number;
  final dynamic kyc_id_type;
  final File? kycDocument;
  const RegistrationOtpPage(
      {super.key,
      required this.loginWith,
      required this.firstName,
      required this.lastName,
      required this.emailId,
      required this.offic,
      required this.phoneNumber,
      this.kyc_id_type,
      this.kyc_id_number,
      this.kycDocument});

  @override
  State<RegistrationOtpPage> createState() => RegistrationOtpPageState();
}

class RegistrationOtpPageState extends State<RegistrationOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
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

  Future<void> _verifyOtp() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        var url = Uri.parse('${AppConfig.baseUrl}/api/agents/');
        var request = http.MultipartRequest('POST', url);

        // Add text fields
        request.fields['first_name'] = widget.firstName;
        request.fields['last_name'] = widget.lastName;
        request.fields['email'] = widget.emailId;
        request.fields['phone_number'] = widget.phoneNumber;
        request.fields['kyc_id_type'] = widget.kyc_id_type.toString();
        request.fields['kyc_id_number'] = widget.kyc_id_number.toString();
        request.fields['office'] = widget.offic;

        // Add file field
        if (widget.kycDocument != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'kyc_document',
            widget.kycDocument!.path,
          ));
        }
        print(request);
        // Send the request
        var response = await request.send();

        if (response.statusCode == 201) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Success"),
                content: Text(
                    "You have successfully registered. Please wait for approval from UNO Team."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      if (widget.loginWith == "Sal") {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage(
                                    loginWith: 'Sal',
                                  )),
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage(
                                    loginWith: 'Fin',
                                  )),
                        );
                      }
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        } else {
          var responseBody = await response.stream.bytesToString();
          var data = json.decode(responseBody);

          String errorMessage = data['errors'] is List
              ? (data['errors'] as List).join('\n')
              : data['errors'].values.join('\n');
          print(data['errors']);
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(data['message']),
                content: Text(errorMessage),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close the dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Registration(
                                  loginWith: 'Sal',
                                )),
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
          SnackBar(
            content: Text("Error: ${e.toString()}"),
          ),
        );
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
                  Container(
                    //color: Colors.red,
                    width: MediaQuery.of(context).size.width * 0.60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _verifyOtp,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                "Verify OTP",
                                style: WidgetSupport.LoginButtonTextColor(),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _resendOtp,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                "Resend OTP",
                                style: WidgetSupport.LoginButtonTextColor(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.60,
      child: SizedBox(
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
