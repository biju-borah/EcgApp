import 'package:flutter/material.dart';

class LeadPage extends StatelessWidget {
  const LeadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead Configuration'),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Select a lead configuration:',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle lead 1 button press
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                ),
                child: const Text('Lead I'),
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle lead 2 button press
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                ),
                child: const Text('Lead II'),
              ),
            ),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Handle lead 3 button press
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.fromLTRB(36.0, 12.0, 36.0, 12.0),
                ),
                child: const Text('Lead III'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
