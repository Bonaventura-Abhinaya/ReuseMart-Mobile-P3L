import 'package:flutter/material.dart';

class KurirDashboard extends StatelessWidget {
  const KurirDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Kurir")),
      body: const Center(child: Text("Selamat datang, Kurir!")),
    );
  }
}
