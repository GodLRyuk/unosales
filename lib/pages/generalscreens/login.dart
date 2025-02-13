import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsadashboard.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/generalscreens/forcepasswordchange.dart';
import 'package:unosfa/pages/generalscreens/forgotpassword.dart';
import 'package:unosfa/pages/otpscreens/login_otp.dart';
import 'package:unosfa/pages/FRModule/salesdashboard.dart';
import '../../widgetSupport/widgetstyle.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  final String loginWith;
  const LoginPage({super.key, required this.loginWith});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      if (widget.loginWith == "FSA") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Fsadashboard()),
        );
      } else if (widget.loginWith == "FR") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Salesdashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EntryPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 150, left: 15, right: 15),
                        child: Image(
                          image: AssetImage("images/logo.PNG"),
                          width: MediaQuery.of(context).size.width * 0.70,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Column(
                        children: [
                          Text(
                            "WELCOME TO THE",
                            style: WidgetSupport.entrywelcome1(),
                          ),
                          Text(
                            "WORLD OF",
                            style: WidgetSupport.entrywelcome1(),
                          ),
                          Text(
                            "ELEVATED BANKING",
                            style: WidgetSupport.entrywelcome2(),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.1,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                _usernameController,
                                "Agent Id",
                                '',
                                'username',
                                icon: FontAwesomeIcons.envelope,
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordTextField(
                                _passwordController,
                                "Password",
                                '',
                                'password',
                                icon: FontAwesomeIcons.lock,
                                obscureText: !_isPasswordVisible,
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.00,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_formKey.currentState!.validate()) {
                                          userlogin();
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "LOGIN",
                                            style: WidgetSupport
                                                .LoginButtonTextColor(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ForgotPassword(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.01,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "FORGOT PASSWORD?",
                                            style: WidgetSupport
                                                .LoginButtonTextColor(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 20,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? FontAwesomeIcons.eyeSlash
                  : FontAwesomeIcons.eye,
              color: Colors.purple,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$hintText is required';
        }
        return null;
      },
    );
  }

  Future<void> userlogin() async {
    setState(() {
      _isLoading = true;
    });

    if (_formKey.currentState!.validate()) {
      var url = Uri.parse('http://167.88.160.87/api/users/login/');
      Map mapeddata = {
        'username': _usernameController.text,
        'password': _passwordController.text,
      };
      http.Response response = await http.post(url, body: mapeddata);
      jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        if (widget.loginWith == data['roles'][0]) {
          if (data['access'] != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => LoginOtp(
                      _usernameController.text, _passwordController.text)),
            );
          }
        }
        else{
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Info"),
                content: Text('Invalid credentials.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EntryPage(),
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
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
        });
        final data = json.decode(response.body);
        if (data.containsKey('force_password_change') &&
            data['force_password_change'] != false) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', data['access']);
          await prefs.setString('refreshToken', data['refresh']);
          // Case 1: force_password_change exists and is not false
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Info"),
                content: Text(data['detail'] ?? 'Action required.'),
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
        } else if (data['detail'] == "Invalid credentials.") {
          // Case 2: force_password_change is not present and detail says Invalid credentials
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Info"),
                content: Text("Invalid username or password."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        } else {
          // Handle any other cases if needed
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Info"),
                content:
                    Text(data['detail'] ?? "An unexpected error occurred."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Info"),
              content: Text("Invalid username or password."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields."),
        ),
      );
    }
  }
}
