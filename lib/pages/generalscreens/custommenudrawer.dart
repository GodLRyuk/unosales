import 'package:flutter/material.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final String title;

  // Constructor to accept body content and title
  const CustomScaffold({
    required this.body,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'images/logo.PNG', // Path to your image
              height: 30,
              width: 70, // Adjust the height as needed
            ),
            SizedBox(width: 20),
          ],
        ),
        centerTitle: true,
        actions: [
          // Use Builder to get the correct context for Scaffold
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer(); // Open the end drawer
                },
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 150,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFFa604ad),
                ),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home,color: Color(0xFFa604ad),),
              title: Text('Home'),
              onTap: () {
                // Handle Option 1
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle,color: Color(0xFFa604ad),),
              title: Text('Profile'),
              onTap: () {
                // Handle Option 2
              },
            ),
            ListTile(
              leading: Icon(Icons.calculate,color: Color(0xFFa604ad),),
              title: Text('Calculator'),
              onTap: () {
                // Handle Option 2
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications,color: Color(0xFFa604ad),),
              title: Text('Notification'),
              onTap: () {
                // Handle Option 2
              },
            ),
            ListTile(
              leading: Icon(Icons.settings,color: Color(0xFFa604ad),),
              title: Text('Calculator'),
              onTap: () {
                // Handle Option 2
              },
            ),
          ],
        ),
      ),
      body: body, // This will render the passed body content
    );
  }
}
