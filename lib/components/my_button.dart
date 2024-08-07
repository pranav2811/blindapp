import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String buttonText;
  final Future<void> Function() onPressedAsync; // Add an onPressed parameter

  const MyButton(
      {super.key,
      required this.buttonText,
      required this.onPressedAsync}); // Include onPressed in the constructor

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          onPressedAsync();
        }, // Use the onPressed callback
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
              horizontal: 50, vertical: 10), // Adjust padding if needed
          backgroundColor: Colors.blue, // Background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Rounded corners
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
