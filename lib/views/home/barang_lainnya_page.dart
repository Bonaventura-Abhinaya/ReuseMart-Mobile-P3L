import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../detail/barang_detail_page.dart';
import 'package:intl/intl.dart';

class BarangLainnyaPage extends StatefulWidget {
  const BarangLainnyaPage({super.key});

  @override
  State<BarangLainnyaPage> createState() => _BarangLainnyaPageState();
}

class _BarangLainnyaPageState extends State<BarangLainnyaPage> {
  int currentPage = 1;
  List<Map<String, dynamic>> barangList = [];
  bool isLoading = false;
  bool isLastPage = false;
  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  Future<void> fetchBarang() async {
    setState(() => isLoading = true);
    try {
      final fetched = await ApiService.fetchBarangPaginated(page: currentPage);
      setState(() {
        barangList = fetched;
        isLastPage = fetched.length < 10;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void nextPage() {
    if (!isLastPage) {
      setState(() => currentPage++);
      fetchBarang();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() => currentPage--);
      fetchBarang();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barang Lainnya"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: barangList.length,
                    padding: const EdgeInsets.all(16),
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
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentPage > 1)
                      TextButton.icon(
                        onPressed: previousPage,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text("Previous"),
                      ),
                    if (!isLastPage)
                      TextButton.icon(
                        onPressed: nextPage,
                        icon: const Text("Next"),
                        label: const Icon(Icons.chevron_right),
                      ),
                  ],
                )
              ],
            ),
    );
  }
}
