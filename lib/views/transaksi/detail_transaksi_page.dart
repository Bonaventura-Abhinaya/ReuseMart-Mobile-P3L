import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class DetailTransaksiPage extends StatefulWidget {
  final int transaksiId;

  const DetailTransaksiPage({super.key, required this.transaksiId});

  @override
  State<DetailTransaksiPage> createState() => _DetailTransaksiPageState();
}

class _DetailTransaksiPageState extends State<DetailTransaksiPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  String formatTanggal(String tanggal) {
    final dateTime = DateTime.parse(tanggal);
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
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
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final res = await ApiService.fetchDetailTransaksi(widget.transaksiId);
      setState(() {
        data = res;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Transaksi"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text("Data tidak ditemukan"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Umum
                      Text("📅 Tanggal: ${formatTanggal(data!['tanggal'])}"),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text("📦 Status: "),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor(data!['status']),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data!['status'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text("🚚 Metode: ${data!['tipe_pengiriman']}"),
                      if (data!['tipe_pengiriman'] == 'kirim' && data!['alamat'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text("📍 Alamat:\n${data!['alamat']}"),
                        ),
                      const SizedBox(height: 16),

                      const Divider(thickness: 1),

                      // Detail Barang
                      const Text("🛍 Barang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...data!['detail'].map<Widget>((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                child: Image.network(
                                  item['thumbnail'],
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text("Harga: ${formatRupiah(item['harga'])}"),
                                      Text("Subtotal: ${formatRupiah(item['subtotal'])}"),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      }).toList(),

                      const Divider(thickness: 1),
                      const SizedBox(height: 12),

                      // Ringkasan Total
                      Text("Poin Ditukar: ${data!['poin_ditukar']}"),
                      Text("Potongan: ${formatRupiah(data!['potongan'])}"),
                      Text("Total Dibayar: ${formatRupiah(data!['total'])}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
    );
  }
}
