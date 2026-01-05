import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../helpers/db_helper.dart';

class TambahPeminjamPage extends StatefulWidget {
  @override
  _TambahPeminjamPageState createState() => _TambahPeminjamPageState();
}

class _TambahPeminjamPageState extends State<TambahPeminjamPage> {
  final _formKey = GlobalKey<FormState>();
  final DbHelper _dbHelper = DbHelper();

  // Controller untuk mengambil teks dari inputan
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _nominalController = TextEditingController();
  
  // Variabel untuk Dropdown & Tanggal
  String _selectedResiko = 'Aman';
  DateTime? _selectedDate;

  // Fungsi Memilih Tanggal
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)), // Default 1 minggu ke depan
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Fungsi Simpan Data ke Database
  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Harap pilih tanggal jatuh tempo!')),
        );
        return;
      }

      // 1. Simpan Data Pelaku (Tabel 1)
      int pelakuId = await _dbHelper.tambahPelaku({
        'nama': _namaController.text,
        'nomor_hp': _noHpController.text,
        'level_resiko': _selectedResiko,
      });

      // 2. Simpan Data Hutang (Tabel 2)
      // Gunakan ID pelaku yang baru saja dibuat
      await _dbHelper.tambahHutang({
        'pelaku_id': pelakuId,
        'nominal_total': double.parse(_nominalController.text),
        'jatuh_tempo': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        // sisa_hutang akan dihandle otomatis di DbHelper atau sama dengan nominal
        'sisa_hutang': double.parse(_nominalController.text), 
      });

      // 3. Kembali ke Dashboard & Refresh
      if (mounted) { // Cek apakah widget masih aktif sebelum navigasi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data berhasil disimpan!')),
          );
          Navigator.pop(context, true); // Kirim sinyal 'true' agar dashboard refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tambah Teman Baru"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BAGIAN 1: DATA ORANG ---
              Text("Data Peminjam", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 15),
              
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: "Nama Lengkap",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              SizedBox(height: 15),

              TextFormField(
                controller: _noHpController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Nomor HP (WhatsApp)",
                  hintText: "Contoh: 62812345678",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) => value!.isEmpty ? "Nomor HP wajib diisi untuk nagih" : null,
              ),
              SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _selectedResiko,
                decoration: InputDecoration(
                  labelText: "Level Resiko",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                ),
                items: ['Aman', 'Waspada', 'Bahaya'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedResiko = newValue!;
                  });
                },
              ),
              
              SizedBox(height: 30),
              Divider(thickness: 2),
              SizedBox(height: 10),

              // --- BAGIAN 2: DATA HUTANG AWAL ---
              Text("Data Hutang Awal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              SizedBox(height: 15),

              TextFormField(
                controller: _nominalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Nominal Pinjam (Rp)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) => value!.isEmpty ? "Nominal harus diisi" : null,
              ),
              SizedBox(height: 15),

              // Input Tanggal (Custom Widget)
              InkWell(
                onTap: () => _pickDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Jatuh Tempo",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? "Pilih Tanggal"
                        : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                    style: TextStyle(color: _selectedDate == null ? Colors.grey : Colors.black),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _simpanData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text("SIMPAN DATA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}