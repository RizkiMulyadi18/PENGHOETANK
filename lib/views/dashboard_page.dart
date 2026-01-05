import 'tambah_peminjam_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang Rp
import '../helpers/db_helper.dart';
import 'detail_hutang_page.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DbHelper _dbHelper = DbHelper();
  final currencyFormatter = NumberFormat.currency(
    locale: 'id',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  // Fungsi Helper untuk Warna
  Color _getWarnaResiko(String resiko) {
    switch (resiko) {
      case 'Bahaya':
        return Colors.red.shade100;
      case 'Waspada':
        return Colors.orange.shade100;
      default:
        return Colors.green.shade100;
    }
  }

  Color _getWarnaTeks(String resiko) {
    switch (resiko) {
      case 'Bahaya':
        return Colors.red.shade900;
      case 'Waspada':
        return Colors.deepOrange;
      default:
        return Colors.green.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Penghoetank"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bagian 1: Header Ringkasan (Aggregate Data)
          FutureBuilder<double>(
            future: _dbHelper.ambilTotalPiutang(),
            builder: (context, snapshot) {
              double total = snapshot.data ?? 0;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Piutang Anda:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 10),
                    Text(
                      currencyFormatter.format(total),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bagian 2: Daftar Hutang Aktif (Read & Join Table)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbHelper.ambilHutangAktif(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                // 1. EMPTY STATE (Tampilan jika kosong)
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Dompet aman, belum ada yang ngutang!",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // 2. LIST DATA DENGAN TAMPILAN BARU
                return ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: 80,
                  ), // Supaya list terbawah tidak tertutup tombol +
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];

                    // Ambil level resiko (default 'Aman' jika null)
                    String resiko = item['level_resiko'] ?? 'Aman';

                    return Card(
                      elevation: 4, // Efek bayangan (Shadow)
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: InkWell(
                        // Efek percikan air saat diklik
                        borderRadius: BorderRadius.circular(15),
                        onTap: () async {
                          // Navigasi ke Detail
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailHutangPage(dataHutang: item),
                            ),
                          );
                          setState(() {});
                        },
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // AVATAR WARNA-WARNI
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: _getWarnaResiko(resiko),
                                child: Text(
                                  item['nama'][0].toUpperCase(),
                                  style: TextStyle(
                                    color: _getWarnaTeks(resiko),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),

                              // NAMA & TANGGAL
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nama'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          item['jatuh_tempo'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // NOMINAL UANG
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(
                                      item['sisa_hutang'],
                                    ),
                                    style: TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // Badge Kecil Level Resiko
                                  Container(
                                    margin: EdgeInsets.only(top: 5),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getWarnaResiko(resiko),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      resiko,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getWarnaTeks(resiko),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigasi ke Halaman Tambah dan tunggu hasilnya
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahPeminjamPage()),
          );

          // Jika result == true (artinya data berhasil disimpan), refresh halaman
          if (result == true) {
            setState(
              () {},
            ); // Memicu build ulang untuk mengambil data terbaru dari DB
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
