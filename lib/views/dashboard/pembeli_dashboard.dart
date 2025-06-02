import 'package:flutter/material.dart';

class PembeliDashboard extends StatelessWidget {
  const PembeliDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Pembeli")),
      body: const Center(child: Text("Selamat datang, Pembeli!")),
    );
  }
}
