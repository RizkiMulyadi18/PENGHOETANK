import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  static Database? _database;

  factory DbHelper() => _instance;
  DbHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'pawang_pinjol.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // Mengaktifkan fitur Foreign Key agar Relasi antar tabel jalan
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future _onCreate(Database db, int version) async {
    // --- TABEL 1: MASTER PELAKU ---
    await db.execute('''
      CREATE TABLE pelaku (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT,
        nomor_hp TEXT,
        level_resiko TEXT
      )
    ''');

    // --- TABEL 2: TRANSAKSI HUTANG ---
    // Sisa_hutang akan berkurang tiap ada cicilan
    await db.execute('''
      CREATE TABLE hutang (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pelaku_id INTEGER,
        nominal_total REAL,
        sisa_hutang REAL,
        jatuh_tempo TEXT,
        status_lunas INTEGER DEFAULT 0,
        FOREIGN KEY (pelaku_id) REFERENCES pelaku (id) ON DELETE CASCADE
      )
    ''');

    // --- TABEL 3: RIWAYAT CICILAN ---
    // Bukti_bayar opsional (bisa null jika bayar cash di jalan)
    await db.execute('''
      CREATE TABLE riwayat_cicilan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hutang_id INTEGER,
        jumlah_bayar REAL,
        tanggal_bayar TEXT,
        catatan TEXT,
        bukti_bayar TEXT,
        FOREIGN KEY (hutang_id) REFERENCES hutang (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==========================================
  // LOGIKA CRUD & PERHITUNGAN
  // ==========================================

  // 1. Fungsi Tambah Pelaku (Create)
  Future<int> tambahPelaku(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pelaku', data);
  }

  // 2. Fungsi Tambah Hutang Baru (Create)
  Future<int> tambahHutang(Map<String, dynamic> data) async {
    final db = await database;
    // Saat buat hutang baru, sisa_hutang diisi sama dengan nominal_total
    data['sisa_hutang'] = data['nominal_total'];
    return await db.insert('hutang', data);
  }

  // 3. Fungsi Tambah Cicilan (Create + Update Sisa Hutang)
  Future<void> tambahCicilan(int hutangId, double jumlahBayar, String catatan, String? pathBukti) async {
    final db = await database;

    // A. Simpan data ke Tabel 3
    await db.insert('riwayat_cicilan', {
      'hutang_id': hutangId,
      'jumlah_bayar': jumlahBayar,
      'tanggal_bayar': DateTime.now().toIso8601String(),
      'catatan': catatan,
      'bukti_bayar': pathBukti, // Bisa null jika tidak ada foto
    });

    // B. Ambil Sisa Hutang lama dari Tabel 2
    List<Map<String, dynamic>> res = await db.query('hutang', where: 'id = ?', whereArgs: [hutangId]);
    double sisaLama = res.first['sisa_hutang'];

    // C. Hitung sisa baru & cek status lunas
    double sisaBaru = sisaLama - jumlahBayar;
    int statusLunas = sisaBaru <= 0 ? 1 : 0;

    // D. Update Tabel 2 dengan sisa baru
    await db.update(
      'hutang',
      {
        'sisa_hutang': sisaBaru < 0 ? 0 : sisaBaru,
        'status_lunas': statusLunas,
      },
      where: 'id = ?',
      whereArgs: [hutangId],
    );
  }

  // 4. Fungsi Ambil Total Piutang untuk Dashboard (Read & Aggregate)
  Future<double> ambilTotalPiutang() async {
    final db = await database;
    var res = await db.rawQuery('SELECT SUM(sisa_hutang) as total FROM hutang WHERE status_lunas = 0');
    if (res.first['total'] != null) {
      return double.parse(res.first['total'].toString());
    }
    return 0.0;
  }

  // 7. Hitung Jumlah Peminjam Aktif (Orang unik yang masih punya hutang)
  Future<int> hitungJumlahPeminjam() async {
    final db = await database;
    // Hitung pelaku_id yang unik (DISTINCT) dari tabel hutang yang belum lunas
    var result = await db.rawQuery('SELECT COUNT(DISTINCT pelaku_id) as total FROM hutang WHERE status_lunas = 0');
    if (result.first['total'] != null) {
      return result.first['total'] as int;
    } else {
      return 0;
    }
  }

  // 5. Fungsi Ambil Daftar Hutang Aktif (Join Tabel 1 & 2)
  Future<List<Map<String, dynamic>>> ambilHutangAktif() async {
    final db = await database;
    // PERBAIKAN: Tambahkan , pelaku.level_resiko di baris bawah ini
    return await db.rawQuery('''
      SELECT hutang.*, pelaku.nama, pelaku.nomor_hp, pelaku.level_resiko
      FROM hutang 
      JOIN pelaku ON hutang.pelaku_id = pelaku.id 
      WHERE hutang.status_lunas = 0
    ''');
  }

  // 6. Fungsi Hapus (Delete)
  // 8. Hapus Pelaku (Bersih sampai ke akar-akarnya)
  Future<void> hapusPelaku(int id) async {
    final db = await database;
    
    // Manual Cascade: Hapus anak-anaknya dulu biar tidak error
    
    // 1. Cari dulu semua hutang milik orang ini
    var listHutang = await db.query('hutang', where: 'pelaku_id = ?', whereArgs: [id]);
    
    // 2. Hapus semua riwayat cicilan dari setiap hutang tersebut
    for (var h in listHutang) {
      await db.delete('riwayat_cicilan', where: 'hutang_id = ?', whereArgs: [h['id']]);
    }

    // 3. Hapus data hutangnya
    await db.delete('hutang', where: 'pelaku_id = ?', whereArgs: [id]);

    // 4. Terakhir, hapus orangnya
    await db.delete('pelaku', where: 'id = ?', whereArgs: [id]);
  }

  // 7. Ambil Riwayat Cicilan per Hutang
  Future<List<Map<String, dynamic>>> ambilRiwayatCicilan(int hutangId) async {
    final db = await database;
    return await db.query(
      'riwayat_cicilan',
      where: 'hutang_id = ?',
      whereArgs: [hutangId],
      orderBy: 'id DESC', // Yang terbaru di atas
    );
  }
}