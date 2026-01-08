# Pawang Pinjol

A Flutter app to track personal loans: borrowers, debt status, payment history, and reminders via WhatsApp. Data is stored locally using SQLite (sqflite).

## Features
- Dashboard with total outstanding receivables
- Active debt list with risk levels (Aman/Waspada/Bahaya)
- Add borrower + initial loan data
- Debt detail page with payment history
- Record installments with optional photo proof (camera/gallery)
- WhatsApp reminder with auto-formatted number

## Tech Stack
- Flutter (Material)
- SQLite via sqflite
- intl for currency/date formatting
- image_picker for photo capture
- url_launcher for WhatsApp deep link

## Project Structure
- lib/main.dart: App entry point
- lib/views/dashboard_page.dart: Dashboard and active debts list
- lib/views/tambah_peminjam_page.dart: Add borrower form
- lib/views/detail_hutang_page.dart: Debt details, installments, WhatsApp
- lib/helpers/db_helper.dart: SQLite schema and CRUD
- lib/models/: data models (pelaku, hutang, cicilan)

## Database Schema
- pelaku: id, nama, nomor_hp, level_resiko
- hutang: id, pelaku_id, nominal_total, sisa_hutang, jatuh_tempo, status_lunas
- riwayat_cicilan: id, hutang_id, jumlah_bayar, tanggal_bayar, catatan, bukti_bayar

## Setup
1) Install Flutter SDK
2) Get dependencies
   flutter pub get

## Run
flutter run

## Notes
- WhatsApp reminder uses wa.me URL and requires WhatsApp installed.
- Photo proof uses device camera/gallery permissions.

## Build Troubleshooting
If you see JVM target mismatch (Java 17 vs Kotlin 1.8), set:
android/app/build.gradle.kts:
  kotlinOptions { jvmTarget = "17" }

## License
Private/internal project.
