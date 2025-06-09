import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../detail/barang_detail_page.dart';
import '../kategori/barang_by_kategori_page.dart';
import 'barang_lainnya_page.dart';
import 'package:intl/intl.dart';
import 'hasil_pencarian_page.dart';


class BarangTerbaruSection extends StatefulWidget {
  const BarangTerbaruSection({super.key});

  @override
  State<BarangTerbaruSection> createState() => _BarangTerbaruSectionState();
}

class _BarangTerbaruSectionState extends State<BarangTerbaruSection> {
  late Future<List<Map<String, dynamic>>> kategoriFuture;
  late Future<List<Map<String, dynamic>>> barangTerbaruFuture;

  TextEditingController searchController = TextEditingController();
  Future<List<Map<String, dynamic>>>? searchResultFuture;
  String? currentQuery;

  @override
  void initState() {
    super.initState();
    kategoriFuture = ApiService.fetchKategori();
    barangTerbaruFuture = ApiService.fetchBarangTerbaru();
  }

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beranda"),
      backgroundColor: Colors.green,),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔍 SEARCH BAR
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Cari barang...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HasilPencarianPage(keyword: value.trim()),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // 📂 KATEGORI
          const Text("Kategori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: kategoriFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Gagal memuat kategori: ${snapshot.error}");
              }
              final kategoriList = snapshot.data!;
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = kategoriList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BarangByKategoriPage(
                              kategoriId: kategori['id'],
                              kategoriNama: kategori['nama'],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.green.shade100,
                        ),
                        child: Center(child: Text(kategori['nama'])),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // 🛒 PRODUK TERBARU / PENCARIAN
          Text(
            currentQuery == null ? "Produk Terbaru" : "Hasil Pencarian untuk \"$currentQuery\"",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: searchResultFuture ?? barangTerbaruFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Gagal memuat produk: ${snapshot.error}");
              }
              final barangList = snapshot.data!;
              if (barangList.isEmpty) {
                return const Text("Tidak ditemukan barang yang cocok.");
              }

              return Column(
                children: barangList.map((barang) {
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
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // 🔽 TOMBOL LIHAT PRODUK LAINNYA
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BarangLainnyaPage()),
                );
              },
              child: const Text("Lihat Barang Lainnya"),
            ),
          )
        ],
      ),
    );
  }
}
