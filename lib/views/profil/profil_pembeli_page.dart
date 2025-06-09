import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:reusemart_mobile/views/merchandise/riwayat_merchandise_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../home/home_guest_page.dart';

class ProfilPembeliPage extends StatelessWidget {
  final int pembeliId;

  const ProfilPembeliPage({super.key, required this.pembeliId});

  String formatAngka(int angka) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(angka);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tidak"),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeGuestPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Ya"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Saya"), backgroundColor: Colors.green),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService.fetchProfilPembeli(pembeliId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text("Gagal memuat data profil."));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: data['profile_picture'] != null
                      ? NetworkImage(data['profile_picture'])
                      : const AssetImage("assets/default-user.png") as ImageProvider,
                ),
                const SizedBox(height: 16),
                Text(data['username'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("📧 ${data['email']}"),
                Text("📞 ${data['no_telp'] ?? '-'}"),
                Text("🏠 ${data['alamat_utama'] ?? 'Belum ada alamat'}"),
                const SizedBox(height: 12),
                Text("🎁 Poin: ${formatAngka(data['poin'])}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RiwayatMerchandisePage()),
                      );
                    },
                    child: const Text("Claim merch anda"),
                  ),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
