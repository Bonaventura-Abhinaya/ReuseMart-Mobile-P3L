class KomisiLog {
  final int id;
  final DateTime tanggal;
  final String namaBarang;
  final String namaPenitip;
  final int totalHarga;
  final int komisiHunter;

  KomisiLog({
    required this.id,
    required this.tanggal,
    required this.namaBarang,
    required this.namaPenitip,
    required this.totalHarga,
    required this.komisiHunter,
  });

  factory KomisiLog.fromJson(Map<String, dynamic> json) {
    final barang = json['barang'];
    final penitip = json['penitip'];

    return KomisiLog(
      id: json['id'],
      tanggal: DateTime.parse(json['created_at']),
      namaBarang: barang != null ? barang['nama'] ?? '-' : '-',
      namaPenitip: penitip != null ? penitip['username'] ?? '-' : '-',
      totalHarga: _parseInt(json['total_harga']),
      komisiHunter: _parseInt(json['komisi_hunter']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // ambil bagian sebelum titik desimal (misalnya "1000000.00")
      final cleaned = value.split('.').first;
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }
}
