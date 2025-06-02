import 'package:flutter/material.dart';

class HunterDashboard extends StatelessWidget {
  const HunterDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Hunter")),
      body: const Center(child: Text("Selamat datang, Hunter!")),
    );
  }
}
