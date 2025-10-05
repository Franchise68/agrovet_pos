import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const AgrovetPOSApp());
}

class AgrovetPOSApp extends StatelessWidget {
  const AgrovetPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agrovet POS',
      theme: ThemeData(primarySwatch: Colors.green),
  home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
