import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'komisi_history_page.dart.dart';
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
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: profil == null
          ? const Center(child: Text("Profil tidak ditemukan"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dashboard Hunter",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 👤 Profil Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: profil!['profile_picture'] != null
                                ? NetworkImage(profil!['profile_picture'])
                                : const AssetImage("assets/default-user.png") as ImageProvider,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Username: ${profil!['username']}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.email, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Email: ${profil!['email']}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "No. Telepon: ${profil!['no_telp'] ?? '-'}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Jumlah Komisi: ${formatRupiah(profil!['saldo'] ?? 0)}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🔘 Action Buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Navigasi ke edit profil
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text(
                              "Edit Profil",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Di dalam HunterDashboard
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const KomisiHistoryPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.attach_money, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Lihat History Komisi",
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}