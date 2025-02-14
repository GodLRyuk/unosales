import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/config/config.dart';
class DropdownState with ChangeNotifier {
  String? _selectedComId;
  Map<String, String> _ComIdOptions = {}; // To store fetched company data
  bool _isLoading = false;

  String? get selectedComId => _selectedComId;
  Map<String, String> get ComIdOptions => _ComIdOptions;
  bool get isLoading => _isLoading;

  set selectedComId(String? value) {
    notifyListeners();
    _selectedComId = value;
  }

  set ComIdOptions(Map<String, String> newOptions) {
  _ComIdOptions = newOptions;
  print("Updated ComIdOptions: $_ComIdOptions");  // Debugging
  notifyListeners();
} 

  set isLoading(bool value) {
    notifyListeners();
    _isLoading = value;
    
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/companies/?page_size=100'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['results'] != null && data['results'] is List) {
          List<dynamic> companies = data['results'];

          Map<String, String> fetchedData = {};
          for (var item in companies) {
            fetchedData[item['company_number'].toString()] =
                item['company_name'].toString();
          }
          ComIdOptions = fetchedData;
          isLoading = false;
        }
      } else {
        throw Exception('Failed to load companies');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> searchCompanies(String searchText) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('accessToken');
  String url = '${AppConfig.baseUrl}/api/leads/companies/';
  if (searchText.isNotEmpty) {
    url += '?search=$searchText';
  }
  
  try {
    isLoading = true;

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['results'] != null && data['results'] is List) {
        List<dynamic> companies = data['results'];

        Map<String, String> fetchedData = {};
        for (var item in companies) {
          fetchedData[item['company_number'].toString()] =
              item['company_name'].toString();
        }
        ComIdOptions = fetchedData;
        isLoading = false;

        // Close the dropdown
        closeDropdown();
      }
    } else {
      throw Exception('Failed to load companies');
    }
  } catch (e) {
    print('Error occurred while fetching data: $e');
    ComIdOptions = {}; // Clear options on error
    isLoading = false;
  }
}

/// Function to close the dropdown
void closeDropdown() {
  // Implement the logic to close the dropdown
  // This could involve clearing the dropdown's selected value or collapsing it
  print('Dropdown closed');
}
}
