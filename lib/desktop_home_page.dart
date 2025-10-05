import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../database.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  List<Map<String, dynamic>> products = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final dbProducts = await POSDatabase.getProducts();
    setState(() {
      products = dbProducts;
    });
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((p) => p['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agrovet POS Desktop'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.sync),
            tooltip: 'Sync',
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
            destinations: const [
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.box),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.cashRegister),
                label: Text('Sales'),
              ),
              NavigationRailDestination(
                icon: FaIcon(FontAwesomeIcons.gear),
                label: Text('Settings'),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search product',
                      prefixIcon: FaIcon(FontAwesomeIcons.magnifyingGlass),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Category')),
                        DataColumn(label: Text('Stock')),
                        DataColumn(label: Text('Selling Price')),
                      ],
                      rows: filteredProducts.map((product) => DataRow(
                        cells: [
                          DataCell(Text(product['name'] ?? '')),
                          DataCell(Text(product['category'] ?? '')),
                          DataCell(Text(product['quantity'].toString())),
                          DataCell(Text('KSh ${product['sellingPrice']}')),
                        ],
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
