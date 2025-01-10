import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/fsaModule/fsacompanyleaddashboard.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class FsaCompanyLeadGenerate extends StatefulWidget {
  @override
  _FsaCompanyLeadGenerateState createState() => _FsaCompanyLeadGenerateState();
}

class _FsaCompanyLeadGenerateState extends State<FsaCompanyLeadGenerate> {
  final _formKey = GlobalKey<FormState>();
  final company_name = TextEditingController();
  final company_type = TextEditingController();
  final number_of_employees = TextEditingController();
  final operating_since = TextEditingController();
  final address_line_1 = TextEditingController();
  final address_line_2 = TextEditingController();
  final zip_code = TextEditingController();
  final city = TextEditingController();
  final contact_person_first_name = TextEditingController();
  final contact_person_last_name = TextEditingController();
  final contact_person_mobile_no = TextEditingController();
  final email = TextEditingController();
  String? _selectedCompanyType;
  bool _isLoading = false;
  late Map<String, String> _ComIdOptions;
  late Map<String, String> _city = {}; // Initialize as an empty map
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies

  TextEditingController _searchController = TextEditingController();
// Track if TextField is clicked
  bool _isDropdownVisible = false;

  @override
  void initState() {
    super.initState();
    _ComIdOptions = {};
    _filteredCompanies = [];
    _loadData();
    _loadCityData();
  }

  // Load initial company data
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/company-types/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> companies = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in companies) {
            fetchedData[item['id'].toString()] = item['type_name'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _filteredCompanies = fetchedData.entries
                .map((e) => {'id': e.key, 'type_name': e.value})
                .toList();
          });
        }
      } else if (response.statusCode == 401) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              'http://167.88.160.87/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _loadData();
      } else {
        throw Exception('Failed to load companies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Search for companies based on the query
  Future<void> _searchCompany(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = _ComIdOptions.entries
            .map((e) => {'id': e.key, 'type_name': e.value})
            .toList();
        _isDropdownVisible = true;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'http://167.88.160.87/api/leads/company-types/?search=$query'),
        headers: await _getAuthHeader(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> companies = data['results'];

          setState(() {
            _filteredCompanies = companies
                .map((e) => {
                      'id': e['id'].toString(),
                      'type_name': e['type_name'].toString(),
                    })
                .toList();
          });
        }
      } else if (response.statusCode == 401) {
        String? refresh = prefs.getString('refreshToken');
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              'http://167.88.160.87/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _searchCompany(query);
      } else {
        throw Exception('Failed to search companies');
      }
    } catch (e) {
      print('Search Error: $e');
    }
  }

  Future<Map<String, String>> _getAuthHeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0), // Adjust the height as needed
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0), // Start color of the gradient
                Color(0xFF9a37ae), // End color of the gradient
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            elevation: 0, // Remove shadow
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG', // Path to your image
                  height: 30,
                ),
                SizedBox(width: 10),
              ],
            ),
            centerTitle: true, // Center the title
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: Colors.white), // Leading arrow icon
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FsaCompanyLeadDashBoard(
                              searchQuery: '',
                            ))); // Go back to the previous screen
              },
            ),
          ),
        ),
      ),
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
                        horizontal: 20, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            company_name,
                            "Enter Company Name",
                            'Please Enter Your Company Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isAlphabetic: true,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          Padding(
                            padding: EdgeInsets.all(0.0),
                            child: Column(
                              children: [
                                // TextField for searching companies
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {
                                      _isDropdownVisible = hasFocus;
                                    });
                                  },
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: "Type of Company",
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.search),
                                        onPressed: () {
                                          // Trigger the search when the search icon is pressed
                                          _searchCompany(
                                              _searchController.text);
                                        },
                                      ),
                                    ),
                                    onChanged: (query) {
                                      if (query.isEmpty) {
                                        // Reset to showing all companies if the input is cleared
                                        setState(() {
                                          _filteredCompanies = _ComIdOptions
                                              .entries
                                              .map((e) => {
                                                    'id': e.key,
                                                    'type_name': e.value
                                                  })
                                              .toList();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isDropdownVisible)
                            Stack(
                              children: [
                                Positioned(
                                  child: Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: ListView.builder(
                                        itemCount: _filteredCompanies.length,
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(
                                                _filteredCompanies[index]
                                                    ['type_name']!),
                                            onTap: () {
                                              setState(() {
                                                _searchController.text =
                                                    _filteredCompanies[index]
                                                        ['type_name']!;
                                                _selectedCompanyType =
                                                    _filteredCompanies[index]
                                                        ['id']!;
                                                _isDropdownVisible =
                                                    false; // Close dropdown
                                                print(_selectedCompanyType);
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            number_of_employees,
                            "Nummber of Employes",
                            "Please Enter Number of Employees",
                            "noemp",
                            isEmail: false,
                            isNumeric: true,
                            icon: FontAwesomeIcons.personCircleQuestion,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            operating_since,
                            "Operationg Since ",
                            "Please Enter Operating Since",
                            "noemp",
                            isEmail: false,
                            isNumeric: true,
                            icon: FontAwesomeIcons.solidCalendarCheck,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            address_line_1,
                            "Address line 1",
                            'Please Enter Your Address line 1',
                            'address',
                            isEmail: false,
                            isNumeric: false,
                            icon: FontAwesomeIcons.mapLocation,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            address_line_2,
                            "Address line 2",
                            'Please Enter Your Address line 2',
                            'address',
                            isEmail: false,
                            isNumeric: false,
                            icon: FontAwesomeIcons.mapLocationDot,
                            isRequired: false,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            zip_code,
                            "Zip",
                            'Please Enter Zip Code',
                            'zip',
                            isZipNumber: true,
                            icon: FontAwesomeIcons.mapPin,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildCityDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            contact_person_first_name, // Use the controller here
                            "Contact Person First Name",
                            'Please Enter Contact Person First Name',
                            'cpname',
                            isNumeric: false,
                            icon: FontAwesomeIcons.person,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            contact_person_last_name, // Use the controller here
                            "Contact Person Last  Name",
                            'Please Enter Contact Person Last  Name',
                            'cpname',
                            isNumeric: false,
                            icon: FontAwesomeIcons.person,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            contact_person_mobile_no,
                            "(Please put country code and 10 digit mobile number e.g. 63XXXXXXXXXX)",
                            'Please Enter Your Phone Number',
                            'phone',
                            isPhoneNumber: true,
                            icon: FontAwesomeIcons.phoneVolume,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            email,
                            "Contact Person Email ID",
                            'Please Enter Contact Person Email ID',
                            'mail',
                            isEmail: true,
                            icon: FontAwesomeIcons.mailchimp,
                            isNumeric: false,
                            allowSpaces: false,
                          ),
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      leadSubmit();
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
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: Text(
                                    "SUBMIT",
                                    style: WidgetSupport.LoginButtonTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.30),
                        ],
                      ),
                    ),
                  ),
                ))
              ],
            ),
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

  String? _selectedCity; // To store the selected city

// Map to hold the city value (key) and display text (value)
  Future<void> _loadCityData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/cities'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Decode the response as a List<dynamic>
        List<dynamic> cityList = json.decode(response.body);

        // Create a map from the list of locations
        Map<String, String> fetchedData = {};
        for (var item in cityList) {
          fetchedData[item['id'].toString()] = item['city_name'].toString();
        }

        setState(() {
          _city = fetchedData; // Now _LocationType is a Map<String, String>
        });
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              'http://167.88.160.87/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _loadCityData();
      } else {
        throw Exception('Failed to load location types');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

 Future<void> leadSubmit() async {
  setState(() {
    _isLoading = true;
  });

  // Check if the form is valid
  if (_formKey.currentState!.validate()) {
    // Collect form data
    String company = company_name.text.trim();
    String number_of_employee = number_of_employees.text.trim();
    String operating = operating_since.text.trim();
    String address1 = address_line_1.text.trim();
    String address2 = address_line_2.text.trim();
    String zip = zip_code.text.trim();
    String city = _selectedCity!;
    String contact_p_first_name = contact_person_first_name.text.trim();
    String contact_p_last_name = contact_person_last_name.text.trim();
    String contact_p_mobile_no = contact_person_mobile_no.text.trim();
    String contact_p_email = email.text.trim();
    String company_type = _selectedCompanyType ?? '';

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');

    // Map the collected data to be sent in the request body
    Map<String, dynamic> mappedData = {
      'company_name': company,
      'company_type': company_type,
      'number_of_employees': number_of_employee,
      'operating_since': operating,
      'address_line_1': address1,
      'address_line_2': address2,
      'zip_code': zip,
      'city': city,
      'contact_person_first_name': contact_p_first_name,
      'contact_person_last_name': contact_p_last_name,
      'contact_person_mobile_no': contact_p_mobile_no,
      'email': contact_p_email,
    };

    try {
      var url = Uri.parse('http://167.88.160.87/api/leads/company-leads/');

      http.Response response = await http.post(
        url,
        body: mappedData,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Lead submitted successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NavigationPage(),
                      ),
                    );
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        ).then((value) {
          // Clear fields when dialog is dismissed
          clearAllFields();
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
        });

        Map<String, dynamic> refreshData = {'refresh': refresh};
        final response2 = await http.post(
          Uri.parse('http://167.88.160.87/api/users/token-refresh/'),
          body: refreshData,
        );
        final data = json.decode(response2.body);

        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);

        leadSubmit();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit lead. Error: ${response.body}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Form validation failed"),
      ),
    );
  }

  setState(() {
    _isLoading = false;
  });
}

void clearAllFields() {
  company_name.clear();
  number_of_employees.clear();
  operating_since.clear();
  address_line_1.clear();
  address_line_2.clear();
  zip_code.clear();
  contact_person_first_name.clear();
  contact_person_last_name.clear();
  contact_person_mobile_no.clear();
  email.clear();

  setState(() {
    _selectedCity = null;
    _selectedCompanyType = null;
  });
}

  Widget _buildCityDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _city.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select City",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedCity != null ? _city[_selectedCity] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedCity =
              _city.entries.firstWhere((entry) => entry.value == newValue).key;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select City';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select City",
          style: WidgetSupport.dropDownText(),
        );
      },
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
    bool isAlphabetic = false,
    bool isNumeric = true,
    bool isZipNumber = false,
    bool isRequired = true, // Add a flag to make the field optional
    bool allowSpaces = false, // New flag to allow spaces
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isPhoneNumber
          ? TextInputType.phone
          : isEmail
              ? TextInputType.emailAddress
              : isNumeric
                  ? TextInputType.number
                  : isZipNumber
                      ? TextInputType.number
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
        if (isNumeric)
          FilteringTextInputFormatter.digitsOnly, // Allow digits only
        if (!isPhoneNumber && !isAlphabetic && !isNumeric)
          FilteringTextInputFormatter.deny(
            allowSpaces
                ? RegExp(r'^\s+$') // Deny consecutive spaces only
                : RegExp(r'\s'), // Deny spaces globally
          ),
      ],
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return validationMessage;
        }

        if (isAlphabetic) {
          if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value!)) {
            return allowSpaces
                ? 'Only alphabets and spaces are allowed'
                : 'Only alphabets are allowed';
          }
        }

        if (isPhoneNumber) {
          if (value == null || value.isEmpty) {
            return validationMessage;
          }
          if (value.length != 12) {
            return 'Phone number must be exactly 12 digits';
          }
          if (!RegExp(r'^\d+$').hasMatch(value)) {
            return 'Phone number must contain only digits';
          }
          if (!value.startsWith('63')) {
            return 'Phone number must start with "63"';
          }
        }
        // Email validation
        if (isEmail && value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Please enter a valid email address';
          }
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
}
