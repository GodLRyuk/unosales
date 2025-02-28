import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/FSAModule/fsadashboard.dart';
import 'package:unosfa/pages/FSAModule/route_travel_by_agent.dart';
import 'package:unosfa/pages/generalscreens/profile.dart';
import 'package:unosfa/pages/generalscreens/setting.dart';
import 'package:unosfa/pages/FRModule/salesdashboard.dart';
import 'package:unosfa/pages/testfacelogin.dart';
import 'package:unosfa/pages/videoKyc.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  _NavigationPageState createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  int _selectedIndex = 2; // Default to Salesdashboard
  late PageController _pageController;
  String? _role; // Store the role from SharedPreferences

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
    _initializeRole(); // Initialize role asynchronously
  }

  Future<void> _initializeRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role'); // Retrieve role and update state
    });
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          ProfilePage(),
          AgentRouteTraveled(),
           if (_role == "FR") Salesdashboard(),
          if (_role == "FSA") Fsadashboard(),
            FaceRecognitionScreen(),
          VideoKyc(),
          SettingsPage(searchQuery: '',),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blueGrey,
        selectedItemColor: const Color(0xFFa604ad),
        unselectedItemColor: const Color.fromARGB(255, 110, 109, 110),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'PROFILE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'CALCULATOR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'NOTIFICATION',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'SETTING',
          ),
        ],
      ),
    );
  }
}
