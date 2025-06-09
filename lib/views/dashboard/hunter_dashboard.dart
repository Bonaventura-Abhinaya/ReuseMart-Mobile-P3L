import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../home/home_guest_page.dart';

class HunterDashboard extends StatefulWidget {
  const HunterDashboard({super.key});

  @override
  State<HunterDashboard> createState() => _HunterDashboardState();
}

class _HunterDashboardState extends State<HunterDashboard> {
  Map<String, dynamic>? profil;
  bool isLoading = true;

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
  }

  Future<void> kirimFcmTokenKeLaravel(int hunterId) async {
    final token = await FirebaseMessaging.instance.getToken();
    try {
      final response = await http.post(
        Uri.parse('http://192.168.115.68:8000/api/hunter/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: '{"id": $hunterId, "token": "$token"}',
      );
      print("✅ Kirim token respon: ${response.body}");
    } catch (e) {
      print("❌ Gagal kirim token: $e");
    }
  }

  Future<void> loadProfilHunter() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    try {
      final data = await ApiService.fetchProfilHunter(userId);
      setState(() {
        profil = data;
        isLoading = false;
      });

      await kirimFcmTokenKeLaravel(userId);
    } catch (e) {
      print("❌ Error load profil: $e");
      setState(() => isLoading = false);
    }
  }

  void _confirmLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeGuestPage()),
      (route) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    loadProfilHunter();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Hunter"),
        backgroundColor: Colors.teal,
        actions: [
          TextButton(
            onPressed: _confirmLogout,
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: profil == null
          ? const Center(child: Text("Profil tidak ditemukan"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Profil
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profil!['profile_picture'] != null
                            ? NetworkImage(profil!['profile_picture'])
                            : const AssetImage("assets/default-user.png") as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Nama: ${profil!['username']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("📧 Email: ${profil!['email']}"),
                            Text("📞 No. Telepon: ${profil!['no_telp'] ?? '-'}"),
                            Text("🎁 Saldo Komisi: ${formatRupiah(profil!['saldo'] ?? 0)}"),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 🔘 Aksi
                  Wrap(
                    spacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigasi ke edit profil
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: const Text("Edit Profil"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigasi ke laporan komisi atau transaksi
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Lihat Komisi"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigasi ke notifikasi hunter jika ada
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("Notifikasi"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
