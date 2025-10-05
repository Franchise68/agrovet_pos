import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import '../database.dart';
import '../widgets/main_sidebar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  // Remove _buildMainDrawer, use MainSidebar in Scaffold.drawer
  // Helper to print receipt with QR code
  Future<void> _printReceiptWithQR(BuildContext context) async {
    String qrData = cart.map((p) => '${p['id']}:${cartQuantities[p['id']] ?? 1}').join(',');
    final pdf = pw.Document();
    // Get company name from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final companyName = prefs.getString('company_name') ?? 'Agrovet POS';
    // Generate QR code image as Uint8List
    final qrPainter = QrPainter(
      data: qrData,
      version: 4, // Use a fixed version or calculate based on data length
      gapless: false,
    );
    final qrByteData = await qrPainter.toImageData(120);
    final qrBytes = qrByteData != null ? qrByteData.buffer.asUint8List() : Uint8List(0);
    double total = cart.fold<double>(0.0, (sum, p) {
      int pid = p['id'];
      int qty = cartQuantities[pid] ?? 1;
      return sum + (p['sellingPrice'] ?? 0.0) * qty;
    });
    double balance = paymentAmount - total;
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$companyName Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Products Sold:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Column(
                children: cart.map((product) {
                  int pid = product['id'];
                  int qty = cartQuantities[pid] ?? 1;
                  return pw.Text('${product['name']} x $qty - KSh ${(product['sellingPrice'] ?? 0.0) * qty}');
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Total: KSh $total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Amount Paid: KSh $paymentAmount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Balance: KSh $balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Payment Mode: $paymentMode'),
              if (paymentMode != 'Cash') pw.Text('Statement Code: $mpesaCode'),
              pw.SizedBox(height: 16),
              pw.Text('Date: ${DateTime.now().toString()}'),
              pw.SizedBox(height: 16),
              pw.Text('Scan QR code to verify sale:'),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(qrBytes),
                  width: 120,
                  height: 120,
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt sent to printer.')));
  }

  // Helper to download receipt with QR code
  Future<void> _downloadReceiptWithQR(BuildContext context) async {
    String qrData = cart.map((p) => '${p['id']}:${cartQuantities[p['id']] ?? 1}').join(',');
    final pdf = pw.Document();
    final qrPainter = QrPainter(
      data: qrData,
      version: 4,
      gapless: false,
    );
    final qrByteData = await qrPainter.toImageData(120);
    final qrBytes = qrByteData != null ? qrByteData.buffer.asUint8List() : Uint8List(0);
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Agrovet POS Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Products Sold:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Column(
                children: cart.map((product) {
                  int pid = product['id'];
                  int qty = cartQuantities[pid] ?? 1;
                  return pw.Text('${product['name']} x $qty - KSh ${(product['sellingPrice'] ?? 0.0) * qty}');
                }).toList(),
              ),
              pw.SizedBox(height: 16),
              pw.Text('Total: KSh ${cart.fold<double>(0.0, (sum, p) {
                int pid = p['id'];
                int qty = cartQuantities[pid] ?? 1;
                return sum + (p['sellingPrice'] ?? 0.0) * qty;
              })}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Payment Mode: $paymentMode'),
              if (paymentMode != 'Cash') pw.Text('Statement Code: $mpesaCode'),
              pw.SizedBox(height: 16),
              pw.Text('Date: ${DateTime.now().toString()}'),
              pw.SizedBox(height: 16),
              pw.Text('Scan QR code to verify sale:'),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(qrBytes),
                  width: 120,
                  height: 120,
                ),
              ),
            ],
          );
        },
      ),
    );
    // Save to Downloads folder
    final downloadsDir = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    final filePath = '${downloadsDir.path}/Agrovet_Receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Receipt downloaded to $filePath with QR code.')));
  }
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> inventory = [];
  List<Map<String, dynamic>> cart = [];
  Map<int, int> cartQuantities = {}; // productId -> quantity
  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final products = await POSDatabase.getProducts();
    setState(() {
      inventory = products;
    });
  }
  String paymentMode = 'Cash';
  String mpesaCode = '';
  double paymentAmount = 0.0;

  List<Map<String, dynamic>> get filteredInventory {
    if (searchQuery.isEmpty) return inventory;
    return inventory.where((product) =>
      product['name'].toString().toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainSidebar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search product by name',
                prefixIcon: FaIcon(FontAwesomeIcons.magnifyingGlass),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
            const SizedBox(height: 16),
            const Text('Available Products', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: filteredInventory.map((product) {
                  Widget leadingWidget;
                  if (product['image'] != null && product['image'].toString().isNotEmpty) {
                    leadingWidget = Image.file(File(product['image']), width: 40, height: 40, fit: BoxFit.cover);
                  } else {
                    IconData faIcon = FontAwesomeIcons.box;
                    if (product['name'].toString().toLowerCase().contains('seed')) faIcon = FontAwesomeIcons.seedling;
                    if (product['name'].toString().toLowerCase().contains('fertilizer')) faIcon = FontAwesomeIcons.leaf;
                    if (product['name'].toString().toLowerCase().contains('feed')) faIcon = FontAwesomeIcons.wheatAwn;
                    if (product['name'].toString().toLowerCase().contains('pesticide')) faIcon = FontAwesomeIcons.bug;
                    leadingWidget = FaIcon(faIcon, color: Colors.green, size: 28);
                  }
                  int productId = product['id'];
                  return ListTile(
                    leading: leadingWidget,
                    title: Text(product['name']),
                    subtitle: Text('Sell: KSh ${product['sellingPrice']} | Stock: ${product['quantity']}'),
                    trailing: IconButton(
                      icon: const FaIcon(FontAwesomeIcons.cartPlus, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          if (!cart.any((p) => p['id'] == productId)) {
                            cart.add(product);
                            cartQuantities[productId] = 1;
                          } else {
                            cartQuantities[productId] = (cartQuantities[productId] ?? 1) + 1;
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            if (cart.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        FaIcon(FontAwesomeIcons.cartShopping, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const Divider(),
                    ...cart.map((product) {
                      int pid = product['id'];
                      int qty = cartQuantities[pid] ?? 1;
                      double price = (product['sellingPrice'] ?? 0.0) * qty;
                      return ListTile(
                        leading: product['image'] != null && product['image'].toString().isNotEmpty
                          ? Image.file(File(product['image']), width: 32, height: 32, fit: BoxFit.cover)
                          : const FaIcon(FontAwesomeIcons.box, color: Colors.green, size: 24),
                        title: Text(product['name']),
                        subtitle: Text('Qty: $qty | Total: KSh $price'),
                        trailing: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.trash, color: Colors.red),
                          tooltip: 'Remove',
                          onPressed: () {
                            setState(() {
                              cart.removeWhere((p) => p['id'] == pid);
                              cartQuantities.remove(pid);
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const FaIcon(FontAwesomeIcons.cashRegister),
                label: const Text('Proceed to Sale'),
                onPressed: () => _showCompleteSaleDialog(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCompleteSaleDialog(BuildContext context) {
  if (cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty. Add products to complete sale.'), backgroundColor: Colors.red));
    return;
  }
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          double total = cart.fold<double>(0.0, (sum, product) {
            int pid = product['id'];
            int qty = cartQuantities[pid] ?? 1;
            return sum + (product['sellingPrice'] ?? 0.0) * qty;
          });
          String? amountError;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Complete Sale', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const FaIcon(FontAwesomeIcons.print, color: Colors.white),
                          tooltip: 'Print Receipt',
                          onPressed: () async {
                            await _printReceiptWithQR(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Products Selected:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...cart.map((product) {
                            int pid = product['id'];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(product['name'])),
                                SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    initialValue: cartQuantities[pid].toString(),
                                    decoration: const InputDecoration(labelText: 'Qty'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      int qty = int.tryParse(val) ?? 1;
                                      setState(() {
                                        cartQuantities[pid] = qty;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 16),
                          Text('Total: KSh $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Payment Mode',
                              prefixIcon: FaIcon(FontAwesomeIcons.moneyBillWave, color: Colors.green),
                            ),
                            value: paymentMode,
                            items: ['Cash', 'Mpesa', 'Airtel Money'].map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode),
                            )).toList(),
                            onChanged: (val) => setState(() => paymentMode = val ?? 'Cash'),
                          ),
                          if (paymentMode == 'Cash') ...[
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Amount Paid',
                                errorText: amountError,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {
                                  paymentAmount = double.tryParse(val) ?? 0.0;
                                  amountError = null;
                                });
                              },
                            ),
                          ] else ...[
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Statement Code'),
                              onChanged: (val) => mpesaCode = val,
                            ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Amount Paid',
                                errorText: amountError,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                setState(() {
                                  paymentAmount = double.tryParse(val) ?? 0.0;
                                  amountError = null;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          child: const Text('Complete Sale'),
                          onPressed: () async {
                            // Validate payment fields
                            if (paymentMode == 'Cash') {
                              if (paymentAmount <= 0) {
                                setState(() { amountError = 'Enter payment amount'; });
                                return;
                              }
                              if (paymentAmount < total) {
                                setState(() { amountError = 'Amount paid is less than total price'; });
                                return;
                              }
                            } else {
                              if (mpesaCode.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter statement code for mobile payment.'), backgroundColor: Colors.red));
                                return;
                              }
                              if (paymentAmount <= 0) {
                                setState(() { amountError = 'Enter payment amount'; });
                                return;
                              }
                              if (paymentAmount < total) {
                                setState(() { amountError = 'Amount paid is less than total price'; });
                                return;
                              }
                            }
                            bool outOfStock = false;
                            for (var product in cart) {
                              int pid = product['id'];
                              int qty = cartQuantities[pid] ?? 1;
                              double totalPrice = (product['sellingPrice'] ?? 0.0) * qty;
                              await POSDatabase.insertSale({
                                'productId': pid,
                                'customerId': null,
                                'quantity': qty,
                                'total': totalPrice,
                                'date': DateTime.now().toIso8601String(),
                              });
                              var updatedProduct = Map<String, dynamic>.from(product);
                              updatedProduct['quantity'] = (product['quantity'] ?? 0) - qty;
                              await POSDatabase.updateProduct(updatedProduct);
                              if (updatedProduct['quantity'] <= 0) {
                                outOfStock = true;
                              }
                            }
                            // Show dialog for receipt options, then close sale dialog and show success message
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Receipt Options'),
                                content: const Text('Would you like to print the receipt, download it, or complete the sale?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Download'),
                                    onPressed: () async {
                                      await _downloadReceiptWithQR(context);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Print'),
                                    onPressed: () async {
                                      await _printReceiptWithQR(context);
                                      Navigator.pop(ctx);
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Complete'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully.'), backgroundColor: Colors.green));
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Cancel Sale'),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      setState(() {
                                        cart.clear();
                                        cartQuantities.clear();
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale cancelled.'), backgroundColor: Colors.red));
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('No Receipt'),
                                    onPressed: () => Navigator.pop(ctx),
                                  ),
                                ],
                              ),
                            );
                            Navigator.pop(context); // Close sale dialog after receipt option
                            setState(() {
                              cart.clear();
                              cartQuantities.clear();
                            });
                            if (outOfStock) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Some products are out of stock!'), backgroundColor: Colors.red));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed.')));
                            }
                            _loadInventory();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }
}
