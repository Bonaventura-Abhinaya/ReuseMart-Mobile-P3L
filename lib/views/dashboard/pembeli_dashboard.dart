import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../home/home_guest_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class PembeliDashboard extends StatefulWidget {
  const PembeliDashboard({super.key});

  @override
  State<PembeliDashboard> createState() => _PembeliDashboardState();
}

class _PembeliDashboardState extends State<PembeliDashboard> {
  Future<List<Map<String, dynamic>>>? notifikasiFuture;
  Map<String, dynamic>? profilPembeli;

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();
    print('🔔 Notif permission: ${settings.authorizationStatus}');
  }

  Future<void> kirimFcmTokenKeLaravel(int pembeliId) async {
    final token = await FirebaseMessaging.instance.getToken();
    try {
      final response = await http.post(
        Uri.parse('http://192.168.115.68:8000/api/pembeli/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: '{"id": $pembeliId, "token": "$token"}',
      );
      print("✅ Kirim token respon: ${response.body}");
    } catch (e) {
      print("❌ Gagal kirim token: $e");
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah kamu yakin ingin logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeGuestPage()),
                (route) => false,
              );
            },
            child: const Text("Logout"),
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      final profil = await ApiService.fetchProfilPembeli(userId);
      setState(() {
        profilPembeli = profil;
        notifikasiFuture = ApiService.fetchNotifikasiPembeli(userId);
      });

      await kirimFcmTokenKeLaravel(userId);
    } else {
      setState(() {
        notifikasiFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notifikasiFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Pembeli"),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () => _confirmLogout(context),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Profil
            if (profilPembeli == null) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
            ] else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profilPembeli!['profile_picture'] != null
                        ? NetworkImage(profilPembeli!['profile_picture'])
                        : const AssetImage("assets/default-user.png") as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Nama: ${profilPembeli!['username']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Email: ${profilPembeli!['email']}"),
                        Text("No. Telepon: ${profilPembeli!['no_telp'] ?? '-'}"),
                        Text("Alamat Utama: ${profilPembeli!['alamat_utama'] ?? 'Belum ada alamat'}"),
                        Text("Poin: 🎁 ${profilPembeli!['poin'] ?? 0} poin"),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Navigasi ke halaman edit profil
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text("Edit Profil"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Navigasi ke halaman kelola alamat
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              child: const Text("Kelola Alamat"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Navigasi ke riwayat pembelian
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                              child: const Text("Riwayat Pembelian"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],

            // 🔔 Notifikasi
            FutureBuilder<List<Map<String, dynamic>>>(
              future: notifikasiFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifs = snapshot.data ?? [];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("🔔 Notifikasi Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          TextButton(
                            onPressed: () {
                              // TODO: Tandai semua sebagai sudah dibaca
                            },
                            child: const Text("Tandai semua dibaca", style: TextStyle(fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (notifs.isEmpty)
                        const Text("Tidak ada notifikasi baru.", style: TextStyle(color: Colors.grey)),
                      ...notifs.map((n) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(n['pesan']),
                            subtitle: Text(n['created_at']),
                          )),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
