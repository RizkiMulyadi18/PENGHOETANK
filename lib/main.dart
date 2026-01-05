import 'package:flutter/material.dart';
import 'views/dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pawang Pinjol',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: DashboardPage(),
    );
  }
}