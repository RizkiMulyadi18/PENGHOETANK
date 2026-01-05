import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../helpers/db_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io'; // Untuk mengelola File Gambar
import 'package:image_picker/image_picker.dart'; // Untuk buka Kamera

class DetailHutangPage extends StatefulWidget {
  final Map<String, dynamic> dataHutang;

  // Kita butuh data hutang (Nama, ID, Nominal) dari halaman sebelumnya
  const DetailHutangPage({Key? key, required this.dataHutang}) : super(key: key);

  @override
  _DetailHutangPageState createState() => _DetailHutangPageState();
}

class _DetailHutangPageState extends State<DetailHutangPage> {
  final DbHelper _dbHelper = DbHelper();
  final currencyFormatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  
  // Controller untuk input bayar
  final TextEditingController _bayarController = TextEditingController();

  // Fungsi Refresh Halaman
  void _refresh() {
    setState(() {});
  }

  void _tampilFormBayar() {
    // Reset foto setiap kali buka form baru
    _selectedImage = null;
    _bayarController.clear();

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder berguna agar Dialog bisa di-refresh saat foto dipilih
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Input Pembayaran"),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Agar dialog tidak kegedean
                children: [
                  TextField(
                    controller: _bayarController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nominal Bayar (Rp)",
                      prefixText: "Rp ",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 15),
                  
                  // AREA PREVIEW FOTO
                  Text("Bukti Foto (Opsional):", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  InkWell(
                    onTap: () {
                      // Munculkan pilihan: Kamera atau Galeri
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => Wrap(
                          children: [
                            ListTile(
                              leading: Icon(Icons.camera_alt),
                              title: Text('Ambil Foto Kamera'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickImage(ImageSource.camera, setStateDialog);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.photo_library),
                              title: Text('Ambil dari Galeri'),
                              onTap: () {
                                Navigator.pop(ctx);
                                _pickImage(ImageSource.gallery, setStateDialog);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      // Tampilkan Foto jika ada, atau Ikon Kamera jika kosong
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                Text("Tap untuk foto", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(child: Text("Batal"), onPressed: () => Navigator.pop(context)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  child: Text("SIMPAN"),
                  onPressed: () async {
                    if (_bayarController.text.isNotEmpty) {
                      double nominal = double.parse(_bayarController.text);
                      
                      await _dbHelper.tambahCicilan(
                        widget.dataHutang['id'],
                        nominal,
                        "Pembayaran via Aplikasi",
                        _selectedImage?.path, // <--- KIRIM PATH FOTO KE DATABASE
                      );

                      Navigator.pop(context); // Tutup Dialog
                      _refresh(); // Refresh halaman
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }
  
  // Variabel untuk menampung file foto sementara
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Fungsi Membuka Kamera/Galeri
  Future<void> _pickImage(ImageSource source, Function setStateDialog) async {
    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 50);
    if (photo != null) {
      // Kita pakai setStateDialog agar tampilan DI DALAM DIALOG berubah
      setStateDialog(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  // --- LOGIKA WHATSAPP ---
  Future<void> _kirimPesanWA() async {
    // 1. Ambil data nomor HP & Nama
    String nomor = widget.dataHutang['nomor_hp'].toString();
    String nama = widget.dataHutang['nama'];
    
    // 2. Ambil sisa hutang terbaru dari database (biar akurat)
    final db = await _dbHelper.database;
    var data = await db.query('hutang', where: 'id = ?', whereArgs: [widget.dataHutang['id']]);
    double sisa = data.first['sisa_hutang'] as double;
    
    // 3. Format Nomor HP (Ubah 08xx jadi 628xx)
    if (nomor.startsWith('0')) {
      nomor = '62' + nomor.substring(1);
    }
    
    // 4. Buat Pesan Otomatis
    String sisaRp = currencyFormatter.format(sisa);
    String pesan = "Halo *$nama*, sekadar mengingatkan hutangmu tersisa *$sisaRp* dan sudah jatuh tempo. Mohon segera diselesaikan ya, terima kasih! 🙏";
    
    // 5. Buka WhatsApp
    final Uri url = Uri.parse("https://wa.me/$nomor?text=${Uri.encodeComponent(pesan)}");
    
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka WhatsApp: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dataHutang['nama']),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // TOMBOL WHATSAPP
          IconButton(
            icon: Icon(Icons.chat, color: Colors.greenAccent), // Ikon Chat Hijau
            tooltip: 'Tagih via WA',
            onPressed: () {
              _kirimPesanWA(); // Panggil fungsi yang kita buat tadi
            },
          ),
          SizedBox(width: 10), // Jarak sedikit
        ],
      ),
      body: Column(
        children: [
          // HEADER: Status Hutang
          // ... di dalam build() ...
          
          // HEADER: Status Hutang
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              // Gradient Mewah
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.indigo, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)), // Melengkung bawahnya
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0,5))]
            ),
            child: Column(
              children: [
                Text("Sisa Hutang ${widget.dataHutang['nama']}", style: TextStyle(color: Colors.white70)),
                SizedBox(height: 10),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _dbHelper.database.then((db) => db.query('hutang', where: 'id = ?', whereArgs: [widget.dataHutang['id']])),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text("-", style: TextStyle(color: Colors.white));
                    double sisa = snapshot.data!.first['sisa_hutang'];
                    return Text(
                      currencyFormatter.format(sisa),
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  },
                ),
                SizedBox(height: 10),
                Container(
                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                   decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                   child: Text(
                     "Resiko: ${widget.dataHutang['level_resiko'] ?? 'Aman'}", 
                     style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                   ),
                )
              ],
            ),
          ),

          // LIST: Riwayat Cicilan
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dbHelper.ambilRiwayatCicilan(widget.dataHutang['id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("Belum ada riwayat pembayaran."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data![index];
                    return Card( // Bungkus pakai Card biar rapi
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: ListTile(
                        // Bagian Kiri: Menampilkan Foto Kecil atau Icon
                        leading: item['bukti_bayar'] != null
                            ? GestureDetector(
                                onTap: () {
                                  // Fitur Zoom: Tampilkan dialog gambar besar saat diklik
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Image.file(File(item['bukti_bayar'])),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(item['bukti_bayar']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.payment, color: Colors.green),
                              ),
                        
                        title: Text(currencyFormatter.format(item['jumlah_bayar']), style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy - HH:mm').format(DateTime.parse(item['tanggal_bayar']))),
                        trailing: Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Tombol Tambah Bayar
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilFormBayar,
        label: Text("Terima Bayaran"),
        icon: Icon(Icons.add_card),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}