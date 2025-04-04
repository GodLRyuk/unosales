import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:unosfa/pages/generalscreens/login.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:http/http.dart' as http;
import 'package:unosfa/pages/config/config.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPasswordFormVisible = false;
  bool _isemailFormVisible = true;
  String apiUrl = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Center(
          child: Text("Forgot Password", style: WidgetSupport.titleText()),
        ),
      ),
      body: Column(
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 100, left: 15, right: 15),
                    child: Image(
                      image: AssetImage("images/logo.PNG"),
                      width: MediaQuery.of(context).size.width * 0.70,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.1,
                    ),
                    child: Column(
                      children: [
                        // Email Form
                        if (_isemailFormVisible) ...[
                          _buildEmailForm(),
                        ],
                        if (_isPasswordFormVisible) ...[
                          SizedBox(height: 20),
                          // Password Form
                          _buildPasswordForm(),
                        ],
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Enter your email",
              hintStyle: WidgetSupport.inputLabel(),
              suffixIcon: Icon(FontAwesomeIcons.envelope),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              if (_formKeyEmail.currentState!.validate()) {
                _sendEmailToAPI();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              child: Center(
                child: Text(
                  "Submit",
                  style: WidgetSupport.LoginButtonTextColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _formKeyPassword,
      child: Column(
        children: [
          _buildPasswordTextField(
            _passwordController,
            "New Password",
            obscureText: !_isPasswordVisible,
            onVisibilityToggle: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildPasswordTextField(
            _confirmpasswordController,
            "Confirm Password",
            obscureText: !_isConfirmPasswordVisible,
            isConfirmPassword: true,
            onVisibilityToggle: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          GestureDetector(
            onTap: () {
              if (_formKeyPassword.currentState!.validate()) {
                _submitNewPassword();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.height * 0.01,
              ),
              child: Center(
                child: Text(
                  "Submit",
                  style: WidgetSupport.LoginButtonTextColor(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTextField(
    TextEditingController controller,
    String hintText, {
    bool obscureText = false,
    bool isConfirmPassword = false,
    required VoidCallback onVisibilityToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      enableInteractiveSelection: false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
            color: Colors.purple,
            size: 20,
          ),
          onPressed: onVisibilityToggle,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Enter $hintText';
        }
        if (isConfirmPassword && value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Future<void> _sendEmailToAPI() async {
    final email = _emailController.text;

    // Construct the API request body
    final Map<String, String> data = {'email': email};

    // Send the POST request to the API
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/users/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _isPasswordFormVisible = true;
          _isemailFormVisible = false;
          apiUrl = data['link'];
        });
      } 
      else {
        // Handle error response
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email. Please try again.')),
        );
      }
    } catch (error) {
      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _submitNewPassword() async {
  final new_password = _passwordController.text;
  final confirm_password = _confirmpasswordController.text;

  try {
    var url = Uri.parse(apiUrl);
    Map<String, String> mappedData = {
      'new_password': new_password,
      'confirm_password': confirm_password
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json"
      },
      body: jsonEncode(mappedData),
    );

    try {
      final data = json.decode(response.body); // Try to decode response JSON

      if (response.statusCode == 200) {
        // Success Popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Success"),
              content: Text(data['detail'] ?? 'Password changed successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => LoginPage(loginWith: 'Sal'),
                      ),
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      } else {
        // Extract error message
        String errorMessage = data.containsKey('non_field_errors')
            ? data['non_field_errors'].join(", ")
            : "Something went wrong. Please try again.";

        // Error Popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Error"),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // JSON Decode Error Popup
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text('Failed to parse response. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  } catch (error) {
    // Network Error Popup
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Network Error"),
          content: Text(error.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }
}

}
