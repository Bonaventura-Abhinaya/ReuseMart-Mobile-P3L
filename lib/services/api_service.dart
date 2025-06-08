import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class ApiService {
  static const String baseUrl = "http://192.168.1.10:8000";

  // 🔐 LOGIN UNIVERSAL
   static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Accept': 'application/json'},
      body: {'username': username, 'password': password},
    );

    final data = jsonDecode(response.body);
    print('🧾 RESPONSE BODY: $data');

    if (response.statusCode == 200 && data['status'] == 'success') {
      final userData = data['data'] ?? {};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['token'] ?? '');
      await prefs.setString('username', userData['username'] ?? '');
      await prefs.setString('role', data['role'] ?? '');
      await prefs.setInt('user_id', userData['id'] ?? 0);
      await prefs.setString('nama_lengkap', userData['nama_lengkap'] ?? '');

      // ✅ KIRIM FCM TOKEN JIKA PENITIP
      if (data['role'] == 'penitip') {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        await http.post(
          Uri.parse('$baseUrl/api/penitip/update-fcm-token'),
          headers: {'Accept': 'application/json'},
          body: {
            'id': userData['id'].toString(),
            'token': fcmToken ?? '',
          },
        );
      }

      // ✅ KIRIM FCM TOKEN JIKA PEMBELI
      if (data['role'] == 'pembeli') {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        await http.post(
          Uri.parse('$baseUrl/api/pembeli/update-fcm-token'),
          headers: {'Accept': 'application/json'},
          body: {
            'id': userData['id'].toString(),
            'token': fcmToken ?? '',
          },
        );
      }

      return {
        'role': data['role'],
        'data': userData,
      };
    } else {
      print('⛔ Login gagal: ${response.statusCode} | ${response.body}');
      throw Exception(data['message'] ?? 'Login gagal.');
    }
  }


  // 🔓 LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // 📦 GET DATA BARANG UNTUK GUEST
  static Future<List<Map<String, dynamic>>> fetchBarang() async {
    final url = Uri.parse("$baseUrl/api/barang");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Gagal memuat data barang.");
    }
  }

  // 🔹 FETCH KATEGORI
  static Future<List<Map<String, dynamic>>> fetchKategori() async {
    final response = await http.get(Uri.parse("$baseUrl/api/kategori"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Gagal memuat kategori");
    }
  }

  // 🔹 FETCH PRODUK TERBARU
  static Future<List<Map<String, dynamic>>> fetchBarangTerbaru() async {
    final response = await http.get(Uri.parse("$baseUrl/api/barang-terbaru"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception("Gagal memuat barang terbaru");
    }
  }

  // 🔹 FETCH BARANG PAGINATED
  static Future<List<Map<String, dynamic>>> fetchBarangPaginated({int page = 1}) async {
    final response = await http.get(Uri.parse("$baseUrl/api/barang?page=$page&per_page=10"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception("Gagal memuat barang");
    }
  }

  // 🔍 DETAIL BARANG
  static Future<Map<String, dynamic>> fetchDetailBarang(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/barang/$id'));
    if (res.statusCode == 200) return json.decode(res.body);
    throw Exception("Gagal memuat detail barang");
  }

  // 🔁 REKOMENDASI BARANG
  static Future<List<Map<String, dynamic>>> fetchRekomendasi(int kategoriId, int excludeId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/barang-rekomendasi/$kategoriId/$excludeId'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal memuat rekomendasi");
    }
  }

  // 🔎 BARANG BY KATEGORI
  static Future<List<Map<String, dynamic>>> fetchBarangByKategori(int kategoriId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/kategori/$kategoriId/barang'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal memuat barang kategori");
    }
  }

  // 🔍 SEARCH BARANG
  static Future<List<Map<String, dynamic>>> searchBarang(String keyword) async {
    final res = await http.get(Uri.parse('$baseUrl/api/barang/search?q=$keyword'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      print("⛔ STATUS CODE: ${res.statusCode}");
      print("⛔ BODY: ${res.body}");
      throw Exception("Gagal melakukan pencarian");
    }
  }
  

  // Profil Penitip
  static Future<Map<String, dynamic>> fetchProfilPenitip(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/penitip/$id/profil'));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal memuat profil penitip");
    }
  }

  // Barang berdasarkan penitip
  static Future<List<Map<String, dynamic>>> fetchBarangByPenitip(int penitipId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/penitip/$penitipId/barang'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal memuat barang penitip");
    }
  }

  // 🔹 Barang Aktif Penitip
static Future<List<Map<String, dynamic>>> fetchBarangAktifPenitip(int penitipId) async {
  final res = await http.get(Uri.parse('$baseUrl/api/penitip/$penitipId/barang-aktif'));
  if (res.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  } else {
    throw Exception("Gagal memuat barang aktif penitip");
  }
}

// 🔹 Barang Terjual Penitip
static Future<List<Map<String, dynamic>>> fetchBarangTerjualPenitip(int penitipId) async {
  final res = await http.get(Uri.parse('$baseUrl/api/penitip/$penitipId/barang-terjual'));
  if (res.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  } else {
    throw Exception("Gagal memuat barang terjual penitip");
  }
}

// 🔔 Notifikasi Penitip
static Future<List<Map<String, dynamic>>> fetchNotifikasiPenitip(int penitipId) async {
  final res = await http.get(Uri.parse('$baseUrl/api/penitip/$penitipId/notifikasi'));
  if (res.statusCode == 200) {
    return List<Map<String, dynamic>>.from(json.decode(res.body));
  } else {
    throw Exception("Gagal memuat notifikasi");
  }
}

  // 📄 Profil Pembeli
  static Future<Map<String, dynamic>> fetchProfilPembeli(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/pembeli/$id/profil'));
    print("🔍 GET: $baseUrl/api/pembeli/$id/profil");
  print("📡 Status: ${res.statusCode}");
  print("📄 Body: ${res.body}");
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(res.body));
      } else {
        throw Exception("Gagal memuat profil pembeli");
      }
    }


  // 🔔 Notifikasi Pembeli
  static Future<List<Map<String, dynamic>>> fetchNotifikasiPembeli(int pembeliId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/pembeli/$pembeliId/notifikasi'));
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal memuat notifikasi");
    }
  }

  //histori pembeli
  static Future<List<Map<String, dynamic>>> fetchRiwayatTransaksi(int pembeliId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/pembeli/$pembeliId/riwayat-transaksi'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Gagal memuat riwayat transaksi');
    }
  }

  //histori detail pembeli
  static Future<Map<String, dynamic>> fetchDetailTransaksi(int transaksiId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/pembeli/transaksi/$transaksiId'));
    if (res.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(res.body));
    } else {
      throw Exception("Gagal mengambil detail transaksi");
    }
  }


  // 🔓 CLEAR LOGIN SESSION (pakai di main.dart untuk reset manual)
  // static Future<void> clearLoginSession() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.clear();
  // }
}