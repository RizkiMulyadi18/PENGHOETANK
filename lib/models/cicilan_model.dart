class Cicilan {
  final int? id;
  final int hutangId;
  final double jumlahBayar;
  final String tanggalBayar;
  final String catatan;
  final String? buktiBayar; // Nullable karena opsional

  Cicilan({
    this.id,
    required this.hutangId,
    required this.jumlahBayar,
    required this.tanggalBayar,
    required this.catatan,
    this.buktiBayar,
  });

  factory Cicilan.fromMap(Map<String, dynamic> map) => Cicilan(
        id: map['id'],
        hutangId: map['hutang_id'],
        jumlahBayar: map['jumlah_bayar'],
        tanggalBayar: map['tanggal_bayar'],
        catatan: map['catatan'],
        buktiBayar: map['bukti_bayar'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'hutang_id': hutangId,
        'jumlah_bayar': jumlahBayar,
        'tanggal_bayar': tanggalBayar,
        'catatan': catatan,
        'bukti_bayar': buktiBayar,
      };
}