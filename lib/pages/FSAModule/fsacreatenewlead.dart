import 'dart:async';
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
import 'package:unosfa/pages/FSAModule/fsaloancalculation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:intl/intl.dart';
import 'package:unosfa/pages/config/config.dart';

class FsaLeadGenerate extends StatefulWidget {
  final String edit;
  const FsaLeadGenerate({super.key, required this.edit});
  @override
  _FsaLeadGenerateState createState() => _FsaLeadGenerateState();
}

class _FsaLeadGenerateState extends State<FsaLeadGenerate> {
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
  final _income = TextEditingController();
  final _loanamount = TextEditingController();
  final _businessNameController = TextEditingController();
  final _area = TextEditingController();
  final _otherCompanyController = TextEditingController();
  bool _isLoading = false;
  late Map<String, String> _ComIdOptions; // Store the fetched companies
  late Map<String, String> _LocatinIdOptions; // Store the fetched location
  late Map<String, String> _ActivityIdOptions; // Store the fetched activity
// Store the fetched Loan
  late Map<String, String> _DocumentIdOptions; // Store the fetched location
  late Map<String, String> _TenorIdOptions; // Store the fetched location

  late List<Map<String, String>> _Tenor = []; // Initialize as an empty map
  late List<Map<String, String>> _LocationType =
      []; // Initialize as an empty map
  late List<Map<String, String>> _Activity = []; // Initialize as an empty map
  late List<Map<String, String>> _filteredCompanies; // Store filtered companies
  late Map<String, String> _CityIdOptions; // Store the All city
  TextEditingController _citysearchController = TextEditingController();
  late List<Map<String, String>> _filteredCity; // Store filtered companies
  late List<Map<String, String>> _barangay = []; // Initialize as an empty map
  String? _selectedGId;
  late List<Map<String, String>> _doc = []; // Initialize as an empty map
  String? _selectedDocument;
  TextEditingController _searchController = TextEditingController();
  String? _selectedCompany;
  bool _isFieldFocused = false; // Track if TextField is clicked
  bool _isCityFieldFocused = false;
  String? _cityError;
  final _externalId = TextEditingController();
  final _imageController = TextEditingController();
  bool _selectedKycId = false;
  bool _showOtherCompanyField = false;
  String _imageUrl = "";
  Uint8List? _imageBytes;
  bool _hasError = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _ComIdOptions = {};
    _filteredCompanies = [];
    _Tenor = [];
    _doc = [];
    _loadData();
    _loadLocationData();
    _loadActivityData();
    _loadTenorData();
    _loadDocData();
    _loadCityData();
    if (widget.edit != "") {
      _loadEditLead();
    }
  }

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
        Uri.parse('${AppConfig.baseUrl}/api/leads/companies/?page_size=10'),
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
            _filteredCompanies = fetchedData.entries
                .map((e) => {'id': e.key, 'company_name': e.value})
                .toList();

            // Append "Others" option
            _filteredCompanies.add({'id': 'others', 'company_name': 'Others'});
          });
        }
      } else if (response.statusCode == 401) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
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

  Future<void> _searchCompany(String query) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (query.isEmpty) {
      setState(() {
        _filteredCompanies = _ComIdOptions.entries
            .map((e) => {'id': e.key, 'company_name': e.value})
            .toList();

        // Append "Others" option
        _filteredCompanies.add({'id': 'others', 'company_name': 'Others'});
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/companies/?search=$query'),
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

            // Append "Others" option
            _filteredCompanies.add({'id': 'others', 'company_name': 'Others'});
          });
        }
      } else if (response.statusCode == 401) {
        String? refresh = prefs.getString('refreshToken');
        Map<String, dynamic> mappedData = {
          'refresh': refresh,
        };
        final response2 = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
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
        Uri.parse('${AppConfig.baseUrl}/api/leads/location-types'),
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

  String? _selectedActivity;
  Future<void> _loadActivityData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/activities'),
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
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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
        Uri.parse('${AppConfig.baseUrl}/api/leads/tenors'),
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
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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
  Future<void> _loadDocData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/document-types'),
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
              '${AppConfig.baseUrl}/api/users/token-refresh/'), // Using leadId in the API URL
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

  String numericCommaInputFormatter(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }

    // Parse the value to a number
    final number = double.tryParse(value.toString());
    if (number == null) {
      return '';
    }

    // Format the number without trailing .00
    final formatted = number.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(\.\d{0,2})?$)'),
          (Match match) => '${match[1]},',
        );

    // Remove unnecessary .00 at the end
    return formatted.endsWith('.00') ? formatted.split('.')[0] : formatted;
  }

  Future<void> _loadEditLead() async {
    _isLoading = true;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/${widget.edit}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(response.body);

      final cityresponse = await http.get(
        Uri.parse(
            '${AppConfig.baseUrl}/api/leads/cities/?search=${data['city_name']}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data44 = json.decode(cityresponse.body);
      if (data44['results'] != null && data44['results'] is List) {
        List<dynamic> citydata = data44['results'];
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
      final locationresponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/location-types'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data2 = json.decode(locationresponse.body);
      if (data2['results'] != null && data2['results'] is List) {
        List<dynamic> location = data2['results'];
        Map<String, String> fetchedData2 = {};
        for (var item in location) {
          fetchedData2[item['id'].toString()] = item['id'].toString();
        }
        _LocatinIdOptions = fetchedData2;
      }

      final activityresponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/activities'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data3 = json.decode(activityresponse.body);
      if (data3['results'] != null && data3['results'] is List) {
        List<dynamic> activity = data3['results'];
        Map<String, String> fetchedData3 = {};
        for (var item in activity) {
          fetchedData3[item['id'].toString()] = item['id'].toString();
        }
        _ActivityIdOptions = fetchedData3;
      }

      final tenorsresponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/tenors'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data4 = json.decode(tenorsresponse.body);
      if (data4['results'] != null && data4['results'] is List) {
        List<dynamic> tenor = data4['results'];
        Map<String, String> fetchedData4 = {};
        for (var item in tenor) {
          fetchedData4[item['id'].toString()] = item['id'].toString();
        }
        _TenorIdOptions = fetchedData4;
      }

      final documentresponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/document-types'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final Map<String, dynamic> data5 = json.decode(documentresponse.body);
      if (data5['results'] != null && data5['results'] is List) {
        List<dynamic> docs = data5['results'];
        Map<String, String> fetchedData5 = {};
        for (var item in docs) {
          fetchedData5[item['id'].toString()] = item['id'].toString();
        }
        _DocumentIdOptions = fetchedData5;
      }

      // final Map<String, dynamic> kycIdata = _gIdOptions;
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

        setState(() {
          _ComIdOptions = fetchedDataComp;

          // Ensure the selected company is set correctly
          _selectedCompany = data['company']?.toString() ?? '';

          // Populate the search field with the selected company's name
          _searchController.text = _ComIdOptions[_selectedCompany] ?? '';

          // Initialize filtered company list
          _filteredCompanies = _ComIdOptions.entries
              .map((e) => {'id': e.key, 'company_name': e.value})
              .toList();
        });
      }
      if (response.statusCode == 200) {
        setState(() {
          _fname.text = data['first_name'];
          _mname.text = data['middle_name'];
          _lname.text = data['last_name'];
          _phoneNumber.text = data['phone_number'];
          _address1.text = data['address1'];
          _address2.text = data['address2'];
          _email.text = data['email'];
          _zip.text = data['zip'];
          _area.text = data['area'];
          _externalId.text = data['kyc_id_number'];
          _income.text =
              numericCommaInputFormatter(double.parse(data['income']));
          _loanamount.text = numericCommaInputFormatter(
              double.parse(data['loan_amount_requested']));
          _businessNameController.text = data['business_name'] ?? '';
          _location.text = data['location'];
          _imageController.text = data['kyc_document'];
          for (var entry2 in _LocatinIdOptions.entries) {
            if (data['location_type'].toString() == entry2.value) {
              _selectedLocationType = entry2.key;
              break;
            }
          }

          for (var entry3 in _ActivityIdOptions.entries) {
            if (data['activity'].toString() == entry3.value) {
              _selectedActivity = entry3.key;
              break;
            }
          }

          for (var entry4 in _TenorIdOptions.entries) {
            if (data['tenor'].toString() == entry4.value) {
              _selectedTenor = entry4.key;
              break;
            }
          }

          for (var entry5 in _DocumentIdOptions.entries) {
            if (data['document_type'].toString() == entry5.value) {
              _selectedDocument = entry5.key;
              break;
            }
          }
          if (data['customer_type'] == 'salaried') {
            _selectedCustType = "salaried";
          } else {
            _selectedCustType = "self_employed";
          }
          for (var entry7 in _ComIdOptions.entries) {
            if (data['company'].toString() == entry7.value) {
              _selectedCompany = entry7.key;
              break;
            }
          }
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
                                        _isFieldFocused = hasFocus;
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
                                                  _isFieldFocused = false;
                                                  _showOtherCompanyField =
                                                      _selectedCompany ==
                                                          'others';
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
                          if (_showOtherCompanyField) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.0),
                              child: TextFormField(
                                controller: _otherCompanyController,
                                decoration: InputDecoration(
                                  hintText: "Enter company name",
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      _selectedCompany == 'others') {
                                    return 'Company name is required';
                                  }
                                  return null;
                                },
                                onChanged: (value) {},
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.04,
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
                          Padding(
                            padding: EdgeInsets.all(0.0),
                            child: Column(
                              children: [
                                // TextField for searching cities
                                Focus(
                                  onFocusChange: (hasFocus) {
                                    setState(() {
                                      if (widget.edit != "") {
                                        _loadCityData();
                                      }
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
                                          _filteredCity = _CityIdOptions.entries
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
                            'area',
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
                          _buildTextField(
                            _email,
                            "Contact Person Email ID ",
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
                                    setState(() {
                                      if (_citysearchController.text.isEmpty) {
                                        _cityError = "City name is required";
                                      } else {
                                        _cityError = null;
                                      }
                                      if (_formKey.currentState!.validate()) {
                                        leadSubmit();
                                      }
                                    });
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

  Future<void> leadSubmit() async {
    // Check if the form is valid
    String middle_name = _mname.text.trim();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      // Collect form data
      String first_name = _fname.text.trim();
      String last_name = _lname.text.trim();
      String phone_number = _phoneNumber.text.trim();
      String address1 = _address1.text.trim();
      String address2 = _address2.text.trim();
      String email = _email.text.trim();
      String zip = _zip.text.trim();
      String area = _area.text.trim();
      String city = _selectedCity!;
      String location = _location.text.trim();
      String location_type = _selectedLocationType!;
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
      String finalOtherCompanyName = _selectedCompany == 'others'
          ? _otherCompanyController.text.trim()
          : '';
      String company =
          _selectedCompany == 'others' ? '' : (_selectedCompany ?? '');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('accessToken');
      String? refresh = prefs.getString('refreshToken');
      String barangay = _selectedBarangayType!;
      String disposition_code = "";
      String sub_disposition_code = "";
      String selectedGId = _selectedGId ?? "";
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
        'area': area,
        'zip': zip,
        'city': city,
        'barangay': barangay,
        'location': location,
        'income': income,
        'loan_amount_requested': loan_amount_requested,
        'submitted_on_uno_app': submitted_on_uno_app.toString(),
        'need_to_follow_up': need_to_follow_up.toString(),
        'customer_type': customer_type,
        'interest': interest,
        'business_name': business_name,
        'tenor': tenor,
        'location_type': location_type,
        'activity': activity,
        'document_type': document_type,
        'disposition_code': disposition_code,
        'sub_disposition_code': sub_disposition_code,
        'kyc_id_type': selectedGId,
        'kyc_id_number': externalId,
        'others_company': finalOtherCompanyName
      };
      if (widget.edit == "") {
        try {
          var url = Uri.parse('${AppConfig.baseUrl}/api/leads/');
          var request = http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer $token'
            ..fields.addAll(mappedData);

          if (_image != null) {
            request.files.add(
              await http.MultipartFile.fromPath('kyc_document', _image!.path),
            );
          } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
            request.fields['kyc_document'] =
                _imageUrl!; // Send existing image URL if no new image is picked
          }
          http.Response response =
              await http.Response.fromStream(await request.send());

          if (response.statusCode == 201) {
            final data = json.decode(response.body);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FsaLoancalculation(
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
            Map<String, dynamic> mappedData = {
              'refresh': refresh,
            };
            final response2 = await http.post(
              Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
              body: mappedData,
            );
            final data = json.decode(response2.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            leadSubmit();
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
        try {
          var url = Uri.parse('${AppConfig.baseUrl}/api/leads/${widget.edit}/');
          var request = http.MultipartRequest('put', url)
            ..headers['Authorization'] = 'Bearer $token'
            ..fields.addAll(mappedData);

          if (_image != null) {
            request.files.add(
              await http.MultipartFile.fromPath('kyc_document', _image!.path),
            );
          } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
            request.fields['kyc_document'] =
                _imageUrl!; // Send existing image URL if no new image is picked
          }
          http.Response response =
              await http.Response.fromStream(await request.send());
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FsaLoancalculation(
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
            Map<String, dynamic> mappedData = {
              'refresh': refresh,
            };
            final response2 = await http.post(
              Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
              body: mappedData,
            );
            final data = json.decode(response2.body);
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            leadSubmit();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to update lead. Error: ${response.body}"),
              ),
            );
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("An error occurred: $e"),
            ),
          );
        }
      }
    } else {
      // Show a snackbar or other UI indication if validation fails
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

  void clearbusinessname() {
    _businessNameController.clear();
    _searchController.clear();
    _selectedCompany = null;
  }

  void clearAllFields() {
    _fname.clear();
    _mname.clear();
    _lname.clear();
    _phoneNumber.clear();
    _address1.clear();
    _address2.clear();
    _zip.clear();
    _location.clear();
    _income.clear();
    _loanamount.clear();
    _businessNameController.clear();

    // Reset selected values
    setState(() {
      _selectedCity = null;
      _selectedCustType = null;
      _selectedPricing = null;
      _selectedTenor = null;
      _selectedCompany = null;
    });

    // Reset the form state
    _formKey.currentState?.reset();
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
        if (isZipNumber) ...[
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4), // Limit to 4 digits
        ],
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
        if (isEmail && value != null && value.isNotEmpty) {
          final emailRegex = RegExp(
              r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'); // Valid email format
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
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
      selectedItem:
          (_selectedBarangayType == null || _selectedBarangayType!.isEmpty)
              ? null
              : _barangay.firstWhere(
                  (e) => e['id'] == _selectedBarangayType,
                  orElse: () => {'barangay_name': ""},
                )['barangay_name'],
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
        if (value == null || value == "") {
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

  Widget _buildLocTypeDropdownField() {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _LocationType.map((e) => e['description'].toString()).toList(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          hintText: "Select Location Type",
          hintStyle: WidgetSupport.inputLabel(),
        ),
      ),
      selectedItem: _selectedLocationType != null
          ? _LocationType.firstWhere(
              (e) => e['id'] == _selectedLocationType)['description']
          : null,
      onChanged: (String? newValue) {
        setState(() {
          if (newValue != null) {
            _selectedLocationType = _LocationType.firstWhere(
                    (e) => e['description'] == newValue)['id']
                .toString(); // Update _selectedLocationType with the selected id
          }
        });
        FocusScope.of(context).requestFocus(FocusNode());
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
        FocusScope.of(context).requestFocus(FocusNode());
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
        if (_selectedKycId != null && _selectedKycId!.isNotEmpty) {
          if (_selectedKycId!.length < 6) {
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
        FocusScope.of(context).requestFocus(FocusNode());
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
        FocusScope.of(context).requestFocus(FocusNode());
      },
      dropdownBuilder: (BuildContext context, String? _selectedGId) {
        return Text(
          _selectedGId ?? "Select KYC ID",
          style: WidgetSupport.dropDownText(),
        );
      },
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
