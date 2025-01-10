import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unosfa/pages/generalscreens/customNavigation.dart';
import 'package:unosfa/pages/generalscreens/entrypage.dart';
import 'package:unosfa/widgetSupport/widgetstyle.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _brandingcontroller;
  late Animation<Offset> _unoAnimation;
  late Animation<Offset> _salesAnimation;
  late Animation<double> _brandingOpacity;

  @override
  void initState() {
    super.initState();

    // Animation Controller for Uno and Sales images
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Animation Controller for Branding
    _brandingcontroller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Uno slides in from the top
    _unoAnimation = Tween<Offset>(
      begin: const Offset(0.0, -8.0), // Start far above the screen
      end: Offset.zero, // Ends at its final position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Sales slides in from the bottom
    _salesAnimation = Tween<Offset>(
      begin: const Offset(0.0, 8.0), // Start far below the screen
      end: Offset.zero, // Ends at its final position
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Branding fades in
    _brandingOpacity = Tween<double>(
      begin: 0.0, // Fully transparent
      end: 1.0, // Fully visible
    ).animate(
        CurvedAnimation(parent: _brandingcontroller, curve: Curves.easeInOut));

    // Start animations
    _controller.forward();
    _brandingcontroller.forward();
    // Use Future.delayed to wait before navigating
    Future.delayed(const Duration(seconds: 3), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (BuildContext context) => NavigationPage()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (BuildContext context) => const EntryPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _brandingcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Row for animated Uno and Sales images
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Uno Image (slides from top)
                SlideTransition(
                  position: _unoAnimation,
                  child: Image.asset(
                    "images/Uno1.PNG",
                    width: MediaQuery.of(context).size.width * 0.4,
                  ),
                ),
                const SizedBox(width: 10),
                Transform.translate(
                  offset: Offset(
                    MediaQuery.of(context).size.width > 600
                        ? (MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            // Tablet in portrait orientation
                            ? -14
                            // Tablet in landscape orientation
                            : -97)
                        : (MediaQuery.of(context).orientation ==
                                Orientation.portrait
                            // Mobile in portrait orientation
                            ? -12
                            // Mobile in landscape orientation
                            : -16),
                    0, 
                  ),
                  child: SlideTransition(
                    position: _salesAnimation,
                    child: Image.asset(
                      "images/sales1.PNG",
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Branding with fade-in effect
            FadeTransition(
              opacity: _brandingOpacity,
              child: Column(
                children: [
                  Text(
                    "Powered by",
                    style: WidgetSupport.btandingText(),
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    "images/branding.png",
                    width: MediaQuery.of(context).size.width * 0.15,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
