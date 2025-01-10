import 'dart:io';

import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class RegistrationOld extends StatefulWidget {
  const RegistrationOld({super.key});

  @override
  State<RegistrationOld> createState() => _RegistrationOldState();
}

class _RegistrationOldState extends State<RegistrationOld> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _streetName = TextEditingController();
  final _barangay = TextEditingController();
  final _municipality = TextEditingController();
  final _province = TextEditingController();
  final _postal_code = TextEditingController();
  final _emailId = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _dob = TextEditingController();
  final _gIdNoController = TextEditingController();
  final _agencyName = TextEditingController();
  final _imageController = TextEditingController();
  final _nbiController = TextEditingController();
  bool _isChecked = false;

  String? _selectedGId;
  final Map<String, String> _gIdOptions = {
    'passport': 'Passport',
  'national_id': 'Philippine National ID (PhilSys ID)',
  'drivers_license': 'Driver\'s License',
  'barangay_id': 'Barangay ID',
  'voter_id': 'Voter\'s ID',
  'school_id': 'School ID',
  'senior_citizen_id': 'Senior Citizen ID',
  'pwd_id': 'Persons with Disability (PWD) ID',
  'postal_id': 'Postal ID',
  'government_id': 'Other Government Issued ID'
  };

  String _getIdHintText() {
    switch (_selectedGId) {
      case 'Passport':
        return 'Enter your Passport Number';
      case 'Philippine National ID (PhilSys ID)':
        return 'Enter your PhilSys ID';
      case 'Driver\'s License':
        return 'Enter your Driver’s License Number';
      case 'Barangay ID':
        return 'Enter your Barangay ID';
      case 'Voter\'s ID':
        return 'Enter your Voter\'s ID';
      case 'School ID':
        return 'Enter your School ID';
      case 'Senior Citizen ID':
        return 'Enter your Senior Citizen ID';
      case 'Persons with Disability (PWD) ID':
        return 'Enter your (PWD) ID';
      case 'Postal ID':
        return 'Enter your Postal ID';
      case 'Other Government Issued ID':
        return 'Enter your Other Government Issued ID';
      default:
        return 'Enter ID Number';
    }
  }

  // final List<String> _nbiOptions = ['Yes', 'No'];
  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EntryPage(),
          ),
        );
        return false; // Prevents default pop behavior
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Detect swipe right gesture to go back
          if (details.primaryDelta! > 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EntryPage(),
              ),
            );
          }
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("images/AppBg2.PNG"), fit: BoxFit.fill),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
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
                          horizontal: 30, vertical: 0),
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
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _lastName,
                              "Last Name",
                              'Please Enter Your Last Name',
                              'lname',
                              icon: FontAwesomeIcons.solidCircleUser,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _streetName,
                              "Street Name",
                              'Please Enter Street Name',
                              'stname',
                              icon: FontAwesomeIcons.signsPost,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _barangay,
                              "Barangay",
                              'Please Enter Barangay ',
                              'barangay',
                              icon: FontAwesomeIcons.locationDot,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _municipality,
                              "Municipality City",
                              'Please Enter Municipality',
                              'munici',
                              icon: FontAwesomeIcons.city,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            _buildTextField(
                              _province,
                              "Province",
                              'Please Enter Province',
                              'province',
                              icon: FontAwesomeIcons.city,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            _buildTextField(
                              _postal_code,
                              "Postal Code",
                              'Please Enter Postal Code',
                              'pcode',
                              icon: FontAwesomeIcons.city,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            _buildTextField(
                              _emailId,
                              "Email Id",
                              'Please Enter Your Email',
                              'email',
                              isEmail: true,
                              icon: FontAwesomeIcons.envelope,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _phoneNumber,
                              "Phone Number",
                              'Please Enter Your Phone Number',
                              'phone',
                              isPhoneNumber: true,
                              icon: FontAwesomeIcons.phoneVolume,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextFieldcallender(
                              _dob,
                              "DOB",
                              icon: FontAwesomeIcons.calendarDay,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                            _buildDropdownField(),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _gIdNoController,
                              _getIdHintText(),
                              '',
                              '',
                              icon: FontAwesomeIcons.idCard,
                              obscureText: false,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildTextField(
                              _agencyName,
                              "Agency Name",
                              'Please Enter Agency Name',
                              'agency',
                              icon: FontAwesomeIcons.buildingUser,
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildFileUploadField(_nbiController,"Select NIB Clearance File"),
                             SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildImageUploadField(
                                _imageController, "Select Image"),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _isChecked,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      _isChecked = newValue ?? false;
                                    });
                                  },
                                ),
                                Flexible(
                                  child: Text(
                                    "I confirm that all files and details provided are accurate and complete."
                                    "I accept responsibility for any discrepancies or issues arising from incorrect "
                                    "or incomplete information.",
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                    style: WidgetSupport.smallText(),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFac00d0),
                                    Color(0xFFac00d0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        registerUser();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        vertical:
                                            MediaQuery.of(context).size.height *
                                                0.01,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: Text(
                                      "Register",
                                      style: WidgetSupport.LoginButtonTextColor(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber ? TextInputType.phone : TextInputType.text,
      inputFormatters: isPhoneNumber
          ? <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly, // Allow only digits
            ]
          : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage; // Default validation message for empty fields
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email';
        }
        if (isPhoneNumber && !RegExp(r'^\d+$').hasMatch(value)) {
          return 'Please enter a valid phone number'; // Check if it contains only digits
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
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldcallender(
    TextEditingController controller,
    String hintText, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1000),
          lastDate: DateTime.now(),
        );
        if (pickDate != null) {
          controller.text = "${pickDate.toLocal()}".split(' ')[0];
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your date of birth';
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
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // String? _selectedNbiValue;
  // Widget _buildDropdownNbiField() {
  //   return DropdownButtonFormField<String>(
  //     decoration: InputDecoration(
  //       hintText: 'NBI Clearance',
  //       hintStyle: WidgetSupport.inputLabel(),
  //     ),
  //     value: _selectedNbiValue, // Add this variable to track the NBI selection
  //     items: _nbiOptions.map((String option) {
  //       return DropdownMenuItem(
  //         value: option,
  //         child: Text(option),
  //       );
  //     }).toList(),
  //     onChanged: (String? newValue) {
  //       setState(() {
  //         _selectedNbiValue = newValue; // Track selected value
  //       });
  //     },
  //     validator: (value) {
  //       if (value == null) {
  //         return 'Please select NBI Clearance status'; // Validation message
  //       }
  //       return null;
  //     },
  //   );
  // }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: "Select a valid ID",
        hintStyle: WidgetSupport.inputLabel(),
      ),
      value: _selectedGId,
      items: _gIdOptions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedGId = newValue;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select an ID';
        }
        return null;
      },
    );
  }

  File? _image;

  Widget _buildImageUploadField(
      TextEditingController controller, String hintText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: () async {
            final ImagePicker picker = ImagePicker();
            final XFile? image =
                await picker.pickImage(source: ImageSource.gallery);
            if (image != null) {
              setState(() {
                _image = File(image.path); // Save the selected image
                controller.text = image
                    .path; // Update the controller with the selected image path
              });
            }
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please upload an image'; // Validation message
        }
        return null;
      },
    );
  }

  File? _file;

  Widget _buildFileUploadField(
      TextEditingController controller, String hintText) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        suffixIcon: IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles();

            if (result != null) {
              setState(() {
                _file =
                    File(result.files.single.path!); // Save the selected file
                controller.text = result.files.single.name; // Display file name
              });
            }
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please upload a file'; // Validation message
        }
        return null;
      },
    );
  }

  Future<void> registerUser() async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      // Check if the checkbox is checked
      if (!_isChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please confirm that all details are accurate."),
          ),
        );
        return; // Exit the function if the checkbox is not checked
      }

      final url = Uri.parse('http://167.88.160.87:8000/api/agent/');
      var request = http.MultipartRequest('POST', url);

      // Add the text fields
      request.fields['first_name'] = _firstName.text;
      request.fields['last_name'] = _lastName.text;
      request.fields['email'] = _emailId.text;
      request.fields['street'] = _streetName.text;
      request.fields['barangay'] = _barangay.text;
      request.fields['municipality_city'] = _municipality.text;
      request.fields['province'] =_province.text;
      request.fields['postal_code'] = _postal_code.text;
      request.fields['phone_number'] = _phoneNumber.text;
      request.fields['date_of_birth'] = _dob.text;
      request.fields['government_id_type'] = _selectedGId!;
      request.fields['government_id_number'] = _gIdNoController.text;
      request.fields['agency_name'] = _agencyName.text;
      request.fields['declaration'] = _isChecked.toString(); 

      // If an image is selected, add it to the request
      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'nbi_clearance',
          _image!.path,
        ));
      }
      if (_file != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _file!.path,
        ));
      }
 // Print the fields and files for debugging
    print("Fields: ${request.fields}");
    print("Files:");
    for (var file in request.files) {
      print(" - Field: ${file.field}, Filename: ${file.filename}");
    }
      // Send the request
      final response = await request.send();

      // Handle the response
      if (response.statusCode == 201) {
        showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Success"),
            content: const Text("User registered successfully!"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EntryPage(),
                    ),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to register user"),
          ),
        );
      }
    }
  }
}
