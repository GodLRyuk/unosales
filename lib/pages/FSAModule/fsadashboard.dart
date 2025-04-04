import 'dart:convert';
import 'package:circle_progress_bar/circle_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:unosfa/pages/FSAModule/assignedLeads.dart';
import 'package:unosfa/pages/FSAModule/campaignlist.dart';
import 'package:unosfa/pages/FSAModule/fsaleaddashboard.dart';
import 'package:unosfa/pages/services/in_app_storage.dart';
import 'package:unosfa/pages/services/in_app_tutorial_target.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:unosfa/pages/config/config.dart';
import 'package:unosfa/pages/FSAModule/mytodolist.dart';

class Fsadashboard extends StatefulWidget {
  const Fsadashboard({super.key});

  @override
  State<Fsadashboard> createState() => _FsadashboardState();
}

class _FsadashboardState extends State<Fsadashboard> {
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  List<String>? userInfo;
  int leadDetails = 0;
  final TextEditingController searchController = TextEditingController();
  bool tokenisLoading = false;
  bool areDateFieldsVisible = false;
  final _searchFilter = TextEditingController();
  String? role;

  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TutorialCoachMark tutorialCoachMark;
  final CreateLeadKey = GlobalKey();
  final AssignedLeadsKey = GlobalKey();
  final MyToDoListKey = GlobalKey();
  final CampaignKey = GlobalKey();
  final RewardsKey = GlobalKey();
  final TrainingKey = GlobalKey();
  final SearchFilterKey = GlobalKey();
  final TotalSubmitedKey = GlobalKey();
  final InProgressKey = GlobalKey();
  final InPrincipalApprovedKey = GlobalKey();
  final FinalApprovedKey = GlobalKey();
  final DeclinedKey = GlobalKey();
  final DisbursedKey = GlobalKey();
  int totalSubmited = 0;
  int inProgress = 0;
  int inPrincipalApproved = 0;
  int finalApproved = 0;
  int declined = 0;
  int disbursed = 0;

  @override
  void initState() {
    _loadData();
    _showInAppTour();
    _loadLOSData();
    super.initState();
    // _checkFirstTimeUser();
    _initAddAppInAppTour();
  }

  void _initAddAppInAppTour() {
    tutorialCoachMark = TutorialCoachMark(
      targets: addAppTargets(
        CreateLeadKey: CreateLeadKey,
        AssignedLeadsKey: AssignedLeadsKey,
        MyToDoListKey: MyToDoListKey,
        CampaignKey: CampaignKey,
        RewardsKey: RewardsKey,
        TrainingKey: TrainingKey,
        SearchFilterKey: SearchFilterKey,
        TotalSubmitedKey: TotalSubmitedKey,
        InProgressKey: InProgressKey,
        InPrincipalApprovedKey: InPrincipalApprovedKey,
        FinalApprovedKey: FinalApprovedKey,
        DeclinedKey: DeclinedKey,
        DisbursedKey: DisbursedKey,
      ),
      colorShadow: Color(0xFF420244),
      paddingFocus: 10,
      hideSkip: false,
      textStyleSkip: TextStyle(
          fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
      skipWidget: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Skip",
          style: TextStyle(
            fontSize: 18,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      opacityShadow: 0.8,
      onFinish: () {
        SaveInAppTour().savedAppTourStatus();
      },
    );
  }

  void _showInAppTour() {
    Future.delayed(const Duration(seconds: 0), () {
      SaveInAppTour().getAppTourStatus().then((value) {
        if (value == false) {
          tutorialCoachMark.show(context: context);
        } else {
          print("User have seen this page");
        }
      });
    });
  }

  Future<void> _loadLOSData() async {
    String token = "";
    final tokenUrl =
        Uri.parse('${AppConfig.baseUrl}/api/leads/los-access-token/');
    try {
      final Tokenresponse = await http.get(tokenUrl);
      final data = json.decode(Tokenresponse.body);
      token = data['access_token'];
    } catch (e) {
      print("HTTP Request Failed: $e");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    userInfo = prefs.getStringList('userInfo');

    Map<String, String> mappedData = {
      'mobileNo': "",
      'agentCode': userInfo![0],
      'applicationNo': "",
      'last_name': ""
    };
    final url = Uri.parse(
        "https://unoapi.uat.ph.unobank.asia/api/app/fetch/application/status");

    final headers = {
      "Idempotency-Key": "jbkjdbjkjk",
      "Authorization": "Bearer $token",
    };
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: mappedData,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> losData = data['result'] ?? [];
        setState(() {
          totalSubmited =data['result'].length;
        inProgress = losData
            .where((item) =>
                item['offerStatus'] == 'IN-PROGRESS' &&
                item['uwStatus'] == 'IN-PROGRESS')
            .length;
        inPrincipalApproved = losData
            .where((item) =>
                item['offerStatus'] == 'PRE-QUALIFIED' &&
                item['uwStatus'] == 'Pass')
            .length;
        finalApproved = losData
            .where((item) =>
                item['offerStatus'] == 'Pass' && item['uwStatus'] == 'Pass')
            .length;
        declined = losData
            .where((item) =>
                item['offerStatus'] == 'Cancel' && item['uwStatus'] == 'Cancel' ||
                item['offerStatus'] == 'Fail' && item['uwStatus'] == 'Fail' ||
                item['Dedupe'] == 'Fail' && item['uwStatus'] == 'Fail' ||
                item['Dedupe'] == 'Fail' && item['uwStatus'] == 'Fail')
            .length;
            print(declined);
        disbursed = losData
            .where((item) =>
                item['offerStatus'] == 'Availed' && item['uwStatus'] == 'Pass')
            .length;
        });
      }
    } catch (e) {}
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('accessToken');
    String? refresh = prefs.getString('refreshToken');
    role = prefs.getString('role');
    if (mounted) {
      setState(() {
        userInfo = prefs.getStringList('userInfo');
      });
    }
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/leads/?ordering=-created_at'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      String apiUrl =
          '${AppConfig.baseUrl}/api/leads/company-leads/?ordering=-created_at';
      final response2 = await http.get(
        Uri.parse(apiUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> data2 = json.decode(response2.body);

        if (mounted) {
          setState(() {
            leadDetails = (data['count'] ?? 0) + (data2['count'] ?? 0);
          });
        }
      } else if (response.statusCode == 401) {
        if (refresh != null) {
          Map<String, dynamic> mappedData = {'refresh': refresh};

          final response2 = await http.post(
            Uri.parse('${AppConfig.baseUrl}/api/users/token-refresh/'),
            body: jsonEncode(mappedData),
            headers: {'Content-Type': 'application/json'},
          );

          if (response2.statusCode == 200) {
            final data = json.decode(response2.body);
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('accessToken', data['access']);
            await prefs.setString('refreshToken', data['refresh']);
            _loadData();
          } else {}
        } else {}
      }
    } catch (e) {
      print('❌ Error fetching lead details: $e');
    }
  }

  String? selectedLeadType; // Initially null or set a default value.

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Close the app when the back button is pressed
        SystemNavigator.pop();
        return false; // Prevents navigation back
      },
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh, // Function to handle refresh logic
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.94,
                ),
                child: IntrinsicHeight(
                  child: _buildColumn(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Define the refresh logic
  Future<void> _handleRefresh() async {
    _loadData();
    _loadLOSData();
    // Add the logic for refresh (e.g., fetching new data)
    await Future.delayed(Duration(seconds: 2)); // Simulate a delay
  }

  Widget _buildColumn() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopContainer(),
          SizedBox(
            height: MediaQuery.of(context).size.width > 600
                ? MediaQuery.of(context).size.height * 0.03
                : MediaQuery.of(context).size.height * 0.02,
          ),
          _buildMidContainerWithButton(),
          _smallBoxLeadDetailsContainer(),
          _smallBoxSecondContainer(),
          _smallBoxThirdContainer(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          _perfomanceContainer(),
        ],
      );

  Widget _buildTopContainer() => Flexible(
        flex: 1,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                Image.asset(
                  "images/logo.PNG",
                  // width: MediaQuery.of(context).size.width > 600 ? 400 : 200,
                  height: MediaQuery.of(context).size.width > 600 ? 70 : 40,
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width > 600 ? 10 : 0),
                Text(
                  '${capitalize(userInfo?[1] ?? 'No First Name')} ${capitalize(userInfo?[2] ?? 'No Last Name')} (${userInfo?[0] != null ? '${userInfo![0]}' : 'Guest ID'}) (${role})',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width > 600 ? 30 : 0),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TextField for phone number filter
                      TextField(
                        controller: _searchFilter,
                        key: SearchFilterKey,
                        decoration: InputDecoration(
                          labelText: 'Filter By Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(0),
                            borderSide: const BorderSide(
                              color: Color(0xFFac00d0),
                              width: 1.0,
                            ),
                          ),
                          suffixIcon: Container(
                            color: const Color(0xFFac00d0),
                            child: IconButton(
                              onPressed: () {
                                // ✅ Fixed Syntax
                                final String searchData = _searchFilter.text;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FsaLeadDashBoard(
                                        searchQuery: searchData),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.filter_list,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        style: const TextStyle(height: 1),
                        // onChanged: _filterLeads, // Uncomment if needed
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildMidContainerWithButton() {
    const buttonHeight = 30.0;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    double containerHeight = isLandscape
        ? screenHeight * 0.40 // Adjusted height for landscape
        : screenHeight > 600
            ? screenHeight * 0.22 // Portrait - tablet
            : screenHeight * 0.26; // Portrait - mobile

    double containerHeight3 = isLandscape
        ? screenHeight * 0.40 // Adjusted height for landscape
        : screenHeight > 600
            ? screenHeight * 0.25 // Portrait - tablet
            : screenHeight * 0.26; // Portrait - mobile

    double containerWidth = isLandscape
        ? screenWidth * 0.99 // Adjusted width for landscape
        : screenWidth > 600
            ? screenWidth * 0.98 // Portrait - tablet
            : screenWidth * 0.93; // Portrait - mobile

    double containerHeight2 = isLandscape
        ? screenHeight * 0.08 // Adjusted height for landscape
        : screenHeight > 600
            ? screenHeight * 0.04 // Portrait - tablet
            : screenHeight * 0.03; // Portrait - mobile

    double containerWidth2 = isLandscape
        ? screenWidth * 0.06 // Adjusted width for landscape
        : screenWidth > 600
            ? screenWidth * 0.08 // Portrait - tablet
            : screenWidth * 0.08; // Portrait - mobile;
    // Portrait - mobile

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          Container(
            width: containerWidth,
            height: MediaQuery.of(context).size.width > 600
                ? containerHeight
                : containerHeight3,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                  Color(0xFFb600da),
                  Color(0xFF6c0481),
                ])),
            child: Padding(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.width > 600 ? 38 : 30,
                  bottom: 1),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          key: TotalSubmitedKey,
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align text to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        FaIcon(
                                          Icons.task,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              "Total\n Submitted",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600 // Tablet detection
                                              ? MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.09 // Landscape for tablet
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.09 // Portrait for tablet
                                              : MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.07 // Landscape for mobile
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.09, // Portrait for mobile
                                        ),
                                        Container(
                                          height: containerHeight2,
                                          width:
                                              containerWidth2, // Set width as needed
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Replace with your desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional: rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${totalSubmited}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab() // Use a different style for tablets
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 3,
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align column to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  key: InProgressKey,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        // Container for the icon and text
                                        FaIcon(
                                          Icons.hourglass_empty,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        // Column for the text
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              " In-Progress",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600 // Tablet detection
                                              ? MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.07 // Landscape for tablet
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.07 // Portrait for tablet
                                              : MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.08 // Landscape for mobile
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.05, // Portrait for mobile
                                        ),
                                        Container(
                                          height: containerHeight2,
                                          width: containerWidth2,
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Replace with your desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional: rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${inProgress}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab()
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          key: InPrincipalApprovedKey,
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align text to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        FaIcon(
                                          Icons.check_box,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              "In-Principal \nApproved",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600 // Tablet detection
                                              ? MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.08 // Landscape for tablet
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.08 // Portrait for tablet
                                              : MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.0 // Landscape for mobile
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.07, // Portrait for mobile
                                        ),
                                        Container(
                                          height: containerHeight2,
                                          width: containerWidth2,
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Replace with your desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional: rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${inPrincipalApproved}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab()
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 3,
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align text to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  key: FinalApprovedKey,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        FaIcon(
                                          Icons.verified,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              " Final \n Approved",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.09),
                                        Container(
                                          height: containerHeight2,
                                          width: containerWidth2,
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Replace with your desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional: rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${finalApproved}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab()
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align text to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  key: DeclinedKey,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        // Container for the icon with centered content
                                        FaIcon(
                                          Icons.cancel,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              "Declined",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600 // Tablet detection
                                              ? MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.10 // Landscape for tablet
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.11
                                              // Portrait for tablet
                                              : MediaQuery.of(context)
                                                          .orientation ==
                                                      Orientation.landscape
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.08 // Landscape for mobile
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.12, // Portrait for mobile
                                        ),
                                        Container(
                                          height: containerHeight2,
                                          width: containerWidth2,
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${declined}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab()
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          width: 3,
                        ),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align column to start
                          children: [
                            Row(
                              children: [
                                Column(
                                  key: DisbursedKey,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // Align text to start
                                  children: [
                                    Row(
                                      children: [
                                        // Container for the icon with centered content
                                        FaIcon(
                                          Icons.done_all,
                                          size: MediaQuery.of(context)
                                                      .size
                                                      .width >
                                                  600
                                              ? 50
                                              : 30,
                                          color: Colors.white,
                                        ),
                                        // Column for the text
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start, // Align text to start
                                          children: [
                                            Text(
                                              " Disbursed",
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .normalTextTab()
                                                  : WidgetSupport.normalText(),
                                            ),
                                          ],
                                        ),
                                        // SizedBox for spacing between the text and the next container
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.08,
                                        ),
                                        // Container for the percentage text with background
                                        Container(
                                          height: containerHeight2,
                                          width: containerWidth2,
                                          decoration: BoxDecoration(
                                            color: Color(
                                                0xFF640D78), // Replace with your desired background color
                                            borderRadius: BorderRadius.circular(
                                                5.0), // Optional: rounded corners
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${disbursed}', // Example percentage text
                                              style: MediaQuery.of(context)
                                                          .size
                                                          .width >
                                                      600
                                                  ? WidgetSupport
                                                      .progressBarInnerTextTab()
                                                  : WidgetSupport
                                                      .progressBarInnerText(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0.0, -buttonHeight / 1.50),
            child: Center(
              child: GestureDetector(
                onTap: () {/* do stuff */},
                child: Container(
                  height: MediaQuery.of(context).size.width > 600 ? 40 : 33,
                  width: MediaQuery.of(context).size.width > 600 ? 300 : 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(buttonHeight / 0.0),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 50.0,
                        offset: const Offset(0.0, 6.0),
                        color: Colors.black.withOpacity(0.16),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(24.0, 3.0, 24.0, 3.0),
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width > 600
                                ? 50.0
                                : 20),
                        child: Text(
                          'LEAD DASHBOARD',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 17
                                : 14.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF093a89),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBoxLeadDetailsContainer() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    double containerHeight = screenWidth > 600
        ? (isLandscape ? screenHeight * 0.08 : screenHeight * 0.05)
        : (isLandscape ? screenHeight * 0.07 : screenHeight * 0.05);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FsaLeadDashBoard(
                            searchQuery: '',
                          )));
            },
            child: Column(
              children: [
                SizedBox(
                  child: Container(
                    width: screenWidth * 0.43,
                    height: containerHeight,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FaIcon(
                          Icons.handshake,
                          size:
                              MediaQuery.of(context).size.width > 600 ? 40 : 20,
                          color: Colors.purple,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "Create New Lead",
                          style: MediaQuery.of(context).size.width > 600
                              ? WidgetSupport.normalblackTextTab()
                              : WidgetSupport.normalblackText(),
                          key: CreateLeadKey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // My Leads Box - triggers Tooltip for Training
          GestureDetector(
            onTap: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AssignedLeads(
                            searchQuery: '',
                          )));
            },
            child: Column(
              children: [
                SizedBox(
                  child: Container(
                    width: screenWidth * 0.43,
                    //height: containerHeight,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.start, // Center horizontally
                      crossAxisAlignment:
                          CrossAxisAlignment.center, // Center vertically
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                        ),
                        FaIcon(
                          FontAwesomeIcons.handshake,
                          size:
                              MediaQuery.of(context).size.width > 600 ? 40 : 20,
                          color: Colors.orange,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "Assigned Leads",
                          style: MediaQuery.of(context).size.width > 600
                              ? WidgetSupport.normalblackTextTab()
                              : WidgetSupport.normalblackText(),
                          key: AssignedLeadsKey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBoxSecondContainer() {
    double screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              // Trigger the tooltip on tap
              _tooltipKey.currentState?.ensureTooltipVisible();
            },
            child: Tooltip(
              key: _tooltipKey,
              message: 'Coming Soon',
              decoration: BoxDecoration(
                color: Color(
                    0xFFa604ad), // Set the background color of the tooltip
                borderRadius:
                    BorderRadius.circular(5), // Optional: rounded corners
              ),
              child: Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.43,
                      //height: containerHeight,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.trophy,
                            size: MediaQuery.of(context).size.width > 600
                                ? 40
                                : 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Rewards",
                            style: MediaQuery.of(context).size.width > 600
                                ? WidgetSupport.normalblackTextTab()
                                : WidgetSupport.normalblackText(),
                            key: RewardsKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // My Leads Box - triggers Tooltip for Training
          GestureDetector(
            onTap: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => FSAMyTodoList(
                            searchQuery: '',
                          )));
            },
            // onTap: () {
            //   _ToDotooltipKey.currentState?.ensureTooltipVisible();
            // },
            child: Tooltip(
              key: _ToDotooltipKey,
              message: 'Coming Soon',
              decoration: BoxDecoration(
                color: Color(
                    0xFFa604ad), // Set the background color of the tooltip
                borderRadius:
                    BorderRadius.circular(5), // Optional: rounded corners
              ),
              child: Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: screenWidth * 0.43,
                      // height: screenHeight * 0.07,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.grey[300]!,
                        //     spreadRadius: 2,
                        //     blurRadius: 2,
                        //     offset: const Offset(0, 1),
                        //   ),
                        // ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // Center horizontally
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Center vertically
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                          ),
                          FaIcon(
                            FontAwesomeIcons.listCheck,
                            size: MediaQuery.of(context).size.width > 600
                                ? 40
                                : 20,
                            color: Colors.green,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "My To-Do List",
                            style: MediaQuery.of(context).size.width > 600
                                ? WidgetSupport.normalblackTextTab()
                                : WidgetSupport.normalblackText(),
                            key: MyToDoListKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  final GlobalKey<TooltipState> _ToDotooltipKey = GlobalKey<TooltipState>();
  final GlobalKey<TooltipState> _TrainingtooltipKey = GlobalKey<TooltipState>();
  final GlobalKey<TooltipState> _CampaigntooltipKey = GlobalKey<TooltipState>();
  Widget _smallBoxThirdContainer() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    double containerHeight = screenWidth > 600
        ? (isLandscape ? screenHeight * 0.08 : screenHeight * 0.05)
        : (isLandscape ? screenHeight * 0.07 : screenHeight * 0.05);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () async {
              _TrainingtooltipKey.currentState?.ensureTooltipVisible();
            },
            child: Tooltip(
              key: _TrainingtooltipKey,
              message: 'Coming Soon',
              decoration: BoxDecoration(
                color: Color(
                    0xFFa604ad), // Set the background color of the tooltip
                borderRadius:
                    BorderRadius.circular(5), // Optional: rounded corners
              ),
              child: Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: screenWidth * 0.43,
                      height: containerHeight,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.grey[300]!,
                        //     spreadRadius: 2,
                        //     blurRadius: 2,
                        //     offset: const Offset(0, 1),
                        //   ),
                        // ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FaIcon(
                            FontAwesomeIcons.laptopCode,
                            size: MediaQuery.of(context).size.width > 600
                                ? 40
                                : 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Training",
                            style: MediaQuery.of(context).size.width > 600
                                ? WidgetSupport.normalblackTextTab()
                                : WidgetSupport.normalblackText(),
                            key: TrainingKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // My Leads Box - triggers Tooltip for Training
          GestureDetector(
            onTap: () async {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Campaignlist()));
            },
            // onTap: () async {
            //   _CampaigntooltipKey.currentState?.ensureTooltipVisible();
            // },
            child: Tooltip(
              key: _CampaigntooltipKey,
              message: 'Coming Soon',
              decoration: BoxDecoration(
                color: Color(
                    0xFFa604ad), // Set the background color of the tooltip
                borderRadius:
                    BorderRadius.circular(5), // Optional: rounded corners
              ),
              child: Column(
                children: [
                  SizedBox(
                    child: Container(
                      width: screenWidth * 0.43,
                      //height: screenHeight * 0.07,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        // boxShadow: [
                        //   BoxShadow(
                        //     color: Colors.grey[300]!,
                        //     spreadRadius: 2,
                        //     blurRadius: 2,
                        //     offset: const Offset(0, 1),
                        //   ),
                        // ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.start, // Center horizontally
                        crossAxisAlignment:
                            CrossAxisAlignment.center, // Center vertically
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                          ),
                          FaIcon(
                            FontAwesomeIcons.bullhorn,
                            size: MediaQuery.of(context).size.width > 600
                                ? 40
                                : 20,
                            color: Colors.green,
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Text(
                            "Campaign",
                            style: MediaQuery.of(context).size.width > 600
                                ? WidgetSupport.normalblackTextTab()
                                : WidgetSupport.normalblackText(),
                            key: CampaignKey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfomanceContainer() {
    const buttonHeight = 30.0;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

    // Determine if the device is a tablet or mobile
    bool isTablet = screenWidth > 600;

    // Adjust container width and height for tablet/mobile based on orientation
    double containerWidth = isTablet
        ? (orientation == Orientation.portrait
            ? screenWidth * 0.99
            // Tablet Portrait
            : screenWidth * 0.99) // Tablet Landscape
        : (orientation == Orientation.portrait
            ? screenWidth * 0.95 // Mobile Portrait
            : screenWidth * 0.90); // Mobile Landscape

    double containerHeight = isTablet
        ? (orientation == Orientation.portrait
            ? screenHeight * 0.30 // Tablet Portrait
            : screenHeight * 0.4) // Tablet Landscape
        : (orientation == Orientation.portrait
            ? screenHeight * 0.20 // Mobile Portrait
            : screenHeight * 0.25); // Mobile Landscape

    // Adjust performance meter dimensions for tablet/mobile based on orientation
    double perfomanceMeaterHeight = isTablet
        ? (orientation == Orientation.portrait
            ? screenHeight * 0.3 // Tablet Portrait
            : screenHeight * 0.3) // Tablet Landscape
        : (orientation == Orientation.portrait
            ? screenHeight * 0.15 // Mobile Portrait
            : screenHeight * 0.2); // Mobile Landscape

    double perfomanceMeaterWidth = isTablet
        ? (orientation == Orientation.portrait
            ? screenWidth * 0.35 // Tablet Portrait
            : screenWidth * 0.3) // Tablet Landscape
        : (orientation == Orientation.portrait
            ? screenWidth * 0.4 // Mobile Portrait
            : screenWidth * 0.5); // Mobile Landscape

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Stack(
        children: [
          Container(
            height: containerHeight,
            width: containerWidth,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF720487),
                  Color(0xFF462eaa),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: Stack(
                children: [
                  // Bottom-left green box and "test" text
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10.0, // Small green box width
                            height: 10.0, // Small green box height
                            color: Colors.green,
                          ),
                          const SizedBox(
                              width: 5), // Space between box and text
                          Text(
                            "SALES PERFOMANCE",
                            style: WidgetSupport.normalText(),
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width >
                                    600 // Tablet detection
                                ? MediaQuery.of(context).orientation ==
                                        Orientation.landscape
                                    ? MediaQuery.of(context).size.width *
                                        0.76 // Landscape for tablet
                                    : MediaQuery.of(context).size.width *
                                        0.60 // Portrait for tablet
                                : MediaQuery.of(context).orientation ==
                                        Orientation.landscape
                                    ? MediaQuery.of(context).size.width *
                                        0.08 // Landscape for mobile
                                    : MediaQuery.of(context).size.width *
                                        0.23, // Portrait for mobile
                          ),
                          Container(
                            width: 10.0, // Small green box width
                            height: 10.0, // Small green box height
                            color: Colors.white,
                          ),
                          const SizedBox(
                              width: 5), // Space between box and text
                          Text(
                            "MILESTONE",
                            style: WidgetSupport.normalText(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Centered CircleProgressBar
                  Center(
                    child: SizedBox(
                      width: perfomanceMeaterWidth,
                      height: perfomanceMeaterHeight,
                      child: CircleProgressBar(
                        foregroundColor: Colors.lightGreen,
                        backgroundColor: Colors.black12,
                        value: 0.7,
                        child: Center(
                          child: Text(
                            '\u20B1 180,000',
                            style: MediaQuery.of(context).size.width > 600
                                ? WidgetSupport.perfomanceBarInnerTextTab()
                                : WidgetSupport.perfomanceBarInnerText(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0.0, -buttonHeight / 1.50),
            child: Center(
              child: GestureDetector(
                onTap: () {/* do stuff */},
                child: Container(
                  height: MediaQuery.of(context).size.width > 600 ? 40 : 33,
                  width: MediaQuery.of(context).size.width > 600 ? 300 : 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(buttonHeight / 0.0),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16.0,
                        offset: const Offset(0.0, 6.0),
                        color: Colors.black.withOpacity(0.16),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(
                      left:
                          MediaQuery.of(context).size.width > 600 ? 80.0 : 40),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          'PERFORMANCE',
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 17
                                : 14.0,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF093a89),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
