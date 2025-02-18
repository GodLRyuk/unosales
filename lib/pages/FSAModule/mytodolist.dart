import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/leadroughttracking.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';
class FSAMyTodoList extends StatefulWidget {
  final String searchQuery;
  const FSAMyTodoList({super.key, required this.searchQuery});

  @override
  State<FSAMyTodoList> createState() => _FSAMyTodoListState();
}

class _FSAMyTodoListState extends State<FSAMyTodoList> {
  final _searchFilter = TextEditingController();
  final _toDate = TextEditingController();
  final _fromDate = TextEditingController();
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  String filterText = '';
  bool isLoading = true;
  bool areDateFieldsVisible =
      false; // Boolean to control visibility of date fields
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;

  @override
  void initState() {
    super.initState();
    selectedFromDate = DateTime.now();
    selectedToDate = DateTime.now();
    fetchLeads(); // Fetch leads on initialization
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  // Method to fetch leads
  Future<void> fetchLeads({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        isFetchingMore = true;
      });
    } else {
      setState(() {
        isLoading = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String apiUrl =
        '${AppConfig.baseUrl}/api/leads/?search=${widget.searchQuery}&ordering=-created_at&page=$currentPage';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> leadsData = data['results'] ?? [];

        setState(() {
          if (isLoadMore) {
            leads.addAll(leadsData.map((item) => {
                  'name':
                      '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                          .trim(),
                  'phone': item['phone_number']?.toString() ?? '',
                  'id': item['id']?.toString() ?? '',
                }));
          } else {
            leads = leadsData
                .map((item) => {
                      'name':
                          '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                              .trim(),
                      'phone': item['phone_number']?.toString() ?? '',
                      'id': item['id']?.toString() ?? '',
                    })
                .toList();
          }

          filteredLeads = List.from(leads);

          // Check if there's more data
          hasMoreData = data['next'] != null;

          isLoading = false;
          isFetchingMore = false;
        });
      } else {
        setState(() {
          isLoading = false;
          isFetchingMore = false;
        });
        throw Exception('Failed to load leads');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      print('Error fetching leads: $e');
    }
  }

// Scroll listener
  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isFetchingMore &&
        hasMoreData) {
      currentPage++;
      fetchLeads(isLoadMore: true); // Fetch more data
    }
  }

  Future<void> fetchFilteredLeads() async {
    String searchQuery = '';
    if (_searchFilter.text.isNotEmpty) {
      searchQuery = '?phone_number=${_searchFilter.text}';
    }
    if (_toDate.text.isNotEmpty && _fromDate.text.isNotEmpty) {
      searchQuery += (searchQuery.isNotEmpty ? '&' : '?') +
          'created_at_from=${_fromDate.text}&created_at_to=${_toDate.text}T23:59:59';
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/$searchQuery'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> leadsData = data['results'] ?? [];
        setState(() {
          leads = leadsData.map((item) {
            return {
              'name':
                  '${item['first_name']} ${item['middle_name']} ${item['last_name']}'
                      .trim(),
              'phone': item['phone_number']?.toString() ?? '',
              'id': item['id']?.toString() ?? '',
            };
          }).toList();
          filteredLeads = List.from(leads);
          hasMoreData = data['next'] != null;

          isLoading = false;
          isFetchingMore = false;
        });
      } else if (response.statusCode == 401) {
        final response2 = await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
          body: {'refresh': refresh},
        );
        final data = json.decode(response2.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', data['access']);
        await prefs.setString('refreshToken', data['refresh']);
        fetchFilteredLeads(); // Retry fetching after token refresh
      } else {
        throw Exception('Failed to load leads');
      }
    } catch (e) {
      print('Error fetching leads: $e');
      setState(() {
        isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching leads: $e')),
      );
    }
  }

  // Format the date string
  String getFormattedFromDate(DateTime? date) {
    if (date == null) {
      return 'Select Date';
    }
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String getFormattedToDate(DateTime? date1) {
    if (date1 == null) {
      return 'Select Date';
    }
    return "${date1.year}-${date1.month.toString().padLeft(2, '0')}-${date1.day.toString().padLeft(2, '0')}";
  }

  // Toggle visibility of the date fields
  void _toggleDateFieldsVisibility() {
    setState(() {
      areDateFieldsVisible = !areDateFieldsVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFc433e0),
                Color(0xFF9a37ae),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/logo.PNG',
                  height: 30,
                ),
                SizedBox(width: 50),
              ],
            ),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => NavigationPage()));
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh the data or reset necessary states
                await fetchFilteredLeads();
              },
              child: Column(
                children: [
                  // Filter section
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TextField for phone number filter
                        TextField(
                          controller: _searchFilter,
                          decoration: InputDecoration(
                            labelText: 'Filter by Phone Number',
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.filter_list),
                              onPressed:
                                  _toggleDateFieldsVisibility, // Toggle date fields visibility
                            ),
                          ),
                          style: TextStyle(height: 1),
                          // onChanged: _filterLeads, // Uncomment if needed
                        ),

                        // Date fields visibility control
                        if (areDateFieldsVisible)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _fromDate,
                                  readOnly: true,
                                  onTap: () => _selectFromDate(),
                                  decoration: InputDecoration(
                                    labelText: "From Date",
                                    hintText: selectedFromDate == null
                                        ? 'Select Date'
                                        : getFormattedFromDate(
                                            selectedFromDate),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF640D78)),
                                    ),
                                    suffixIcon:
                                        Icon(Icons.calendar_month_outlined),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _toDate,
                                  readOnly: true,
                                  onTap: () => _selectToDate(),
                                  decoration: InputDecoration(
                                    labelText: "To Date",
                                    hintText: selectedToDate == null
                                        ? 'Select Date'
                                        : getFormattedToDate(selectedToDate),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFF640D78)),
                                    ),
                                    suffixIcon:
                                        Icon(Icons.calendar_month_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        SizedBox(
                          height: 10,
                        ),

                        // Search button for applying filters
                        if (areDateFieldsVisible)
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFc433e0),
                                          Color(0xFF9a37ae)
                                        ], // Define your gradient colors
                                        begin: Alignment
                                            .topLeft, // Start from top-left
                                        end: Alignment
                                            .bottomRight, // End at bottom-right
                                      ),
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        fetchFilteredLeads();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        "Search",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18), // Text style
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
                  // ListView.builder for displaying filtered leads
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(
                          10), // Adding some margin around the container

                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : leads.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No Leads Found',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                )
                              : ListView.builder(
                                  controller:
                                      _scrollController, // Attach ScrollController
                                  itemCount: leads.length +
                                      1, // Add one extra item for the loader
                                  itemBuilder: (context, index) {
                                    if (index < leads.length) {
                                      return GestureDetector(
                                        onTap: () {
                                          String leadId = leads[index]['id']!;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => FSAOSMRouteTracking(leadId: leadId,),
                                              ),
                                            );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border(
                                              top: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                              bottom: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                              left: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 5.0),
                                              right: BorderSide(
                                                  color: Color(0xFF640D78),
                                                  width: 1.0),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 15),
                                            leading: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  leads[index]['name']!
                                                      .toUpperCase(),
                                                  style: WidgetSupport.label(),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  leads[index]['phone']!,
                                                  style: WidgetSupport
                                                      .inputLabel(),
                                                ),
                                              ],
                                            ),
                                            trailing: Icon(
                                              Icons.chevron_right,
                                              color: Color(0xFF640D78),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Loader at the bottom
                                      return hasMoreData
                                          ? Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : Center(child: Text('No more data'));
                                    }
                                  },
                                ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Show Date Picker for From Date
  Future<void> _selectFromDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedFromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != selectedFromDate) {
      setState(() {
        selectedFromDate = pickedDate;
        _fromDate.text =
            getFormattedFromDate(selectedFromDate); // Update the text field
      });
    }
  }

// Show Date Picker for To Date
  Future<void> _selectToDate() async {
    DateTime? pickedDateTo = await showDatePicker(
      context: context,
      initialDate: selectedToDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDateTo != null && pickedDateTo != selectedToDate) {
      setState(() {
        selectedToDate = pickedDateTo;
        _toDate.text =
            getFormattedToDate(selectedToDate); // Update the text field
      });
    }
  }

  // Handle Refresh
}

class LeadDetailPage extends StatelessWidget {
  final String leadId;
  const LeadDetailPage({super.key, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lead Details"),
      ),
      body: Center(
        child: Text(
            'Lead ID: $leadId'), // Here you can fetch and display the lead details
      ),
    );
  }
}
