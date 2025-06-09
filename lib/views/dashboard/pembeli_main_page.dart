import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../kategori/list_kategori_page.dart';
import '../home/barang_terbaru_section.dart';
import '../profil/profil_pembeli_page.dart';
import '../transaksi/riwayat_transaksi_page.dart';
import '../merchandise/merchandise_page.dart';

class PembeliMainPage extends StatefulWidget {
  const PembeliMainPage({super.key});

  @override
  State<PembeliMainPage> createState() => _PembeliMainPageState();
}

class _PembeliMainPageState extends State<PembeliMainPage> {
  int _selectedIndex = 0;
  int? pembeliId;

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
    // Ubah jadi mutable list (tanpa const)
    final List<Widget> displayedPages = [
      const BarangTerbaruSection(),
      const ListKategoriPage(),
      pembeliId != null
          ? RiwayatTransaksiPage(pembeliId: pembeliId!)
          : const BelumLoginPage(),
      pembeliId != null
          ? ProfilPembeliPage(pembeliId: pembeliId!)
          : const BelumLoginPage(),
    ];

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.category), label: "Kategori"),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: "Transaksi"),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Akun"),
    ];

    // ✅ Jika login, tambahkan Merch
    if (pembeliId != null) {
      displayedPages.add(const MerchandisePage());
      navItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.card_giftcard),
        label: "Merch",
      ));
    }

    // Pastikan selected index tidak lebih besar dari jumlah halaman
    final int maxIndex = displayedPages.length - 1;
    final int safeIndex = _selectedIndex > maxIndex ? 0 : _selectedIndex;

    return Scaffold(
      body: displayedPages[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}

class BelumLoginPage extends StatelessWidget {
  const BelumLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("Kamu belum login. Silakan login terlebih dahulu."),
    );
  }
}