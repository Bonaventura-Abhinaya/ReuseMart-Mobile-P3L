import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../kategori/barang_by_kategori_page.dart';

class ListKategoriPage extends StatelessWidget {
  const ListKategoriPage({super.key});

  IconData getIconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('elektronik')) return Icons.devices_other;
    if (lower.contains('fashion')) return Icons.checkroom;
    if (lower.contains('furniture')) return Icons.chair;
    if (lower.contains('automotive')) return Icons.directions_car;
    if (lower.contains('bayi') || lower.contains('anak')) return Icons.child_friendly;
    if (lower.contains('hobi') || lower.contains('olahraga')) return Icons.sports_soccer;
    if (lower.contains('buku')) return Icons.menu_book;
    if (lower.contains('tulis')) return Icons.edit_note;
    if (lower.contains('antik') || lower.contains('koleksi')) return Icons.auto_awesome;
    if (lower.contains('musik')) return Icons.music_note;
    if (lower.contains('mainan')) return Icons.toys;
    if (lower.contains('game')) return Icons.videogame_asset;
    if (lower.contains('perkebunan')) return Icons.local_florist;
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kategori"),
      backgroundColor: Colors.green,),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ApiService.fetchKategori(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final kategoriList = snapshot.data ?? [];
          if (kategoriList.isEmpty) {
            return const Center(child: Text("Tidak ada kategori."));
          }

          return ListView.builder(
            itemCount: kategoriList.length,
            itemBuilder: (context, index) {
              final kategori = kategoriList[index];
              return ListTile(
                leading: Icon(getIconForCategory(kategori['nama']), color: Colors.green),
                title: Text(kategori['nama']),
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
              );
            },
          );
        },
      ),
    );
  }
}
