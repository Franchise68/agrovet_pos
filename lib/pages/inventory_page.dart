import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/main_sidebar.dart';
import '../database.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
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

  Future<void> _addProductDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final buyingController = TextEditingController();
    final sellingController = TextEditingController();
    final quantityController = TextEditingController();
    final minStockController = TextEditingController();
  String? imagePath;
  DateTime? expiryDate;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: buyingController, decoration: const InputDecoration(labelText: 'Buying Price'), keyboardType: TextInputType.number),
              TextField(controller: sellingController, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
              TextField(controller: quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: minStockController, decoration: const InputDecoration(labelText: 'Min Stock'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Image'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setState(() {
                          imagePath = picked.path;
                        });
                      }
                    },
                  ),
                  if (imagePath != null) ...[
                    const SizedBox(width: 8),
                    Image.file(File(imagePath!), width: 40, height: 40, fit: BoxFit.cover),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(expiryDate == null
                        ? 'No expiry date selected'
                        : 'Expiry: ${expiryDate!.toLocal().toString().split(' ')[0]}'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick Expiry'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                      );
                      if (picked != null) {
                        setState(() {
                          expiryDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (expiryDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an expiry date.')),
                );
                return;
              }
              final product = {
                'name': nameController.text,
                'category': categoryController.text,
                'buyingPrice': double.tryParse(buyingController.text) ?? 0.0,
                'sellingPrice': double.tryParse(sellingController.text) ?? 0.0,
                'quantity': int.tryParse(quantityController.text) ?? 0,
                'minStock': int.tryParse(minStockController.text) ?? 0,
                'image': imagePath,
                'expiry': expiryDate?.toIso8601String(),
              };
              await POSDatabase.insertProduct(product);
              Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    await POSDatabase.deleteProduct(id);
    _loadProducts();
  }

  List<Map<String, dynamic>> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((p) => p['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus, color: Colors.green),
            tooltip: 'Add Product',
            onPressed: () => _addProductDialog(context),
          ),
        ],
      ),
      drawer: const MainSidebar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search product',
                prefixIcon: FaIcon(FontAwesomeIcons.magnifyingGlass),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, i) {
                      final item = filteredProducts[i];
                      Widget leadingWidget;
                      if (item['image'] != null && item['image'].toString().isNotEmpty) {
                        leadingWidget = Image.file(File(item['image']), width: 40, height: 40, fit: BoxFit.cover);
                      } else {
                        IconData faIcon;
                        switch (item['category']?.toString().toLowerCase()) {
                          case 'fertilizer':
                            faIcon = FontAwesomeIcons.leaf;
                            break;
                          case 'seeds':
                            faIcon = FontAwesomeIcons.seedling;
                            break;
                          case 'pesticide':
                            faIcon = FontAwesomeIcons.bug;
                            break;
                          case 'feed':
                            faIcon = FontAwesomeIcons.wheatAwn;
                            break;
                          default:
                            faIcon = FontAwesomeIcons.box;
                        }
                        leadingWidget = FaIcon(faIcon, color: Colors.green, size: 28);
                      }
                      return Card(
                        color: const Color(0xFFFFF8E1),
                        child: ListTile(
                          leading: leadingWidget,
                          title: Text(item['name'].toString()),
                          subtitle: Text('Buy: KSh ${item['buyingPrice']} | Sell: KSh ${item['sellingPrice']} | Stock: ${item['quantity']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.penToSquare, color: Colors.orange),
                                tooltip: 'Edit/Restock',
                                onPressed: () async {
                                  final quantityController = TextEditingController(text: item['quantity'].toString());
                                  DateTime? expiryDate = item['expiry'] != null && item['expiry'].toString().isNotEmpty
                                      ? DateTime.tryParse(item['expiry'].toString())
                                      : null;
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Edit ${item['name']}'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            controller: quantityController,
                                            decoration: const InputDecoration(labelText: 'New Quantity'),
                                            keyboardType: TextInputType.number,
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(expiryDate == null
                                                    ? 'No expiry date selected'
                                                    : 'Expiry: ${expiryDate?.toLocal().toString().split(' ')[0]}'),
                                              ),
                                              ElevatedButton.icon(
                                                icon: const Icon(Icons.calendar_today),
                                                label: const Text('Pick Expiry'),
                                                onPressed: () async {
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: expiryDate ?? DateTime.now(),
                                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                                  );
                                                  if (picked != null) {
                                                    expiryDate = picked;
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final updated = Map<String, dynamic>.from(item);
                                            updated['quantity'] = int.tryParse(quantityController.text) ?? item['quantity'];
                                            updated['expiry'] = expiryDate?.toIso8601String();
                                            await POSDatabase.updateProduct(updated);
                                            Navigator.pop(context);
                                            _loadProducts();
                                          },
                                          child: const Text('Update'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () => _deleteProduct(item['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
