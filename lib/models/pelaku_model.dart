class Pelaku {
  final int? id;
  final String nama;
  final String nomorHp;
  final String levelResiko;

  Pelaku({this.id, required this.nama, required this.nomorHp, required this.levelResiko});

  // Mengubah Map dari database menjadi Object
  factory Pelaku.fromMap(Map<String, dynamic> map) => Pelaku(
        id: map['id'],
        nama: map['nama'],
        nomorHp: map['nomor_hp'],
        levelResiko: map['level_resiko'],
      );

  // Mengubah Object menjadi Map untuk disimpan ke database
  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'nomor_hp': nomorHp,
        'level_resiko': levelResiko,
      };
}