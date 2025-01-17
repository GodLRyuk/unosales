import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/salesModule/loancalculation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';

class LeadGenerate extends StatefulWidget {
  @override
  _LeadGenerateState createState() => _LeadGenerateState();
}

class _LeadGenerateState extends State<LeadGenerate> {
  final _formKey = GlobalKey<FormState>();
  // final _companyName = TextEditingController();
  final _fname = TextEditingController();
  final _mname = TextEditingController();
  final _lname = TextEditingController();
  final _phoneNumber = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _zip = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _area = TextEditingController();
  final _income = TextEditingController();
  final _loanamount = TextEditingController();
  final _businessNameController = TextEditingController();
  final _imageController = TextEditingController();
  final _externalId = TextEditingController();

  bool _isLoading = false;
  late Map<String, String> _ComIdOptions; // Store the fetched companies
  late List<Map<String, String>> _LocationType =
      []; // Initialize as an empty map
  late List<Map<String, String>> _Activity = []; // Initialize as an empty map
  late List<Map<String, String>> _Tenor = []; // Initialize as an empty map
  late List<Map<String, String>> _doc = []; // Initialize as an empty map
  late Map<String, String> _city = {}; // Initialize as an empty map
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies

  TextEditingController _searchController = TextEditingController();
  String? _selectedCompany;
  bool _isFieldFocused = false; // Track if TextField is clicked
  String? _selectedGId;
  bool _selectedKycId = false;

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
  void initState() {
    super.initState();
    _ComIdOptions = {};
    _filteredCompanies = [];
    _LocationType = [];
    _Activity = [];
    _Tenor = [];
    _doc = [];
    _loadData();
    _loadLocationData();
    _loadActivityData();
    _loadTenorData();
    _loadDocData();
    _loadCityData();
  }

  // Load initial company data
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/companies/?page_size=100'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> companies = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in companies) {
            fetchedData[item['id'].toString()] =
                item['company_name'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _filteredCompanies = fetchedData.entries
                .map((e) => {'id': e.key, 'company_name': e.value})
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
            .map((e) => {'id': e.key, 'company_name': e.value})
            .toList();
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/companies/?search=$query'),
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
                      'company_name': e['company_name'].toString(),
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

  String? _selectedCustType;
  final Map<String, String> _CustomerType = {
    'salaried': 'Salaried ',
    'self_employed': 'Self-employed',
  };
  String? _selectedLocationType;

  Future<void> _loadLocationData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/location-types'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> location = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in location) {
            fetchedData[item['id'].toString()] = item['description'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _LocationType = fetchedData.entries
                .map((e) => {'id': e.key, 'description': e.value})
                .toList();
          });
        }
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
        _getAuthHeader();
      } else {
        throw Exception('Failed to load location types');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? _selectedActivity;
  Future<void> _loadActivityData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/activities'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> location = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in location) {
            fetchedData[item['id'].toString()] = item['description'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _Activity = fetchedData.entries
                .map((e) => {'id': e.key, 'description': e.value})
                .toList();
          });
        }
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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _loadActivityData();
      } else {
        throw Exception('Failed to load location types');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? _selectedTenor;
  Future<void> _loadTenorData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/tenors'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> tenor = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in tenor) {
            fetchedData[item['id'].toString()] = item['description'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _Tenor = fetchedData.entries
                .map((e) => {'id': e.key, 'description': e.value})
                .toList();
          });
        }
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
        _loadTenorData();
      } else {
        throw Exception('Failed to load location types');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String? _selectedPricing;
  final Map<String, String> _pricing = {'1.99': '1.99%'};
  String? _selectedDocument;
  Future<void> _loadDocData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('http://167.88.160.87/api/leads/document-types'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> docs = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in docs) {
            fetchedData[item['id'].toString()] = item['description'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _doc = fetchedData.entries
                .map((e) => {'id': e.key, 'description': e.value})
                .toList();
          });
        }
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
        _loadDocData();
      } else {
        throw Exception('Failed to load location types');
      }
    } catch (e) {
      print('Error: $e');
    }
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
                        builder: (context) =>
                            NavigationPage())); // Go back to the previous screen
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            _fname,
                            "Customer First Name",
                            'Please Enter Your Customer First Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isAlphabetic: true,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _mname,
                            "Customer Middle Name",
                            'Please Enter Your Customer Middle Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isBlankAlphabetic: true,
                            isRequired: false,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _lname,
                            "Customer Last Name",
                            'Please Enter Your Customer Last Name',
                            'name',
                            isNumeric: false,
                            icon: FontAwesomeIcons.solidCircleUser,
                            isAlphabetic: true,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _email,
                            "Email Address",
                            'Please Enter Your Email',
                            'email',
                            isNumeric: false,
                            icon: FontAwesomeIcons.mailchimp,
                            isRequired: true,
                            isEmail: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildTextField(
                            _phoneNumber,
                            "(Please put country code e.g. 63XXXXXXXXXX)",
                            'Please Enter Your Phone Number',
                            'phone',
                            isPhoneNumber: true,
                            icon: FontAwesomeIcons.phoneVolume,
                            allowSpaces: false,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _buildCtypeDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          if (_selectedCustType == 'salaried') ...[
                            Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Column(
                                children: [
                                  // TextField for searching companies
                                  Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _isFieldFocused =
                                            hasFocus; // Track if the TextField is focused
                                        // _businessNameController.clear();
                                      });
                                    },
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: "Company",
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
                                                      'company_name': e.value
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
                            if (_isFieldFocused)
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
                                                      ['company_name']!),
                                              onTap: () {
                                                // Set the selected company
                                                setState(() {
                                                  _selectedCompany =
                                                      _filteredCompanies[index]
                                                          ['id'];
                                                  _searchController.text =
                                                      _filteredCompanies[index]
                                                          ['company_name']!;
                                                  _isFieldFocused =
                                                      false; // Dismiss the suggestions after selection
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
                          ],
                          if (_selectedCustType == 'self_employed') ...[
                            TextField(
                              controller: _businessNameController,
                              decoration: InputDecoration(
                                hintText: "Business Name",
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.03,
                            ),
                          ],
                          _buildTextField(
                            _address1,
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
                            _address2,
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
                            _zip,
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
                            _location, // Use the controller here
                            "Location",
                            'Please Enter Location',
                            'location',
                            isNumeric: false,
                            icon: FontAwesomeIcons.locationPin,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _area,
                            "Area",
                            'Please Enter Area',
                            'rate',
                            isNumeric: false,
                            icon: FontAwesomeIcons.mapLocation,
                            allowSpaces: true,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildLocTypeDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildactivityDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _income,
                            "Monthly Income",
                            'Please Enter Income',
                            'mincome',
                            isNumeric: true,
                            icon: FontAwesomeIcons.moneyBillWave,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTextField(
                            _loanamount,
                            "Loan Amount Requested",
                            'Please Enter Loan Amount',
                            'loan',
                            isNumeric: true,
                            // ignore: deprecated_member_use
                            icon: FontAwesomeIcons.handHoldingUsd,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildTenorDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildPricingDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildDocTypeDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildDropdownField(),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.04,
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
                            height: MediaQuery.of(context).size.height * 0.04,
                          ),
                          _buildImageUploadField(
                              _imageController, "Select Image"),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
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
                                    "NEXT",
                                    style: WidgetSupport.LoginButtonTextColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 180),
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

  Future<void> leadSubmit() async {
    setState(() {
      _isLoading = true;
    });

    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      // Collect form data
      String first_name = _fname.text.trim();
      String middle_name = _mname.text.trim();
      String last_name = _lname.text.trim();
      String phone_number = _phoneNumber.text.trim();
      String address1 = _address1.text.trim();
      String address2 = _address2.text.trim();
      String email = _email.text.trim();
      String zip = _zip.text.trim();
      String city = _selectedCity!;
      String location = _location.text.trim();
      String location_type = _selectedLocationType!;
      String area = _area.text.trim();
      String income = _income.text.trim().replaceAll(',', '');
      String loan_amount_requested =
          _loanamount.text.trim().replaceAll(',', '');
      bool submitted_on_uno_app = true;
      bool need_to_follow_up = false;
      String customer_type = _selectedCustType!;
      String activity = _selectedActivity!;
      String interest = _selectedPricing!;
      String business_name = _businessNameController.text.isNotEmpty
          ? _businessNameController.text.trim()
          : '';
      String tenor = _selectedTenor!;
      String document_type = _selectedDocument!;
      String company =
          _selectedCompany?.isNotEmpty ?? false ? _selectedCompany! : '';
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String? refresh = prefs.getString('refreshToken');
      String selectedGId = _selectedGId!;
      String externalId = _externalId.text.trim();

      // Map the collected data to be sent in the request body
      Map<String, String> mappedData = {
        'company': company,
        'first_name': first_name,
        'middle_name': middle_name,
        'last_name': last_name,
        'phone_number': phone_number,
        'address1': address1,
        'address2': address2,
        'email': email,
        'zip': zip,
        'city': city,
        'location': location,
        'area': area,
        'income': income,
        'loan_amount_requested': loan_amount_requested,
        'submitted_on_uno_app': submitted_on_uno_app.toString(),
        'need_to_follow_up': need_to_follow_up.toString(),
        'customer_type': customer_type,
        'location_type': location_type,
        'activity': activity,
        'interest': interest,
        'business_name': business_name,
        'tenor': tenor,
        'document_type': document_type,
        'kyc_id_type': selectedGId,
        'kyc_id_number': externalId,
      };

      try {
        var url = Uri.parse('http://167.88.160.87/api/leads/');

        var request = http.MultipartRequest('POST', url)
          ..headers['Authorization'] = 'Bearer $token'
          ..fields.addAll(mappedData);

        if (_image != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'kyc_document',
            _image!.path,
          ));
        }
        http.Response response =
            await http.Response.fromStream(await request.send());
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Loancalculation(
                id: data['id'],
                loanAmountRequested: data['loan_amount_requested'],
                tenorDescription: data['tenor_description'],
                monthlyInstallment: data['monthly_installment'],
                interest: data['interest'],
              ),
            ),
          );
        } else if (response.statusCode == 401) {
          setState(() {
            _isLoading = false;
          });

          // Refresh token
          Map<String, dynamic> refreshData = {'refresh': refresh};
          final response2 = await http.post(
            Uri.parse('http://167.88.160.87/api/users/token-refresh/'),
            body: refreshData,
          );

          final data = json.decode(response2.body);
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('accessToken', data['access']);
          await prefs.setString('refreshToken', data['refresh']);
          leadSubmit(); // Retry the submission
        } else {
          // Handle API errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to submit lead. Error: ${response.body}"),
            ),
          );
        }
      } catch (e) {
        // Handle network errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
          ),
        );
      }
    } else {
      // Show a snackbar or other UI indication if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Form validation failed"),
        ),
      );
    }
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
    bool isBlankAlphabetic = false,
    bool isNumeric = false,
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
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return validationMessage;
        }

        if (isNumeric && value != null && value.isNotEmpty) {
          final cleanedValue = value.replaceAll(',', '');
          if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
            return 'Please enter a valid number';
          }
        }

        if (isBlankAlphabetic && value != null && value.isNotEmpty) {
          if (!RegExp(r'^[a-zA-Z]*$').hasMatch(value)) {
            return 'Only alphabets are allowed';
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
    bool isBlankAlphabetic = false,
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
        if (_externalId.text.length > 6) {
          return 'Id must be 6 characters long';
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

  Widget _buildCtypeDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _CustomerType.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Customer Type",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem:
          _selectedCustType != null ? _CustomerType[_selectedCustType] : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedCustType = _CustomerType.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
          clearbusinessname();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Customer Type';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Customer Type",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildactivityDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _Activity.map((e) => e['description'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Activity",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedActivity != null
          ? _Activity.firstWhere((e) => e['id'] == _selectedActivity)[
              'description'] // Show selected description
          : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedActivity =
              _Activity.firstWhere((e) => e['description'] == newValue)['id']
                  .toString();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Activity';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Activity",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildLocTypeDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Hide the search box in the dropdown
        fit: FlexFit.loose, // Adjust the dropdown to fit the content
      ),
      items: _LocationType.map((e) => e['description'].toString())
          .toList(), // Populate dropdown with descriptions
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Location Type", // Hint text in the input field
          hintStyle:
              WidgetSupport.inputLabel(), // Custom style for the hint text
        ),
      ),
      selectedItem: _selectedLocationType != null
          ? _LocationType.firstWhere((e) => e['id'] == _selectedLocationType)[
              'description'] // Show selected description
          : null, // If no location is selected, show null (empty state)
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedLocationType = _LocationType.firstWhere(
                    (e) => e['description'] == newValue)['id']
                .toString(); // Update _selectedLocationType with the selected id
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Location Type'; // Validation message if no item is selected
        }
        return null; // If selection is valid, return null
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ??
              "Select Location Type", // Display selected item or default hint
          style: WidgetSupport
              .dropDownText(), // Custom text style for the dropdown display
        );
      },
    );
  }

  Widget _buildTenorDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _Tenor.map((e) => e['description'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Tenor",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedTenor != null
          ? _Tenor.firstWhere((e) => e['id'] == _selectedTenor)[
              'description'] // Show selected description
          : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedTenor =
              _Tenor.firstWhere((e) => e['description'] == newValue)['id']
                  .toString();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Tenor';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Tenor",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildPricingDropdownField() {
    // Ensure _selectedPricing is initialized to a valid key in _pricing
    if (_selectedPricing == null && _pricing.isNotEmpty) {
      _selectedPricing =
          _pricing.keys.first; // Set a default key if none is selected
    }

    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _pricing.values.toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Interest",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedPricing != null
          ? _pricing[_selectedPricing]
          : null, // Ensure default value is selected
      onChanged: (String? newValue) {
        setState(() {
          _selectedPricing = _pricing.entries
              .firstWhere((entry) => entry.value == newValue)
              .key;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Interest';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Interest",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildDocTypeDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Disable the search box
        fit: FlexFit.loose,
      ),
      items: _doc.map((e) => e['description'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Document",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedDocument != null
          ? _doc.firstWhere((e) => e['id'] == _selectedDocument)[
              'description'] // Show selected description
          : null,
      onChanged: (String? newValue) {
        setState(() {
          _selectedDocument = _doc
              .firstWhere((e) => e['description'] == newValue)['id']
              .toString();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Select Document';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Document",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
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

  void clearbusinessname() {
    _businessNameController.clear();
    _searchController.clear();
    _selectedCompany = null;
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
                fit: BoxFit
                    .cover, 
              ),
            ),
          ),
      ],
    );
  }
}

class NumericCommaInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    // Remove existing commas
    final cleanedValue = newValue.text.replaceAll(',', '');
    if (cleanedValue.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format number with commas
    final number = int.tryParse(cleanedValue) ?? 0;
    final formattedValue = _formatter.format(number);

    // Update the selection to match the formatted value
    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
