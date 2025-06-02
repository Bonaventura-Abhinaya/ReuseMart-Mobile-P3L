import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../home/home_guest_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class PenitipDashboard extends StatefulWidget {
  const PenitipDashboard({super.key});

  @override
  State<PenitipDashboard> createState() => _PenitipDashboardState();
}

class _PenitipDashboardState extends State<PenitipDashboard> {
  Future<List<Map<String, dynamic>>>? barangAktifFuture;
  Future<List<Map<String, dynamic>>>? barangTerjualFuture;
  Future<List<Map<String, dynamic>>>? notifikasiFuture;
  Map<String, dynamic>? profilPenitip;
  String _formatTanggal(String tanggalISO) {
    try {
      final dt = DateTime.parse(tanggalISO);
      return DateFormat('dd - MM - yyyy').format(dt); // atau 'yyyy-MM-dd'
    } catch (_) {
      return tanggalISO; // fallback kalau gagal parse
    }
  }
  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  void requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission();

    print('🔔 Notif permission: ${settings.authorizationStatus}');
  }

  Future<void> kirimFcmTokenKeLaravel(int penitipId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/penitip/update-fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: '{"id": $penitipId, "token": "$token"}',
      );
      print("✅ Kirim token respon: ${response.body}");
    } else {
      print("❌ Tidak dapat token FCM");
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
            onPressed: () => Navigator.pop(context), // Batal
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // hapus semua sesi
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
      final profil = await ApiService.fetchProfilPenitip(userId);
      setState(() {
        profilPenitip = profil;
        barangAktifFuture = ApiService.fetchBarangAktifPenitip(userId);
        barangTerjualFuture = ApiService.fetchBarangTerjualPenitip(userId);
        notifikasiFuture = ApiService.fetchNotifikasiPenitip(userId);
      });

      await kirimFcmTokenKeLaravel(userId); // ✅ kirim token FCM
    } else {
      setState(() {
        barangAktifFuture = Future.value([]);
        barangTerjualFuture = Future.value([]);
        notifikasiFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (barangAktifFuture == null || barangTerjualFuture == null || notifikasiFuture == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Penitip"),
        backgroundColor: Colors.green,
        actions: [
          TextButton(
            onPressed: () => _confirmLogout(context),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      const Text("🔔 Notifikasi Terbaru", style: TextStyle(fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 24),

            // 👤 Profil
            if (profilPenitip == null) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
            ] else ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profilPenitip!['profile_picture'] != null
                        ? NetworkImage(profilPenitip!['profile_picture'])
                        : const AssetImage("assets/default-user.png") as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Username : ${profilPenitip!['username']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("Email✉️ : ${profilPenitip!['email']}"),
                        Text("No Telp☎️ : ${profilPenitip!['no_telp'] ?? '-'}"),
                        Text("Saldo: ${formatRupiah(profilPenitip!['saldo'])}"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Arahkan ke halaman edit profil penitip
                          },
                          child: const Text("Edit Profil"),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
            ],

            // 📦 Barang Aktif
            const Text("Barang yang Sedang Dititipkan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: barangAktifFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final barang = snapshot.data ?? [];
                if (barang.isEmpty) return const Text("Tidak ada barang aktif.");

                return ListView.builder(
                  itemCount: barang.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final b = barang[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: b['thumbnail'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(b['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatRupiah(b['harga'])),
                            Text("Kategori: ${b['kategori']}"),
                            Text("Titip s/d: ${_formatTanggal(b['batas_waktu_titip'])}"),
                            Text("Perpanjang: ${(b['status_perpanjangan'] ?? 0) == 1 ? '✅' : '❌'}"),
                            const SizedBox(height: 6),
                            if ((b['status_perpanjangan'] ?? 0) == 0)
                              ElevatedButton(onPressed: () {}, child: const Text("⏳ Perpanjang")),
                            if ((b['status_pengambilan'] ?? 0) == 0)
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                child: const Text("Konfirmasi Ambil"),
                              ),
                            OutlinedButton(onPressed: () {}, child: const Text("Detail")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // 🛒 Barang Terjual
            const Text("Riwayat Barang Terjual", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: barangTerjualFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final barang = snapshot.data ?? [];
                if (barang.isEmpty) return const Text("Belum ada barang yang terjual.");

                return ListView.builder(
                  itemCount: barang.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final b = barang[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CachedNetworkImage(
                              imageUrl: b['thumbnail'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 8),
                            Text(b['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("Rp ${b['harga']}"),
                            const Text("✅ Sudah Terjual", style: TextStyle(color: Colors.red)),
                            OutlinedButton(onPressed: () {}, child: const Text("Lihat Detail")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
