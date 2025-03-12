import 'dart:convert';
import 'dart:io';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';

class FsaCompanyLeadGenerate extends StatefulWidget {
  final String edit;
  const FsaCompanyLeadGenerate({super.key, required this.edit});
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
  final contact_person_first_name = TextEditingController();
  final contact_person_last_name = TextEditingController();
  final contact_person_mobile_no = TextEditingController();
  late Map<String, String> _CityIdOptions; // Store the All city
  TextEditingController _citysearchController = TextEditingController();
  late List<Map<String, String>> _filteredCity; // Store filtered companies
  late List<Map<String, String>> _barangay = []; // Initialize as an empty map
  final email = TextEditingController();
  final _imageController = TextEditingController();
  final _externalId = TextEditingController();
  String? _selectedCompanyType;
  bool _isLoading = false;
  late Map<String, String> _ComIdOptions;
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies

  TextEditingController _searchController = TextEditingController();
// Track if TextField is clicked
  bool _isDropdownVisible = false;
  bool _isCityFieldFocused = false;
  String? _cityError;
  String _imageUrl = "";
  Uint8List? _imageBytes;
  bool _hasError = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _ComIdOptions = {};
    _filteredCompanies = [];
    _loadData();
    _loadCityData();
    if (widget.edit != "") {
      _loadEditLead();
    }
  }

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

  // Load initial company data
  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/company-types/'),
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
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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
            '${AppConfig.baseUrl}/api/leads/company-types/?search=$query'),
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
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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

  Future<void> _loadEditLead() async {
    _isLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/company-leads/${widget.edit}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);
      final companyType = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/company-types/?search=${data['type_name']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data44 = json.decode(companyType.body);
      if (data44['results'] != null && data44['results'] is List) {
        List<dynamic> companiesType = data44['results'];
        Map<String, String> fetchedData = {};

        for (var item in companiesType) {
          fetchedData[item['id'].toString()] = item['type_name'].toString();
        }

        setState(() {
          _ComIdOptions = fetchedData;
          _filteredCompanies = _ComIdOptions.entries
              .map((e) => {'id': e.key, 'type_name': e.value})
              .toList();
          _selectedCompanyType = data['company_type'].toString();
          _searchController.text = _ComIdOptions[_selectedCompanyType]!;
        });
      }
      final String? kycIdType = data['kyc_id_type'];
      if (kycIdType != null && _gIdOptions.containsKey(kycIdType)) {
        _selectedGId = kycIdType; // Assign the key instead of the value
      }

      final barangayresponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/cities/${data['city']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data6 = json.decode(barangayresponse.body);

      if (data6['barangays'] != null && data6['barangays'] is List) {
        setState(() {
          _barangay =
              List<Map<String, String>>.from(data6['barangays'].map((item) {
            return {
              'id': item['id'].toString(),
              'barangay_name': item['barangay_name'].toString(),
            };
          }));

          // Ensure the selected barangay is correctly set
          _selectedBarangayType = data['barangay']?.toString();
        });
      }
      final companyResponse = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/companies/?search=${data['company']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> dataComp = json.decode(companyResponse.body);
      if (dataComp['results'] != null && dataComp['results'] is List) {
        List<dynamic> companies = dataComp['results'];

        Map<String, String> fetchedDataComp = {};
        for (var item in companies) {
          fetchedDataComp[item['id'].toString()] =
              item['company_name'].toString();
        }

        setState(() {});
      }
      final cityresponse = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/cities/?search=${data['city_name']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data454 = json.decode(cityresponse.body);
      if (data454['results'] != null && data454['results'] is List) {
        List<dynamic> citydata = data454['results'];
        Map<String, String> fetchedData = {};
        // Map<String, String> fetchedData2 = {};

        for (var item in citydata) {
          fetchedData[item['id'].toString()] = item['city_name'].toString();
        }
        setState(() {
          _CityIdOptions = fetchedData;
          _filteredCity = _CityIdOptions.entries
              .map((e) => {'id': e.key, 'city_name': e.value})
              .toList();

          _selectedCity = data['city'].toString();
          _citysearchController.text = _CityIdOptions[_selectedCity] ?? '';
          //  _selectedCity = data['city'].toString();
          // _barangay = _CityIdOptions[_selectedCity] ?? '';
        });
      }
      if (response.statusCode == 200) {
        setState(() {
          company_name.text = data['company_name'];
          number_of_employees.text = data['number_of_employees'].toString();
          operating_since.text = data['operating_since'].toString();
          address_line_1.text = data['address_line_1'];
          address_line_2.text = data['address_line_2'];
          contact_person_first_name.text = data['contact_person_first_name'];
          contact_person_last_name.text = data['contact_person_last_name'];
          contact_person_mobile_no.text = data['contact_person_mobile_no'];
          email.text = data['email'];
          zip_code.text = data['zip_code'];
          _externalId.text = data['kyc_id_number'];
          _imageController.text = data['kyc_document'];

          // Load the image if available

          if (data['kyc_document'] != null && data['kyc_document'].isNotEmpty) {
            _imageUrl = data['kyc_document'];
            _fetchImage(_imageUrl);

            downloadFile(data['kyc_document']).then((file) {
              if (file != null) {
                setState(() {
                  _image = file; // Now _image is a File object
                });
              }
            });
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load document type');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _fetchImage(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Uint8List imageBytes = response.bodyBytes;
        if (imageBytes.isNotEmpty) {
          setState(() {
            _imageBytes = imageBytes;
            _isLoading = false;
            _hasError = false;
          });
          downloadFile(_imageUrl);
        } else {
          _handleImageError();
        }
      } else {
        _handleImageError();
      }
    } catch (e) {
      print("Image loading error: $e");
      _handleImageError();
    }
  }

  Future<File?> downloadFile(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken'); // Retrieve access token

    if (token == null || token.isEmpty) {
      print("Error: Missing access token");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $token', // Include authorization header
        },
      );
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.parse(imageUrl).pathSegments.last;
        final filePath = '${tempDir.path}/$fileName';
        final _image = File(filePath);
        await _image.writeAsBytes(response.bodyBytes);

        return _image;
      } else {
        print("Failed to download image: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error downloading image: $e");
      return null;
    }
  }

  void _handleImageError() {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _imageBytes = null;
    });
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
                        builder: (context) => FsaLeadDashBoard(
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
                                        if (widget.edit != "") {
                                          _loadData();
                                        }
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
                                                  _isDropdownVisible = false;
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
                              icon: FontAwesomeIcons.mapLocation,
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
                            // _buildCityDropdownField(),
                            Padding(
                              padding: EdgeInsets.all(0.0),
                              child: Column(
                                children: [
                                  // TextField for searching cities
                                  Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(() {
                                        _isCityFieldFocused =
                                            hasFocus; // Track if the TextField is focused
                                      });
                                    },
                                    child: TextField(
                                      controller: _citysearchController,
                                      decoration: InputDecoration(
                                        hintText: "Search City",
                                        errorText: _cityError,
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.search),
                                          onPressed: () {
                                            // Trigger the search when the search icon is pressed
                                            _filterCity(
                                                _citysearchController.text);
                                          },
                                        ),
                                      ),
                                      onChanged: (query) {
                                        if (query.isEmpty) {
                                          // Reset to showing all companies if the input is cleared
                                          setState(() {
                                            _filteredCity = _CityIdOptions
                                                .entries
                                                .map((e) => {
                                                      'id': e.key,
                                                      'city_name': e.value
                                                    })
                                                .toList();
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  if (_isCityFieldFocused)
                                    Stack(
                                      children: [
                                        Positioned(
                                          child: Material(
                                            elevation: 4,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Container(
                                              height: 200,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              child: ListView.builder(
                                                itemCount: _filteredCity.length,
                                                itemBuilder: (context, index) {
                                                  return ListTile(
                                                    title: Text(
                                                        _filteredCity[index]
                                                            ['city_name']!),
                                                    onTap: () {
                                                      // Set the selected company
                                                      setState(() {
                                                        _selectedCity =
                                                            _filteredCity[index]
                                                                ['id'];
                                                        _citysearchController
                                                                .text =
                                                            _filteredCity[index]
                                                                ['city_name']!;
                                                        _isCityFieldFocused =
                                                            false;
                                                        _loadBarangayData(
                                                            _selectedCity!);
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
                                ],
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
                            ),
                            _buildBarangayDropdownField(),
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
                              "(Please put country code e.g. 63XXXXXXXXXX)",
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: Text(
                                      "SUBMIT",
                                      style:
                                          WidgetSupport.LoginButtonTextColor(),
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
                  ),
                )
              ],
            ),
          ),
          if (_isLoading)
            Container(
              // ignore: deprecated_member_use
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
        Uri.parse('${AppConfig.baseUrl}/api/leads/cities/?page=2'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> citydata = data['results'];
          Map<String, String> fetchedData = {};
          for (var item in citydata) {
            fetchedData[item['id'].toString()] = item['city_name'].toString();
          }

          setState(() {
            _CityIdOptions = fetchedData;
            _filteredCity = _CityIdOptions.entries
                .map((e) => {'id': e.key, 'city_name': e.value})
                .toList();
          });
        }
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {'refresh': refresh};
        final response2 = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _loadCityData();
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Search for companies based on the query
  Future<void> _filterCity(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      setState(() {
        _filteredCity = _CityIdOptions.entries
            .map((e) => {'id': e.key, 'city_name': e.value})
            .toList();
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/cities/?search=$query'),
        headers: await _getAuthHeader(),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> cityData = data['results'];

          setState(() {
            _filteredCity = cityData
                .map((e) => {
                      'id': e['id'].toString(),
                      'city_name': e['city_name'].toString(),
                    })
                .toList();
            _loadBarangayData(query);
          });
        }
      } else if (response.statusCode == 401) {
        String? refresh = prefs.getString('refreshToken');
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
          body: mappedData,
        );
        final data = json.decode(response2.body);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        _filterCity(query);
      } else {
        throw Exception('Failed to search City');
      }
    } catch (e) {
      print('Search Error: $e');
    }
  }

  String? _selectedBarangayType;

  Future<void> _loadBarangayData(String query2) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/cities/${_selectedCity}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['barangays'] != null && data['barangays'] is List) {
          List<dynamic> barangays = data['barangays'];

          Map<String, String> fetchedData = {};
          for (var item in barangays) {
            fetchedData[item['id'].toString()] =
                item['barangay_name'].toString();
          }

          setState(() {
            _ComIdOptions = fetchedData;
            // Initially, show all companies in the list
            _barangay = fetchedData.entries
                .map((e) => {'id': e.key, 'barangay_name': e.value})
                .toList();
          });
        }
      } else if (response.statusCode == 401) {
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse(
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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

  Future<void> leadSubmit() async {
    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

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
      String selectedGId = _selectedGId!;
      String externalId = _externalId.text.trim();
      String barangay = _selectedBarangayType!;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String? refresh = prefs.getString('refreshToken');

      // Map the collected data to be sent in the request body
      Map<String, String> mappedData = {
        'company_name': company,
        'company_type': company_type,
        'number_of_employees': number_of_employee,
        'operating_since': operating,
        'address_line_1': address1,
        'address_line_2': address2,
        'zip_code': zip,
        'city': city,
        'barangay': barangay,
        'contact_person_first_name': contact_p_first_name,
        'contact_person_last_name': contact_p_last_name,
        'contact_person_mobile_no': contact_p_mobile_no,
        'email': contact_p_email,
        'kyc_id_type': selectedGId,
        'kyc_id_number': externalId,
      };
      if (widget.edit == "") {
        try {
          var url = Uri.parse('${AppConfig.baseUrl}/api/leads/company-leads/');
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
              Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
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
      }
      else
      {
        try {
          var url = Uri.parse('${AppConfig.baseUrl}/api/leads/company-leads/${widget.edit}/');
          var request = http.MultipartRequest('put', url)
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
          if (response.statusCode == 200) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Success'),
                  content: Text('Lead Updated successfully!'),
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
              Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
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
        if (isZipNumber) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4), // Limit to 4 digits
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

  Widget _buildBarangayDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _barangay.map((e) => e['barangay_name'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Barangay",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _barangay.isNotEmpty
          ? _barangay.firstWhere(
              (e) => e['id'] == _selectedBarangayType,
              orElse: () => {'barangay_name': "Select Barangay"},
            )['barangay_name']
          : "Select Barangay",
      onChanged: (String? newValue) {
        setState(() {
          final selectedBarangay = _barangay.firstWhere(
            (e) => e['barangay_name'] == newValue,
          );
          _selectedBarangayType = selectedBarangay['id']?.toString();
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select Barangay';
        }
        return null;
      },
      dropdownBuilder: (BuildContext context, String? selectedItem) {
        return Text(
          selectedItem ?? "Select Barangay",
          style: WidgetSupport.dropDownText(),
        );
      },
    );
  }

  Widget _buildKydIdTextField(
    TextEditingController controller,
    String hintText,
    String validationMessage,
    String validationKey, {
    IconData icon = FontAwesomeIcons.solidCircleUser,
    bool obscureText = false,
    bool isNumeric = false,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      validator: (_selectedKycId) {
        if (_selectedKycId == "" && _selectedGId != null) {
          return 'Please Enter Id'; // Validation message if KYC ID is selected but no image uploaded
        }
        if (_selectedKycId != null && _selectedKycId.isNotEmpty) {
          if (_selectedKycId.length < 6) {
            return 'ID must be at least 6 characters long';
          }
          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_selectedKycId)) {
            return 'Special characters are not allowed';
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
                            await _pickImage(ImageSource.camera, controller);
                            Navigator.of(context).pop(); // Close dialog
                          },
                          child: const Text("Camera"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _pickImage(ImageSource.gallery, controller);
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
          validator: (_) {
            if (_selectedGId != null &&
                _image == null &&
                (_imageUrl == null || _imageUrl!.isEmpty)) {
              return 'Please upload an image'; // Show error only if no image is available at all
            }
            return null;
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  width: 300,
                  height: 150,
                  fit: BoxFit.fill,
                )
              : Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      ],
    );
  }

// Function to handle image selection and replacement
  Future<void> _pickImage(
      ImageSource source, TextEditingController controller) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final Uint8List imageBytes = await File(image.path).readAsBytes();

      setState(() {
        _image = File(image.path); // Replace with new image
        _imageBytes = imageBytes; // Update UI with new image bytes
        _imageController.text = image.path;
      });
    }
  }
}
