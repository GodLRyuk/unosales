import 'package:flutter/material.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<String>? userInfo;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userInfo = prefs.getStringList('userInfo');
    });
  }

  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _logout(BuildContext context) async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: const Text("Do you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel logout
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Retrieve the values of the keys to retain
      bool? saveTourStatus = prefs.getBool("saveTour");
      bool? saveFRTourStatus = prefs.getBool("saveFRTour");
      bool? saveLeadDashboardTourStatus =
          prefs.getBool("saveLeadDashboardTour");
      bool? saveFRLeadDashboardTourStatus =
          prefs.getBool("saveFRLeadDashboardTour");

      // Get all keys and remove only those not in the excluded list
      for (String key in prefs.getKeys()) {
        if (key != "saveTour" &&
            key != "saveFRTour" &&
            key != "saveLeadDashboardTour" &&
            key != "saveFRLeadDashboardTour") {
          await prefs.remove(key);
        }
      }

      // Restore the retained values (if they were set before)
      if (saveTourStatus != null) {
        await prefs.setBool("saveTour", saveTourStatus);
      }
      if (saveFRTourStatus != null) {
        await prefs.setBool("saveFRTour", saveFRTourStatus);
      }
      if (saveLeadDashboardTourStatus != null) {
        await prefs.setBool(
            "saveLeadDashboardTour", saveLeadDashboardTourStatus);
      }
      if (saveFRLeadDashboardTourStatus != null) {
        await prefs.setBool(
            "saveFRLeadDashboardTour", saveFRLeadDashboardTourStatus);
      }

      // Navigate to the EntryPage and clear the navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const EntryPage()),
        (route) => false, // Clears the navigation stack
      );
    }
  }

  Widget _infoRow(
      {required IconData icon, required String label, String? value}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Text(label, style: WidgetSupport.labelText()),
            const Spacer(),
            Text(value ?? 'Not Available',
                style: WidgetSupport.personaldetailsText()),
          ],
        ),
        const Divider(
          color: Colors.grey,
          thickness: 1,
          height: 20,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    Image.asset(
                      'images/logo.PNG', // Path to your image
                      height: 30,
                    ),
                  ],
                ),
                SizedBox(width: 80),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => _logout(context), // Logout button
                    ),
                  ],
                ),
              ],
            ),
            centerTitle: true, // Center the title
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        border: Border.all(
                          color: Color(0xFF640D78),
                        )
                        // color: const Color(0xFF9a37ae),
                        ),
                    child: Row(
                      children: [
                        Image.asset(
                          "images/user.png",
                          width: 70,
                          height: 70,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${capitalize(userInfo?[1] ?? 'No First Name')} ${capitalize(userInfo?[2] ?? 'No Last Name')}',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                  "ID: ${userInfo?[0] != null ? '${userInfo![0]}' : 'Guest User'}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note_rounded),
                      onPressed: () {
                        // Add functionality for editing profile
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15.0),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF640D78),
                    )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Personal Information",
                        style: WidgetSupport.titleText()),
                    const SizedBox(height: 15),
                    _infoRow(
                        icon: Icons.location_on_outlined,
                        label: "Location",
                        value: "Kolkata, IN"),
                    _infoRow(
                        icon: Icons.card_giftcard_outlined,
                        label: "Birthdate",
                        value: "05/06/1993"),
                    _infoRow(
                        icon: Icons.phone_android_outlined,
                        label: "Phone Number",
                        value: "8670853699"),
                    _infoRow(
                        icon: Icons.info_outline_rounded,
                        label: "Help & Feedback"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
