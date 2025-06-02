import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'barang_detail_page.dart';
import '../kategori/barang_by_kategori_page.dart';
import 'package:intl/intl.dart';

class BarangDetailPage extends StatefulWidget {
  final int id;

  const BarangDetailPage({super.key, required this.id});

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage> {
  late Future<Map<String, dynamic>> barangFuture;
  late Future<List<Map<String, dynamic>>> rekomendasiFuture;
  String? mainImage;
  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  @override
  void initState() {
    super.initState();
    barangFuture = ApiService.fetchDetailBarang(widget.id);
  }

  void setMainImage(String url) {
    setState(() {
      mainImage = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Barang"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: barangFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final barang = snapshot.data!;
          final List<String> fotoList = [
            barang['thumbnail'],
            ...(barang['foto_lain'] as List).cast<String>()
          ];

          if (mainImage == null) mainImage = fotoList.first;

          // Fetch rekomendasi, exclude current ID
          rekomendasiFuture = ApiService.fetchRekomendasi(barang['kategori_id'], barang['id']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Utama
                CachedNetworkImage(
                  imageUrl: mainImage!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),

                // Galeri Thumbnail
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotoList.length,
                    itemBuilder: (context, index) {
                      final url = fotoList[index];
                      return GestureDetector(
                        onTap: () => setMainImage(url),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: mainImage == url ? Colors.green : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Informasi Barang
                Text(barang['nama'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(formatRupiah(barang['harga']),style: const TextStyle(fontSize: 18, color: Colors.orange),),
                const SizedBox(height: 12),

                // Kategori bisa diklik
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BarangByKategoriPage(
                          kategoriId: barang['kategori_id'],
                          kategoriNama: barang['kategori'],
                        ),
                      ),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Kategori: ",
                      children: [
                        TextSpan(
                          text: barang['kategori'],
                          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text("Deskripsi:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(barang['deskripsi']),
                const SizedBox(height: 12),

                Text("Penitip: ${barang['penitip']['username']}"),
                if (barang['penitip']['rating'] > 0)
                  Text("Rating: ${barang['penitip']['rating']} / 5",
                      style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500))
                else
                  const Text("Rating: Belum ada rating", style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 8),
                Text("Garansi: ${barang['garansi'] != null ? 'Ada (hingga ${barang['garansi']})' : 'Tidak Ada'}"),
                Text("Status: ${barang['terjual'] == 1 ? 'Sudah Terjual' : 'Tersedia'}"),

                const SizedBox(height: 32),

                // Rekomendasi
                Text("Barang Serupa dari Kategori ${barang['kategori']}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: rekomendasiFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Text("Gagal memuat rekomendasi: ${snap.error}");
                    }

                    final items = snap.data!;
                    if (items.isEmpty) {
                      return const Text("Belum ada barang lain di kategori ini.");
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BarangDetailPage(id: item['id']),
                              ),
                            );
                          },
                          child: Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: item['thumbnail'],
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['nama'], style: const TextStyle(fontSize: 13)),
                                      Text(formatRupiah(item['harga']),
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),)
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
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
