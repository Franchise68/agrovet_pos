
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/main_sidebar.dart';
import '../database.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Helper to generate sales trend data
  List<Map<String, dynamic>> getSalesTrend() {
    // Group sales by date
    final Map<String, double> trend = {};
    for (var s in sales) {
      final date = s['date']?.toString().substring(0, 10) ?? '';
      trend[date] = (trend[date] ?? 0) + (s['total'] ?? 0.0);
    }
    return trend.entries.map((e) => {'date': e.key, 'total': e.value}).toList();
  }

  // Helper to generate category breakdown data
  Future<Map<String, double>> getCategoryBreakdown() async {
    final products = await POSDatabase.getProducts();
    final Map<String, double> breakdown = {};
    for (var p in products) {
      final cat = p['category'] ?? 'Other';
      breakdown[cat] = (breakdown[cat] ?? 0) + (p['quantity'] ?? 0).toDouble();
    }
    return breakdown;
  }
  List<Map<String, dynamic>> sales = [];
  List<Map<String, dynamic>> filteredSales = [];
  String filter = '';
  double totalRevenue = 0;
  int itemsSold = 0;
  double profitMargin = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbSales = await POSDatabase.getSales();
    setState(() {
      sales = dbSales.reversed.toList();
      filteredSales = sales.take(5).toList();
      totalRevenue = sales.fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0));
  itemsSold = sales.fold(0, (sum, s) => sum + ((s['quantity'] ?? 0) as int));
      profitMargin = sales.isNotEmpty ? (totalRevenue / (sales.fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0))) * 100) : 0;
      loading = false;
    });
  }

  void _filterSales(String value) {
    setState(() {
      filter = value;
      filteredSales = sales.where((s) =>
        s['date'].toString().contains(value) ||
        s['total'].toString().contains(value)
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainSidebar(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reports Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                  const SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: const FaIcon(FontAwesomeIcons.coins, color: Colors.green, size: 28),
                      title: const Text('Total Revenue'),
                      subtitle: Text('KSh $totalRevenue'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Total Revenue Breakdown'),
                            content: SizedBox(
                              width: 300,
                              height: 250,
                              child: ListView(
                                children: sales.map((s) => ListTile(
                                  title: Text('KSh ${s['total']}'),
                                  subtitle: Text('Date: ${s['date']}'),
                                )).toList(),
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const FaIcon(FontAwesomeIcons.cartShopping, color: Colors.blue, size: 28),
                      title: const Text('Items Sold'),
                      subtitle: Text('$itemsSold'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Items Sold Breakdown'),
                            content: SizedBox(
                              width: 300,
                              height: 250,
                              child: ListView(
                                children: sales.map((s) => ListTile(
                                  title: Text('Qty: ${s['quantity']}'),
                                  subtitle: Text('Date: ${s['date']}'),
                                )).toList(),
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const FaIcon(FontAwesomeIcons.percent, color: Colors.orange, size: 28),
                      title: const Text('Profit Margin'),
                      subtitle: Text('${profitMargin.toStringAsFixed(2)}%'),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Profit Margin Details'),
                            content: SizedBox(
                              width: 300,
                              height: 250,
                              child: ListView(
                                children: sales.map((s) => ListTile(
                                  title: Text('KSh ${s['total']}'),
                                  subtitle: Text('Date: ${s['date']}'),
                                )).toList(),
                              ),
                            ),
                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Latest Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Filter by date or amount'),
                    onChanged: _filterSales,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: filteredSales.isEmpty
                        ? const Center(child: Text('No transactions found.'))
                        : ListView.builder(
                            itemCount: filter.isEmpty ? 3 : filteredSales.length,
                            itemBuilder: (context, i) {
                              final tx = filteredSales[i];
                              return Card(
                                child: ListTile(
                                  leading: const FaIcon(FontAwesomeIcons.receipt, color: Colors.indigo),
                                  title: Text('KSh ${tx['total']}'),
                                  subtitle: Text('${tx['date']}'),
                                  trailing: IconButton(
                                    icon: const FaIcon(FontAwesomeIcons.print, color: Colors.grey),
                                    onPressed: () {
                                      // Print logic placeholder
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Print Transaction'),
                                          content: Text('Printing transaction for KSh ${tx['total']} on ${tx['date']}'),
                                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Analysis Tools', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: ListTile(
                            leading: const FaIcon(FontAwesomeIcons.chartLine, color: Colors.green),
                            title: const Text('Sales Trend'),
                            subtitle: const Text('View sales trend over time'),
                            onTap: () {
                              final trend = getSalesTrend();
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Sales Trend'),
                                  content: SizedBox(
                                    width: 300,
                                    height: 250,
                                    child: ListView(
                                      children: trend.map((e) => ListTile(
                                        title: Text(e['date']),
                                        trailing: Text('KSh ${e['total'].toStringAsFixed(2)}'),
                                      )).toList(),
                                    ),
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: ListTile(
                            leading: const FaIcon(FontAwesomeIcons.pieChart, color: Colors.orange),
                            title: const Text('Category Breakdown'),
                            subtitle: const Text('View product category breakdown'),
                            onTap: () async {
                              final breakdown = await getCategoryBreakdown();
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Category Breakdown'),
                                  content: SizedBox(
                                    width: 300,
                                    height: 250,
                                    child: ListView(
                                      children: breakdown.entries.map((e) => ListTile(
                                        title: Text(e.key),
                                        trailing: Text(e.value.toStringAsFixed(0)),
                                      )).toList(),
                                    ),
                                  ),
                                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
