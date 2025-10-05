import 'package:flutter/material.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainSidebar extends StatelessWidget {
  const MainSidebar({super.key});

  Future<Map<String, String>> _getCompanyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('company_name') ?? 'Agrovet POS';
    final image = prefs.getString('company_image') ?? '';
    return {'name': name, 'image': image};
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, String>>(
        future: _getCompanyProfile(),
        builder: (context, snapshot) {
          final name = snapshot.data?['name'] ?? 'Agrovet POS';
          final imageUrl = snapshot.data?['image'] ?? '';
          ImageProvider? companyImage;
          if (imageUrl.isNotEmpty && (imageUrl.startsWith('/') || imageUrl.contains(':\\'))) {
            companyImage = FileImage(File(imageUrl));
          } else if (imageUrl.isNotEmpty) {
            companyImage = NetworkImage(imageUrl);
          }
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Colors.green),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: companyImage,
                      backgroundColor: Colors.white24,
                      child: companyImage == null ? const Icon(Icons.business, size: 32, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.gaugeHigh, color: Colors.green),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dashboard');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.boxesStacked, color: Colors.deepOrange),
                title: const Text('Inventory'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/inventory');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.cartShopping, color: Colors.purple),
                title: const Text('Sales'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/sales');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.gear, color: Colors.blue),
                title: const Text('Farm Services'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/farm_services');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.userGroup, color: Colors.teal),
                title: const Text('Customers'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/customers');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.fileLines, color: Colors.indigo),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reports');
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.gear, color: Colors.grey),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          );
        },
      ),
    );
  }
}