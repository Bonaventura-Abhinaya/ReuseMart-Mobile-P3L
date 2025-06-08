import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../kategori/list_kategori_page.dart';
import '../home/barang_terbaru_section.dart';
import '../profil/profil_pembeli_page.dart';
import '../transaksi/riwayat_transaksi_page.dart';

class PembeliMainPage extends StatefulWidget {
  const PembeliMainPage({super.key});

  @override
  State<PembeliMainPage> createState() => _PembeliMainPageState();
}

class _PembeliMainPageState extends State<PembeliMainPage> {
  int _selectedIndex = 0;
  int? pembeliId;

  final List<Widget> _pages = [
    const BarangTerbaruSection(),
    const ListKategoriPage(),
    const Placeholder(), // Transaksi
    const Placeholder(), // Akun
  ];

  @override
  void initState() {
    super.initState();
    _loadPembeliId();
  }

  Future<void> _loadPembeliId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pembeliId = prefs.getInt('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> displayedPages = [
      const BarangTerbaruSection(),
      const ListKategoriPage(),
      pembeliId != null
          ? RiwayatTransaksiPage(pembeliId: pembeliId!)
          : const BelumLoginPage(),
      pembeliId != null
          ? ProfilPembeliPage(pembeliId: pembeliId!)
          : const BelumLoginPage(),
    ];

    return Scaffold(
      body: displayedPages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: "Kategori"),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Transaksi"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
        ],
      ),
    );
  }
}

// Jika belum login
class BelumLoginPage extends StatelessWidget {
  const BelumLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Kamu belum login. Silakan login terlebih dahulu."),
    );
  }
}
