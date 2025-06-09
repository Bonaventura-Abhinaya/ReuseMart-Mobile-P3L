class MerchandiseModel {
  final int id;
  final String nama;
  final int hargaPoin;
  final int stok;
  final String thumbnail;
  final String status;
  final String? tanggalAmbil;

  MerchandiseModel({
    required this.id,
    required this.nama,
    required this.hargaPoin,
    required this.stok,
    required this.thumbnail,
    required this.status,
    this.tanggalAmbil,
  });

  factory MerchandiseModel.fromJson(Map<String, dynamic> json) {
    return MerchandiseModel(
      id: json['id'],
      nama: json['nama'],
      hargaPoin: json['harga_poin'],
      stok: json['stok'],
      thumbnail: json['thumbnail'],
      status: json['status'],
      tanggalAmbil: json['tanggal_ambil'],
    );
  }
}
