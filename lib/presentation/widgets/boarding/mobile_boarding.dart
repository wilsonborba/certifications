

import 'package:flutter/material.dart';
import 'package:lazycopy/core/utils/my_background.dart';


class MobileBoarding extends StatefulWidget {
  
  const MobileBoarding({super.key});

  @override
  State<MobileBoarding> createState() => _MobileBoardingState();
}

class _MobileBoardingState extends State<MobileBoarding> {
  Color _buttonColor = Colors.black87;

  @override
  Widget build(BuildContext context) {
    // Implement the mobile landing screen UI here
    return Scaffold(

      body: Stack(
          children: [
            // BACKGROUND (under everything)
            const Positioned.fill(
              child: LiquidMetalBackground(
                blobCount: 10,
                blurSigma: 22,        // ≈ “70% blur” feel
                centerFocusRadius: .42, // crisper center (0..1 of shortest side)
                speed: 28,            // px/sec nominal speed
              ),
            ), Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text('Welcome to Accredit', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold)),
            SizedBox(height: 30),
               ElevatedButton.icon(
              
              icon: const Icon(Icons.add),
              onPressed: () {
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 50),
                backgroundColor: _buttonColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  
                ),
              ),
              onHover: (isHovered) {
                // Change the button color on hover
                setState(() {
                  _buttonColor = isHovered ? Colors.black38 : Colors.black87;
                });
              },
              label: Text('New Certification'),
            ),
          ],
        ),
      )]) 
    );
  }
}
