import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/merchandise_model.dart';
import '../../services/api_service.dart';

class MerchandisePage extends StatefulWidget {
  const MerchandisePage({super.key});

  @override
  State<MerchandisePage> createState() => _MerchandisePageState();
}

class _MerchandisePageState extends State<MerchandisePage> {
  List<MerchandiseModel> _merchandiseList = [];
  bool _isLoading = true;
  int? pembeliId;

  @override
  void initState() {
    super.initState();
    loadPembeliId();
  }

  Future<void> loadPembeliId() async {
    final prefs = await SharedPreferences.getInstance();
    pembeliId = prefs.getInt('user_id');
    if (pembeliId != null) {
      fetchMerchandise();
    }
  }

  Future<void> fetchMerchandise() async {
    try {
      final merch = await ApiService.fetchMerchandise(pembeliId!);
      if (mounted) {
        setState(() {
          _merchandiseList = merch;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> konfirmasiKlaim(int merchandiseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin klaim merchandise ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      klaimMerchandise(merchandiseId);
    }
  }

  Future<void> klaimMerchandise(int merchandiseId) async {
    try {
      if (pembeliId == null) return;

      await ApiService.klaimMerchandise(
        pembeliId: pembeliId!,
        merchandiseId: merchandiseId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Klaim berhasil!")),
      );

      fetchMerchandise(); // refresh data
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal klaim: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchandise'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _merchandiseList.isEmpty
              ? const Center(child: Text('Tidak ada merchandise'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _merchandiseList.length,
                  itemBuilder: (context, index) {
                    final merch = _merchandiseList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFFEDF1D6),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                '${ApiService.baseUrl}/storage/${merch.thumbnail}',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 70),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    merch.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Poin: ${merch.hargaPoin}'),
                                  const SizedBox(height: 4),
                                  Text('Stok: ${merch.stok}'),
                                  if (merch.tanggalAmbil != null)
                                    Text('Diambil: ${merch.tanggalAmbil!}',
                                        style: const TextStyle(fontSize: 11)),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          konfirmasiKlaim(merch.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text("Klaim"),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
