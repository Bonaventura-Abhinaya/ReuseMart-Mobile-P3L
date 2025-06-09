import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import '../detail/barang_detail_page.dart';
import 'package:intl/intl.dart';

class BarangLainnyaPage extends StatefulWidget {
  final String? initialKeyword;

  const BarangLainnyaPage({super.key, this.initialKeyword});

  @override
  State<BarangLainnyaPage> createState() => _BarangLainnyaPageState();
}

class _BarangLainnyaPageState extends State<BarangLainnyaPage> {
  int currentPage = 1;
  List<Map<String, dynamic>> barangList = [];
  bool isLoading = false;
  bool isLastPage = false;
  String? searchKeyword;

  final TextEditingController _searchController = TextEditingController();

  String formatRupiah(dynamic angka) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(angka);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialKeyword != null) {
      _searchController.text = widget.initialKeyword!;
      searchKeyword = widget.initialKeyword!;
    }
    fetchBarang();
  }

  Future<void> fetchBarang() async {
    setState(() => isLoading = true);
    try {
      if (searchKeyword != null && searchKeyword!.isNotEmpty) {
        final searched = await ApiService.searchBarang(searchKeyword!);
        setState(() {
          barangList = searched;
          isLastPage = true; // karena tidak paginated
        });
      } else {
        final fetched = await ApiService.fetchBarangPaginated(page: currentPage);
        setState(() {
          barangList = fetched;
          isLastPage = fetched.length < 10;
        });
      }
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

  void performSearch() {
    setState(() {
      currentPage = 1;
      searchKeyword = _searchController.text.trim();
    });
    fetchBarang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Semua Barang"),
        backgroundColor: Colors.green,),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cari barang...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: performSearch,
                      ),
                    ),
                    onSubmitted: (_) => performSearch(),
                  ),
                ),

                // 🛒 LIST BARANG
                Expanded(
                  child: barangList.isEmpty
                      ? const Center(child: Text("Tidak ada barang ditemukan."))
                      : ListView.builder(
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
                        ),
                ),

                // PAGINATION
                if (searchKeyword == null || searchKeyword!.isEmpty) ...[
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
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
    );
  }
}
