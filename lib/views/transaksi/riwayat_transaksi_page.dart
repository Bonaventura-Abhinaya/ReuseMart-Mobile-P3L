import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'detail_transaksi_page.dart'; // ⬅️ Tambahkan ini untuk navigasi ke detail

class RiwayatTransaksiPage extends StatelessWidget {
  final int pembeliId;

  const RiwayatTransaksiPage({super.key, required this.pembeliId});

  String formatRupiah(int angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  String formatTanggal(String tanggal) {
    final dateTime = DateTime.parse(tanggal);
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  Color statusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.blue;
      case 'menunggu konfirmasi':
        return Colors.amber;
      case 'menunggu pembayaran':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.fetchRiwayatTransaksi(pembeliId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final riwayat = snapshot.data ?? [];

          if (riwayat.isEmpty) {
            return const Center(child: Text("Kamu belum memiliki riwayat transaksi."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: riwayat.map((transaksi) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailTransaksiPage(transaksiId: transaksi['id']),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header transaksi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Tanggal: ${formatTanggal(transaksi['tanggal'])}",
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Text("Status: "),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor(transaksi['status']),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          transaksi['status'],
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text("Total: ${formatRupiah(transaksi['total'])}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Icon(Icons.chevron_right, color: Colors.green),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Daftar barang
                          SizedBox(
                            height: 110,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: transaksi['detail'].length,
                              itemBuilder: (context, index) {
                                final item = transaksi['detail'][index];
                                return Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: Image.network(
                                          item['thumbnail'],
                                          height: 60,
                                          width: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Column(
                                          children: [
                                            Text(item['nama'],
                                                style: const TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis),
                                            Text(formatRupiah(item['harga']),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}