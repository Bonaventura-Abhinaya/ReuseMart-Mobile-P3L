import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../home/home_guest_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../detail/barang_detail_page.dart';

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

  String formatAngkaBiasa(dynamic angka) {
    final formatter = NumberFormat('#,###', 'id_ID');
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
        Uri.parse('${ApiService.baseUrl}/api/pembeli/update-fcm-token'),
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
      try {
        final profil = await ApiService.fetchProfilPembeli(userId);
        final notifs = await ApiService.fetchNotifikasiPembeli(userId);

        if (!mounted) return;

        setState(() {
          profilPembeli = profil;
          notifikasiFuture = Future.value(notifs);
        });

        await kirimFcmTokenKeLaravel(userId);
      } catch (e) {
        print("❌ ERROR saat loadData: $e");
        setState(() {
          notifikasiFuture = Future.value([]);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (notifikasiFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text("Dashboard Pembeli"),
        backgroundColor: Colors.green,
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
            // 🔔 Notifikasi di paling atas
            const Text("🔔 Notifikasi Terbaru", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(thickness: 1),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: notifikasiFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final notifs = snapshot.data ?? [];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: const Border(left: BorderSide(color: Colors.blue, width: 4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

            // 👤 Profil Pembeli
            if (profilPembeli == null) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
            ] else ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            Text(
                              profilPembeli!['username'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text("📧 ${profilPembeli!['email']}"),
                            Text("📞 ${profilPembeli!['no_telp'] ?? '-'}"),
                            Text("🏠 ${profilPembeli!['alamat_utama'] ?? 'Belum ada alamat'}"),
                            Text("🎁 ${formatAngkaBiasa(profilPembeli!['poin'])} poin"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profil"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on),
                    label: const Text("Kelola Alamat"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.history),
                    label: const Text("Riwayat Pembelian"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // 🛒 Barang Tersedia
            const Text("🛒 Barang Tersedia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Divider(thickness: 1),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: ApiService.fetchBarangTerbaru(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final barangList = snapshot.data ?? [];
                if (barangList.isEmpty) {
                  return const Text("Tidak ada barang tersedia.");
                }

                return Column(
                  children: [
                    ...barangList.map((barang) => Card(
                          child: ListTile(
                            leading: CachedNetworkImage(
                              imageUrl: barang['thumbnail'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                            title: Text(barang['nama']),
                            subtitle: Text(formatRupiah(barang['harga'])),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BarangDetailPage(id: barang['id']),
                                ),
                              );
                            },
                          ),
                        )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/barang-lainnya');
                        },
                        child: const Text("Lihat Semua Barang"),
                      ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}