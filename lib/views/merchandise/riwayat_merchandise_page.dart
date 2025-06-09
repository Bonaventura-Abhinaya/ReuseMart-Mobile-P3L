import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

class RiwayatMerchandisePage extends StatefulWidget {
  const RiwayatMerchandisePage({super.key});

  @override
  State<RiwayatMerchandisePage> createState() => _RiwayatMerchandisePageState();
}

class _RiwayatMerchandisePageState extends State<RiwayatMerchandisePage> {
  List<Map<String, dynamic>> riwayat = [];
  bool isLoading = true;
  int? pembeliId;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    pembeliId = prefs.getInt('user_id');
    if (pembeliId != null) {
      final data = await ApiService.fetchRiwayatMerchandise(pembeliId!);
      setState(() {
        riwayat = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Klaim Merchandise"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : riwayat.isEmpty
              ? const Center(child: Text("Belum ada klaim merchandise"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: riwayat.length,
                  itemBuilder: (context, index) {
                    final item = riwayat[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Image.network(
                          '${ApiService.baseUrl}/storage/${item['thumbnail']}',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => const Icon(Icons.image_not_supported),
                        ),
                        title: Text(item['nama_merchandise']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${item['status']}"),
                            if (item['tanggal_ambil'] != null)
                              Text("Diambil: ${item['tanggal_ambil']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
