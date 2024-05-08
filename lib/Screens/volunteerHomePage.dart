import 'package:blindapp/Screens/VolunteerVideoCallPage.dart';
import 'package:flutter/material.dart';
import 'package:blindapp/Screens/loginPage.dart';

class VolunteerApp extends StatelessWidget {
  const VolunteerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VolunteerHomePage(),
    );
  }
}

class VolunteerHomePage extends StatelessWidget {
  const VolunteerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 100,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.person, size: 130),
            ),
            const SizedBox(height: 20),
            const Text(
              'Volunteer Now',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your chance to make a difference and help the community.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VolunteerVideoCallScreen(
                              isUser: false,
                            )));
              },
              style: ElevatedButton.styleFrom(fixedSize: const Size(250, 50)),
              child: const Text(
                'Go Online',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showLogoutConfirmationDialog(context);
              },
              style: ElevatedButton.styleFrom(fixedSize: const Size(250, 50)),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.blue,
                ),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Service',
          ),
        ],
      ),
    );
  }
}

void _showLogoutConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to logout?"),
        actions: <Widget>[
          TextButton(
            child: const Text("No"),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
            },
          ),
          TextButton(
            child: const Text("Yes"),
            onPressed: () {
              Navigator.of(context).pop(); // Dismiss the dialog
              _logoutAndRedirect(context);
            },
          ),
        ],
      );
    },
  );
}

void _logoutAndRedirect(BuildContext context) {
  // Perform logout logic here, e.g., clear user session

  // Navigate to the sign-in page
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => LoginPage()),
  );
}
