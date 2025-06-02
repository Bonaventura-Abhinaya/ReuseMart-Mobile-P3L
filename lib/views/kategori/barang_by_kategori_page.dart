import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../detail/barang_detail_page.dart';

class BarangByKategoriPage extends StatefulWidget {
  final int kategoriId;
  final String kategoriNama;

  const BarangByKategoriPage({
    super.key,
    required this.kategoriId,
    required this.kategoriNama,
  });

  @override
  State<BarangByKategoriPage> createState() => _BarangByKategoriPageState();
}

class _BarangByKategoriPageState extends State<BarangByKategoriPage> {
  late Future<List<Map<String, dynamic>>> barangFuture;

  @override
  void initState() {
    super.initState();
    barangFuture = ApiService.fetchBarangByKategori(widget.kategoriId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kategori: ${widget.kategoriNama}"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: barangFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final barangList = snapshot.data!;
          if (barangList.isEmpty) {
            return const Center(child: Text("Belum ada barang dalam kategori ini."));
          }

          return ListView.builder(
            itemCount: barangList.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final barang = barangList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CachedNetworkImage(
                    imageUrl: barang['thumbnail'],
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                  ),
                  title: Text(barang['nama']),
                  subtitle: Text("Rp ${barang['harga']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BarangDetailPage(id: barang['id']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
