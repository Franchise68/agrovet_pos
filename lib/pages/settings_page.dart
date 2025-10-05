import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../widgets/main_sidebar.dart';
import '../database.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();
  String? companyImageUrl;
  File? companyImageFile;
  bool uploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      final response = await client.from('profiles').select().eq('id', user.id).single();
      setState(() {
        companyImageUrl = response['company_image_url'] as String?;
        shopNameController.text = response['company_name'] ?? '';
      });
    }
  }

  Future<void> _updateCompanyName(String name) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user != null) {
      await client.from('profiles').upsert({
        'id': user.id,
        'company_name': name,
      });
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_name', name);
    setState(() {});
  }

  Future<void> _pickAndUploadImage() async {
    setState(() { uploadingImage = true; });
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      setState(() { uploadingImage = false; });
      return;
    }
    setState(() {
      companyImageFile = File(pickedFile.path);
      uploadingImage = false;
    });
    // Save local image path to shared preferences for dashboard and other pages
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('company_image', pickedFile.path);
  }
  final shopNameController = TextEditingController();
  final currencyController = TextEditingController();

  @override
  // Removed duplicate initState

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    // Do NOT reset shopNameController.text here to avoid overwriting user input
    // currencyController.text = settings.currency; // Only set if needed, not every build
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const FaIcon(FontAwesomeIcons.bars),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: FaIcon(FontAwesomeIcons.user), text: 'Account'),
              Tab(icon: FaIcon(FontAwesomeIcons.store), text: 'Business'),
              Tab(icon: FaIcon(FontAwesomeIcons.database), text: 'Data'),
              Tab(icon: FaIcon(FontAwesomeIcons.gear), text: 'Preferences'),
              Tab(icon: FaIcon(FontAwesomeIcons.circleInfo), text: 'Help'),
            ],
          ),
        ),
        drawer: const MainSidebar(),
        body: TabBarView(
          children: [
            _buildAccountTab(),
            _buildBusinessTab(settings),
            _buildDataTab(),
            _buildPreferencesTab(settings),
            _buildHelpTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    final client = Supabase.instance.client;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton(
          child: const Text('Sign Out'),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
                ],
              ),
            );
            if (confirm == true) {
              await client.auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out.')));
              Navigator.pushReplacementNamed(context, '/auth');
            }
          },
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Name'),
          controller: shopNameController,
          onChanged: (val) async {
            final user = client.auth.currentUser;
            if (user != null) {
              await client.from('profiles').upsert({'id': user.id, 'company_name': val});
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('company_name', val);
            }
          },
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
          onChanged: (val) async {
            final user = client.auth.currentUser;
            if (user != null) {
              await client.from('profiles').upsert({'id': user.id, 'company_phone': val});
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('company_phone', val);
            }
          },
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) async {
            final user = client.auth.currentUser;
            if (user != null) {
              await client.from('profiles').upsert({'id': user.id, 'company_email': val});
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('company_email', val);
            }
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          child: const Text('Change Password'),
          onPressed: () {
            final oldPasswordController = TextEditingController();
            final newPasswordController = TextEditingController();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Change Password'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: oldPasswordController, decoration: const InputDecoration(labelText: 'Old Password'), obscureText: true),
                    TextField(controller: newPasswordController, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    onPressed: () async {
                      final user = client.auth.currentUser;
                      if (user != null) {
                        // Try to re-authenticate with old password
                        final response = await client.auth.signInWithPassword(
                          email: user.email ?? '',
                          password: oldPasswordController.text,
                        );
                        if (response.session != null) {
                          // Change password
                          await client.auth.updateUser(UserAttributes(password: newPasswordController.text));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully.')));
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Old password incorrect.')));
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          child: const Text('Manage Users'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Manage Users'),
                content: const Text('User management coming soon.'),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBusinessTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: uploadingImage ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: companyImageFile != null
                        ? FileImage(companyImageFile!)
                        : (companyImageUrl != null ? NetworkImage(companyImageUrl!) : null) as ImageProvider?,
                    child: companyImageFile == null && companyImageUrl == null ? const Icon(Icons.camera_alt, size: 32, color: Colors.blue) : null,
                  ),
                  if (uploadingImage)
                    const Positioned(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: shopNameController,
                decoration: const InputDecoration(labelText: 'Company Name'),
                onChanged: (val) => _updateCompanyName(val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(labelText: 'Address'),
          onChanged: (val) {}, // TODO: Save to business info
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Contact'),
          keyboardType: TextInputType.phone,
          onChanged: (val) {}, // TODO: Save to business info
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton(
          child: const Text('Backup Data'),
          onPressed: () async {
            final dbPath = await getDatabasesPath();
            final dbFile = File('$dbPath/pos.db');
            final downloads = await getDownloadsDirectory();
            final backupFile = File('${downloads?.path}/pos_backup_${DateTime.now().millisecondsSinceEpoch}.db');
            await dbFile.copy(backupFile.path);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved to ${backupFile.path}')));
          },
        ),
        ElevatedButton(
          child: const Text('Restore Data'),
          onPressed: () async {
            final client = Supabase.instance.client;
            String restoreError = '';
            setState(() { uploadingImage = true; });
            try {
              final tables = ['products', 'customers', 'sales', 'farm_services', 'inventory'];
              for (var table in tables) {
                final rows = await client.from(table).select();
                for (var row in rows) {
                  switch (table) {
                    case 'products': await POSDatabase.updateProduct(row); break;
                    case 'customers': await POSDatabase.insertCustomer(row); break;
                    case 'sales': await POSDatabase.insertSale(row); break;
                    case 'farm_services': await POSDatabase.updateFarmService(row); break;
                    case 'inventory': await POSDatabase.insertInventory(row); break;
                  }
                }
              }
            } catch (e) {
              restoreError = e.toString();
            }
            setState(() { uploadingImage = false; });
            if (restoreError.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore completed from Supabase.')));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $restoreError')));
            }
          },
        ),
        ElevatedButton(
          child: const Text('Export Data (CSV/PDF)'),
          onPressed: () async {
            final dbProducts = await POSDatabase.getProducts();
            final csv = StringBuffer('Name,Category,Buying,Selling,Quantity,MinStock\n');
            for (var p in dbProducts) {
              csv.writeln('${p['name']},${p['category']},${p['buyingPrice']},${p['sellingPrice']},${p['quantity']},${p['minStock']}');
            }
            final downloads = await getDownloadsDirectory();
            final csvFile = File('${downloads?.path}/products_${DateTime.now().millisecondsSinceEpoch}.csv');
            await csvFile.writeAsString(csv.toString());
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Products exported to ${csvFile.path}')));
          },
        ),
        ElevatedButton(
          onPressed: uploadingImage
              ? null
              : () async {
                  setState(() { uploadingImage = true; });
                  final client = Supabase.instance.client;
                  final user = client.auth.currentUser;
                  final companyId = user?.userMetadata?['company_id'] ?? user?.id;
                  String syncError = '';
                  List<Map<String, dynamic>> skippedSales = [];
                  try {
                    // Upload all tables with company_id
                    final dbProducts = (await POSDatabase.getProducts()).map((p) => {...p, 'company_id': companyId}).toList();
                    await client.from('products').upsert(dbProducts);
                    final dbCustomers = (await POSDatabase.getCustomers()).map((c) => {...c, 'company_id': companyId}).toList();
                    await client.from('customers').upsert(dbCustomers);
                    final dbSalesRaw = await POSDatabase.getSales();
                    // Validate sales before upload
                    final productIds = dbProducts.map((p) => p['id']).toSet();
                    final validSales = <Map<String, dynamic>>[];
                    for (var sale in dbSalesRaw) {
                      if (productIds.contains(sale['productId'])) {
                        validSales.add({...sale, 'company_id': companyId});
                      } else {
                        skippedSales.add(sale);
                      }
                    }
                    await client.from('sales').upsert(validSales);
                    final dbFarmServices = (await POSDatabase.getFarmServices()).map((fs) => {...fs, 'company_id': companyId}).toList();
                    await client.from('farm_services').upsert(dbFarmServices);
                    final dbInventory = (await POSDatabase.getInventory()).map((inv) => {...inv, 'company_id': companyId}).toList();
                    await client.from('inventory').upsert(dbInventory);
                    // Download and update local DB for all tables, filtered by company_id
                    final tables = ['products', 'customers', 'sales', 'farm_services', 'inventory'];
                    for (var table in tables) {
                      final rows = await client.from(table).select().eq('company_id', companyId);
                      for (var row in rows) {
                        switch (table) {
                          case 'products': await POSDatabase.updateProduct(row); break;
                          case 'customers': await POSDatabase.insertCustomer(row); break;
                          case 'sales': await POSDatabase.insertSale(row); break;
                          case 'farm_services': await POSDatabase.updateFarmService(row); break;
                          case 'inventory': await POSDatabase.insertInventory(row); break;
                        }
                      }
                    }
                  } catch (e) {
                    syncError = e.toString();
                  }
                  setState(() { uploadingImage = false; });
                  if (syncError.isEmpty) {
                    String msg = 'Cloud sync completed.';
                    if (skippedSales.isNotEmpty) {
                      msg += '\nSkipped ${skippedSales.length} sales with missing products.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud sync failed: $syncError')));
                  }
                },
          child: uploadingImage
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
              : const Text('Cloud Sync'),
        ),
      ],
    );
  }

  Widget _buildPreferencesTab(AppSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Dark Theme'),
          value: settings.darkTheme,
          onChanged: (val) => settings.toggleTheme(val),
        ),
        TextField(
          controller: currencyController,
          decoration: const InputDecoration(labelText: 'Currency'),
          onChanged: (val) => settings.updateCurrency(val),
        ),
      ],
    );
  }

  Widget _buildHelpTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(title: Text('User Guide / FAQs'), subtitle: Text('Coming soon.')),
        ListTile(title: Text('Contact Support'), subtitle: Text('support@agrovet.com')),
        ListTile(title: Text('App Version'), subtitle: Text('1.0.0')),
      ],
    );
  }
}
