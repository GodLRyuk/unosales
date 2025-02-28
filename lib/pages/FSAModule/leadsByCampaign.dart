import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/campaignlist.dart';
import 'package:unosfa/pages/FSAModule/singleCampaignlead.dart';
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'dart:async';

class LeadListByCampaign extends StatefulWidget {
  final String campaign;
  LeadListByCampaign({required this.campaign});

  @override
  State<LeadListByCampaign> createState() => _LeadListByCampaignState();
}

class _LeadListByCampaignState extends State<LeadListByCampaign> {
  List<Map<String, String>> leads = [];
  List<Map<String, String>> filteredLeads = [];
  String filterText = '';
  bool isLoading = true;
  bool areDateFieldsVisible =
      false; // Boolean to control visibility of date fields
  // DateTime? selectedFromDate;
  // DateTime? selectedToDate;
  final _scrollController = ScrollController();
  bool isFetchingMore = false;
  int currentPage = 1;
  bool hasMoreData = true;
  DateTime? startDate;
  DateTime? endDate;
  Duration totalDuration = Duration.zero;
  Duration timeLeft = Duration.zero;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    fetchLeads();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    String apiUrl = '${AppConfig.baseUrl}/api/campaigns/${widget.campaign}/leads';

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
                  'phone': item['mobile_phone']?.toString() ?? '',
                  'id': item['id']?.toString() ?? '',
                }));
          } else {
            leads = leadsData
                .map((item) => {
                      'name':
                          '${item['first_name'] ?? ''} ${item['middle_name'] ?? ''} ${item['last_name'] ?? ''}'
                              .trim(),
                      'phone': item['mobile_phone']?.toString() ?? '',
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
                    MaterialPageRoute(builder: (context) => Campaignlist()));
              },
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: Column(
                children: [
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
                                              builder: (context) => FSACampaignSingleLead(campaign: widget.campaign,leadId: leadId,),
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
                                                    horizontal: 0),
                                            leading: Column(
                                              children: [
                                                Image.asset(
                                                  'images/capmaignLeadslogo.PNG',
                                                  height: 55,
                                                  width: 60,
                                                ),
                                              ],
                                            ),
                                            title: Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        leads[index]['name']!
                                                            .toUpperCase(),
                                                        style: WidgetSupport
                                                            .CampaignName(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.mobile_friendly,
                                                        color:
                                                            Color(0xFF640D78),
                                                        size: 17,
                                                      ),
                                                      Text(
                                                        leads[index][
                                                                'phone']!
                                                            .toUpperCase(),
                                                        style: WidgetSupport
                                                            .campainDescription(),
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ),
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
}
