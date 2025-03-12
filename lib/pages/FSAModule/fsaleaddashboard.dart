import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsacreatcompantlead.dart';
import 'package:unosfa/pages/FSAModule/fsacreatenewlead.dart';
import 'package:unosfa/pages/FSAModule/fsacustomersingleleaddetail.dart';
import 'package:unosfa/pages/FSAModule/fsasingleleaddetail.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:unosfa/pages/config/config.dart';
class FsaLeadDashBoard extends StatefulWidget {
  final String searchQuery;
  const FsaLeadDashBoard({super.key, required this.searchQuery});

  @override
  State<FsaLeadDashBoard> createState() => _FsaLeadDashBoardState();
}

class _FsaLeadDashBoardState extends State<FsaLeadDashBoard> {
  final _searchFilter = TextEditingController();
  final _toDate = TextEditingController();
  final _fromDate = TextEditingController();
  final _scrollController = ScrollController(); // Scroll controller
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  bool isLoading = true;
  bool isFetchingMore = false; // Loader for lazy loading
  int currentPage = 1; // Pagination page
  bool hasMoreData = true; // Flag to check if more data is available
  bool areDateFieldsVisible =
      false; // Boolean to control visibility of date fields
  DateTime? selectedFromDate;
  DateTime? selectedToDate;
  bool isExpanded = false;
  @override
  void initState() {
    super.initState();
    fetchLeads(); // Fetch initial data
    _scrollController.addListener(_onScroll); // Attach scroll listener
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose the scroll controller
    super.dispose();
  }

  // Fetch leads from API
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

    // Define API URLs
    String apiUrl1 =
        '${AppConfig.baseUrl}/api/leads/?search=${widget.searchQuery}&ordering=-created_at&page=$currentPage';
    String apiUrl2 =
        '${AppConfig.baseUrl}/api/leads/company-leads/?search=${widget.searchQuery}&ordering=-created_at';

    try {
      // Fetch data from both APIs concurrently
      final responses = await Future.wait([
        http.get(Uri.parse(apiUrl1),
            headers: {'Authorization': 'Bearer $token'}),
        http.get(Uri.parse(apiUrl2),
            headers: {'Authorization': 'Bearer $token'}),
      ]);

      List<Map<String, String>> allLeadsData = [];

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];

        if (response.statusCode == 200) {
          Map<String, dynamic> data = json.decode(response.body);
          List<dynamic> leadsData = data['results'] ?? [];

          if (i == 0) {
            // Processing Customer Leads (`/api/leads/`)
            allLeadsData.addAll(leadsData.map((item) => {
                  'name':
                      '${(item['first_name'] ?? '')} ${(item['middle_name'] ?? '')} ${(item['last_name'] ?? '')}'
                          .trim(),
                  'phone': (item['phone_number'] ?? '').toString(),
                  'id': (item['id'] ?? '').toString(),
                  'type': 'Customer Lead', // Identifies as a customer lead
                }));

            // Check if there's more data (only for the paginated API)
            hasMoreData = data['next'] != null;
          } else {
            // Processing Company Leads (`/api/leads/company-leads/`)
            allLeadsData.addAll(leadsData.map((item) => {
                  'name':
                      (item['company_name'] ?? 'Unknown Company').toString(),
                  'phone': (item['contact_person_mobile_no'] ?? '').toString(),
                  'id': (item['id'] ?? '').toString(),
                  'type': 'Company Lead', // Identifies as a company lead
                }));
          }
        } else {
          throw Exception('Failed to load leads from API ${i + 1}');
        }
      }

      // Update state
      setState(() {
        if (isLoadMore) {
          leads.addAll(allLeadsData);
        } else {
          leads = allLeadsData;
        }

        filteredLeads = List.from(leads);
        isLoading = false;
        isFetchingMore = false;
      });
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

  // Method to filter leads by phone number
  // void _filterLeads(String query) {
  //   setState(() {
  //     filterText = query;
  //     if (query.isEmpty) {
  //       filteredLeads = List.from(leads);
  //     } else {
  //       filteredLeads =
  //           leads.where((lead) => lead['phone']!.contains(query)).toList();
  //     }
  //   });
  // }

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
                                          if (leads[index]['type'] ==
                                              'Customer Lead') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CustomerSingleLead(leadId: leadId,),
                                              ),
                                            );
                                          }else
                                          {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FsaCompanySingleLead(
                                                        leadId: leadId),
                                              ),
                                            );
                                          }
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
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 20, right: 10),
                                                  width: 100,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: (leads[index]
                                                                ['type'] ==
                                                            'Customer Lead')
                                                        ? Color(0xFFc433e0)
                                                        : Color(0xFF640D78),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        leads[index]['type'] ??
                                                            '',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    String leadId =
                                                        leads[index]['id']!;
                                                    if (leads[index]['type'] ==
                                                        'Customer Lead') {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              FsaLeadGenerate(
                                                                  edit: leadId),
                                                        ),
                                                      );
                                                    } else {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              FsaCompanyLeadGenerate(
                                                                  edit: leadId),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Icon(
                                                    Icons.edit,
                                                    color: Color(0xFF640D78),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Icon(
                                                  Icons.chevron_right,
                                                  color: Color(0xFF640D78),
                                                ),
                                              ],
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10), // Adjust padding as needed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExpanded) ...[
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Customer Lead",
                          style: WidgetSupport.LoginButtonTextColor()),
                      SizedBox(width: 10),
                      FloatingActionButton(
                        heroTag: "btn1",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FsaLeadGenerate(edit: ''),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Floating Button with Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("Company Lead",
                          style: WidgetSupport.LoginButtonTextColor()),
                      SizedBox(width: 10),
                      FloatingActionButton(
                        heroTag: "btn2",
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FsaCompanyLeadGenerate(
                                edit: '',
                              ),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ],

            // Main Button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue,
                        Colors.purple
                      ], // Define your gradient colors
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    child: Icon(
                      isExpanded ? Icons.close : Icons.add,
                      color: Colors.white,
                    ),
                    backgroundColor: Colors
                        .transparent, // Set transparent so gradient is visible
                  ),
                ),
              ],
            )
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
