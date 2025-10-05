
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../database.dart';
import '../widgets/main_sidebar.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final dbCustomers = await POSDatabase.getCustomers();
    setState(() {
      customers = dbCustomers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainSidebar(),
      body: customers.isEmpty
          ? const Center(child: Text('No customers found.'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];
                return Card(
                  child: ListTile(
                    leading: const FaIcon(FontAwesomeIcons.user, color: Colors.green, size: 28),
                    title: Text(c['name'] ?? ''),
                    subtitle: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.phone, color: Colors.blue, size: 16),
                        const SizedBox(width: 6),
                        Text((c['phone'] ?? '').toString()),
                        const SizedBox(width: 12),
                        const FaIcon(FontAwesomeIcons.envelope, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text((c['email'] ?? '').toString()),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: Colors.green,
        tooltip: 'Add Customer',
        child: const FaIcon(FontAwesomeIcons.userPlus, color: Colors.white),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();
    final idNumberController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              FaIcon(FontAwesomeIcons.userPlus, color: Colors.green),
              SizedBox(width: 8),
              Text('Add Customer'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.save),
              label: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                final email = emailController.text.trim();
                final address = addressController.text.trim();
                final idNumber = idNumberController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone are required.'), backgroundColor: Colors.red));
                  return;
                }
                await POSDatabase.insertCustomer({
                  'name': name,
                  'phone': phone,
                  'email': email,
                  'address': address,
                  'idNumber': idNumber,
                });
                Navigator.pop(context);
                _loadCustomers();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer added successfully.'), backgroundColor: Colors.green));
              },
            ),
          ],
        );
      },
    );
  }
}
