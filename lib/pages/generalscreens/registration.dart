import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unosfa/pages/FRModule/createnewlead.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/pages/otpscreens/registration_otp.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';

class Registration extends StatefulWidget {
  final String loginWith;
  const Registration({super.key, required this.loginWith});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _emailId = TextEditingController();
  final _externalId = TextEditingController();
  final _office = TextEditingController();
  final _phoneNumber = TextEditingController();
  bool _isLoading = false;
  bool _selectedKycId = false;
  final _imageController = TextEditingController();

  String? _selectedGId;
  final Map<String, String> _gIdOptions = {
    'passport': 'Philippines Passport',
    'national_id': 'Philippine National ID (PhilSys ID)',
    'drivers_license': 'Driver\'s License',
    'umid': 'Unified Multi-Purpose ID (UMID)',
    'sss_id': 'Social Security System (SSS) ID',
    'prc_id': 'Professional Regulation Commission (PRC) ID'
  };

  String _getIdHintText() {
    switch (_selectedGId) {
      case 'passport':
        return 'Enter your Philippines Passport Number';
      case 'national_id':
        return 'Enter your PhilSys ID';
      case 'drivers_license':
        return 'Enter your Driver’s License Number';
      case 'umid':
        return 'Enter your Unified Multi-Purpose ID';
      case 'sss_id':
        return 'Enter your Social Security System (SSS) ID';
      case 'prc_id':
        return 'Enter your Professional Regulation Commission (PRC) ID';
      default:
        return 'Enter ID Number';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const EntryPage(),
          ),
        );
        return false;
      },
      child: GestureDetector(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("images/AppBg2.PNG"), fit: BoxFit.fill),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 50),
                      child: Image(
                        image: const AssetImage(
                          "images/logo.PNG",
                        ),
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  _firstName,
                                  "First Name",
                                  'Please Enter Your Name',
                                  'name',
                                  icon: FontAwesomeIcons.solidCircleUser,
                                  isAlphabetic: true,
                                  allowSpaces: false,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildTextField(
                                  _lastName,
                                  "Last Name",
                                  'Please Enter Your Last Name',
                                  'lname',
                                  icon: FontAwesomeIcons.solidCircleUser,
                                  isAlphabetic: true,
                                  allowSpaces: false,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.03,
                                ),
                                _buildTextField(
                                  _emailId,
                                  "Email Id",
                                  'Please Enter Your Email',
                                  'email',
                                  isEmail: true,
                                  icon: FontAwesomeIcons.envelope,
                                  allowSpaces: false,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildDropdownField(),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildKydIdTextField(
                                  _externalId,
                                  _getIdHintText(),
                                  'Please Enter External ID',
                                  '',
                                  icon: FontAwesomeIcons.idCard,
                                  isRequired: false,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildImageUploadField(
                                    _imageController, "Select Image"),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildTextField(
                                  _office,
                                  "Company Name",
                                  'Please Enter Company Name',
                                  'office',
                                  icon: FontAwesomeIcons.locationDot,
                                  allowSpaces: true,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.04,
                                ),
                                _buildTextField(
                                  _phoneNumber,
                                  "(Please put country code e.g. 63XXXXXXXXXX)",
                                  'Please Enter Your Phone Number',
                                  'phone',
                                  isPhoneNumber: true,
                                  icon: FontAwesomeIcons.phoneVolume,
                                ),
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.02,
                                ),
                                Container(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            registerUser();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.00 // For phones in portrait
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03) // For tablets in portrait
                                                : (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.03 // For phones in landscape
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02), // For tablets in landscape
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: Text(
                                          "REGISTER",
                                          style: WidgetSupport
                                              .LoginButtonTextColor(),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      EntryPage()));
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: MediaQuery.of(context)
                                                        .orientation ==
                                                    Orientation.portrait
                                                ? (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.00 // For phones in portrait
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02) // For tablets in portrait
                                                : (MediaQuery.of(context)
                                                            .size
                                                            .width <
                                                        600
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02 // For phones in landscape
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.02), // For tablets in landscape
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                          ),
                                        ),
                                        child: Text(
                                          "BACK",
                                          style: WidgetSupport
                                              .LoginButtonTextColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
        ),
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
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false, // Add a parameter to validate alphabetic input
    bool allowSpaces = false, // Add a parameter to allow spaces
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : TextInputType.text,
      inputFormatters: [
        if (isPhoneNumber) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12), // Limit to 12 digits
        ],
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
            allowSpaces
                ? RegExp(r'^[a-zA-Z\s]+$') // Allow alphabets and spaces
                : RegExp(r'^[a-zA-Z]+$'), // Allow alphabets only (no spaces)
          ),
        if (!isPhoneNumber && !isAlphabetic)
          FilteringTextInputFormatter.deny(
            allowSpaces
                ? RegExp(r'^\s+$') // Deny consecutive spaces only
                : RegExp(r'\s'), // Deny spaces globally
          ),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage; // Default validation message for empty fields
        }

        if (isAlphabetic) {
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
            return allowSpaces
                ? 'Only alphabets and spaces are allowed'
                : 'Only alphabets are allowed, no spaces';
          }
        }

        if (isEmail) {
          // Basic email validation regex
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(value)) {
            if (!value.contains('@')) {
              return 'Email must contain "@"';
            }
            if (!value.contains('.')) {
              return 'Email must contain a domain (e.g., .com)';
            }
            return 'Please enter a valid email address';
          }
        }

        if (isPhoneNumber) {
          if (value.length != 12) {
            return 'Phone number must be 12 digits';
          }
          if (!value.startsWith('63')) {
            return 'Phone number must start with "63"';
          }
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Phone number must contain only digits';
          }
        }

        return null; // Return null if all validations pass
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildKydIdTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isEmail = false,
    bool isPhoneNumber = false,
    bool isAlphabetic = false,
    bool isNumeric = false,
    bool isZipNumber = false,
    bool isRequired = true, // Add a flag to make the field optional
    bool allowSpaces = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric || isZipNumber
                  ? TextInputType.number
                  : TextInputType.text,
      inputFormatters: [
        if (isNumeric) NumericCommaInputFormatter(),
        if (isZipNumber) FilteringTextInputFormatter.digitsOnly,
        if (isPhoneNumber)
          LengthLimitingTextInputFormatter(12), // Limit to 12 digits
        if (isAlphabetic)
          FilteringTextInputFormatter.allow(
            allowSpaces
                ? RegExp(r'^[a-zA-Z\s]+$') // Allow alphabets and spaces
                : RegExp(r'^[a-zA-Z]+$'), // Allow alphabets only (no spaces)
          ),
      ],
      validator: (_selectedKycId) {
        if (_selectedKycId == "" && _selectedGId != null) {
          return 'Please Enter Id'; // Validation message if KYC ID is selected but no image uploaded
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: WidgetSupport.inputLabel(),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(0),
          child: Icon(
            icon,
            color: Colors.purple,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _gIdOptions.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select a KYC ID",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedGId != null ? _gIdOptions[_selectedGId] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedGId = _gIdOptions.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
          _selectedKycId == true;
        });
      },
      dropdownBuilder: (BuildContext context, String? _selectedGId) {
        return Text(
          _selectedGId ?? "Select KYC ID",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  File? _image;

  Widget _buildImageUploadField(
      TextEditingController controller, String hintText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            hintText: hintText,
            suffixIcon: IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: () async {
                // Show dialog to choose between camera or gallery
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Select Image Source"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.camera); // Open camera
                            if (image != null) {
                              setState(() {
                                _image =
                                    File(image.path); // Save the selected image
                                controller.text = image
                                    .path; // Update the controller with the image path
                              });
                            }
                            Navigator.of(context).pop(); // Close dialog
                          },
                          child: const Text("Camera"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery); // Open gallery
                            if (image != null) {
                              setState(() {
                                _image =
                                    File(image.path); // Save the selected image
                                controller.text = image
                                    .path; // Update the controller with the image path
                              });
                            }
                            Navigator.of(context).pop(); // Close dialog
                          },
                          child: const Text("Gallery"),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.black45,
              ),
            ),
          ),
          validator: (_selectedKycId) {
            if (_selectedGId != null && _image == null) {
              return 'Please upload an image'; // Validation message if KYC ID is selected but no image uploaded
            }
            return null;
          },
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ClipOval(
              child: Image.file(
                _image!,
                height: 110,
                width: 110,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        String firstName = _firstName.text.trim();
        String lastName = _lastName.text.trim();
        String emailId = _emailId.text.trim();
        String office = _office.text.trim();
        String phoneNumber = _phoneNumber.text.trim();
        String selectedGId = _selectedGId!;
        String externalId = _externalId.text.trim();

        // Perform registration logic here, e.g., API call
        await Future.delayed(const Duration(seconds: 2)); // Simulating API call

        // On success, navigate to OTP page and pass the image
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationOtpPage(
              loginWith: 'Sal',
              firstName: firstName,
              lastName: lastName,
              emailId: emailId,
              offic: office,
              phoneNumber: phoneNumber,
              kyc_id_type: selectedGId,
              kyc_id_number: externalId,
              kycDocument: _image, // Pass the image file
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
