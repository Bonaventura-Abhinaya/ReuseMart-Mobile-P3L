import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../detail/barang_detail_page.dart';

class HasilPencarianPage extends StatefulWidget {
  final String keyword;

  const HasilPencarianPage({super.key, required this.keyword});

  @override
  State<HasilPencarianPage> createState() => _HasilPencarianPageState();
}

class _HasilPencarianPageState extends State<HasilPencarianPage> {
  late Future<List<Map<String, dynamic>>> hasilFuture;

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  @override
  void initState() {
    super.initState();
    hasilFuture = ApiService.searchBarang(widget.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hasil untuk \"${widget.keyword}\""),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: hasilFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final barangList = snapshot.data!;
          if (barangList.isEmpty) {
            return const Center(child: Text("Tidak ditemukan barang yang cocok."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: barangList.length,
            itemBuilder: (context, index) {
              final barang = barangList[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarangDetailPage(id: barang['id']),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CachedNetworkImage(
                        imageUrl: barang['thumbnail'],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(barang['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(formatRupiah(barang['harga'])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
