class Hutang {
  final int? id;
  final int pelakuId;
  final double nominalTotal;
  final double sisaHutang;
  final String jatuhTempo;
  final int statusLunas;

  Hutang({
    this.id,
    required this.pelakuId,
    required this.nominalTotal,
    required this.sisaHutang,
    required this.jatuhTempo,
    this.statusLunas = 0,
  });

  factory Hutang.fromMap(Map<String, dynamic> map) => Hutang(
        id: map['id'],
        pelakuId: map['pelaku_id'],
        nominalTotal: map['nominal_total'],
        sisaHutang: map['sisa_hutang'],
        jatuhTempo: map['jatuh_tempo'],
        statusLunas: map['status_lunas'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'pelaku_id': pelakuId,
        'nominal_total': nominalTotal,
        'sisa_hutang': sisaHutang,
        'jatuh_tempo': jatuhTempo,
        'status_lunas': statusLunas,
      };
}