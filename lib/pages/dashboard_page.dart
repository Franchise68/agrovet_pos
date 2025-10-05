import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database.dart';
import '../widgets/main_sidebar.dart';

  Future<Map<String, String>> _getCompanyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('company_name') ?? 'Agrovet POS';
    final image = prefs.getString('company_image') ?? '';
    return {'name': name, 'image': image};
  }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      loading = true;
    });
    dashboardData = await _getDashboardData();
    setState(() {
      loading = false;
    });
  }

  Future<Map<String, dynamic>> _getDashboardData() async {
  final products = await POSDatabase.getProducts();
  final sales = await POSDatabase.getSales();
  final farmServices = await POSDatabase.getFarmServices();
  // Import analytics from reports logic
  double totalRevenue = sales.fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0));
  int itemsSold = sales.fold(0, (sum, s) => sum + ((s['quantity'] ?? 0) as int));
  double profitMargin = sales.isNotEmpty ? (totalRevenue / (sales.fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0))) * 100) : 0;
    int totalProducts = products.length;
    int totalFarmServices = farmServices.length;
    int totalSales = sales.length;
    String today = DateTime.now().toIso8601String().substring(0, 10);
    double todaysSales = sales
        .where((s) => (s['date'] ?? '').toString().startsWith(today))
        .fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0));
    int lowStockItems = products.where((p) => (p['quantity'] ?? 0) <= (p['minStock'] ?? 0)).length;
    int pendingFarmServices = farmServices.where((fs) => (fs['status'] ?? '') == 'Pending').length;
    int completedFarmServices = farmServices.where((fs) => (fs['status'] ?? '') == 'Completed').length;
    List<double> salesTrend = [];
    for (int i = 6; i >= 0; i--) {
      String day = DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      double daySales = sales
          .where((s) => (s['date'] ?? '').toString().startsWith(day))
          .fold(0.0, (sum, s) => sum + (s['total'] ?? 0.0));
      salesTrend.add(daySales);
    }
    Map<String, double> productCategories = {};
    for (var p in products) {
      String cat = p['category'] ?? 'Other';
      productCategories[cat] = (productCategories[cat] ?? 0) + 1;
    }
  List<Map<String, dynamic>> latestTransactions = sales.reversed.take(3).map((s) {
      final prod = products.firstWhere(
        (p) => p['id'] == s['productId'],
        orElse: () => {'name': 'Unknown'}
      );
      return {
        'product': prod['name'],
        'amount': s['total'] ?? 0.0,
        'date': s['date'] ?? '',
      };
    }).toList();
    List<Map<String, dynamic>> latestFarmBookings = farmServices.reversed.take(5).map((fs) {
      return {
        'service': fs['name'] ?? 'Unknown',
        'customer': fs['customerName'] ?? 'Unknown',
        'status': fs['status'] ?? '',
        'due': fs['due'] ?? '',
      };
    }).toList();
    List<String> updates = [];
    if (lowStockItems > 0) updates.add('Low stock alert for $lowStockItems items');
    if (pendingFarmServices > 0) updates.add('Pending farm services: $pendingFarmServices');
    updates.add('Inventory: $totalProducts products');
    updates.add('Farm Services: $totalFarmServices booked, $completedFarmServices completed');
    updates.add('Sales today: KSh $todaysSales');
    updates.add('Total sales: $totalSales');
    return {
      'totalProducts': totalProducts,
      'todaysSales': todaysSales,
      'lowStockItems': lowStockItems,
      'salesTrend': salesTrend,
      'productCategories': productCategories,
      'latestTransactions': latestTransactions,
      'latestFarmBookings': latestFarmBookings,
      'updates': updates,
      'totalFarmServices': totalFarmServices,
      'pendingFarmServices': pendingFarmServices,
      'completedFarmServices': completedFarmServices,
      'totalSales': totalSales,
      'dashboardTotalRevenue': totalRevenue,
      'dashboardItemsSold': itemsSold,
      'dashboardProfitMargin': profitMargin,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const FaIcon(FontAwesomeIcons.bars),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const MainSidebar(),
      body: loading || dashboardData == null
          ? const Center(child: CircularProgressIndicator())
          : Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, String>>(
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
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: companyImage,
                                  backgroundColor: Colors.green.shade200,
                                  child: companyImage == null ? const Icon(Icons.business, size: 28, color: Colors.white) : null,
                                ),
                                const SizedBox(width: 16),
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                              ],
                            );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Welcome to Agrovet POS!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _statCardFa(FontAwesomeIcons.boxesStacked, 'Total Products', dashboardData!['totalProducts'].toString(), Colors.deepOrange)),
                          const SizedBox(width: 16),
                          Expanded(child: _statCardFa(FontAwesomeIcons.moneyBillWave, "Today's Sales", 'KSh ${dashboardData!['todaysSales']}', Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _statCardFa(FontAwesomeIcons.triangleExclamation, 'Low Stock', '${dashboardData!['lowStockItems']} items', Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: _statCardFa(FontAwesomeIcons.tractor, 'Farm Services Booked', dashboardData!['totalFarmServices'].toString(), Colors.blue)),
                          const SizedBox(width: 16),
                          Expanded(child: _statCardFa(FontAwesomeIcons.hourglassHalf, 'Pending Farm Services', dashboardData!['pendingFarmServices'].toString(), Colors.orange)),
                          const SizedBox(width: 16),
                          Expanded(child: _statCardFa(FontAwesomeIcons.circleCheck, 'Completed Farm Services', dashboardData!['completedFarmServices'].toString(), Colors.green)),
                          const SizedBox(width: 16),
                          Expanded(child: _statCardFa(FontAwesomeIcons.cartShopping, 'Total Sales', dashboardData!['totalSales'].toString(), Colors.purple)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('Sales Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 220, child: _buildBarChart(List<double>.from(dashboardData!['salesTrend']))),
                      const SizedBox(height: 32),
                      const Text('Product Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      SizedBox(height: 220, child: _buildPieChart(Map<String, double>.from(dashboardData!['productCategories']))),
                      const SizedBox(height: 32),
                      const Text('Latest Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ...List<Map<String, dynamic>>.from(dashboardData!['latestTransactions']).map((tx) => Card(
                        child: ListTile(
                          leading: const FaIcon(FontAwesomeIcons.fileInvoiceDollar, color: Colors.deepOrange),
                          title: Text(tx['product']),
                          subtitle: Text('KSh ${tx['amount']} - ${tx['date']}'),
                        ),
                      )),
                      const SizedBox(height: 32),
                      const Text('Latest Farm Service Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ...List<Map<String, dynamic>>.from(dashboardData!['latestFarmBookings']).map((fs) => Card(
                        child: ListTile(
                          leading: const FaIcon(FontAwesomeIcons.tractor, color: Colors.blue),
                          title: Text(fs['service']),
                          subtitle: Text('Customer: ${fs['customer']} | Due: ${fs['due']}'),
                          trailing: Text(fs['status'], style: TextStyle(color: fs['status'] == 'Completed' ? Colors.green : Colors.orange)),
                        ),
                      )),
                      const SizedBox(height: 32),
                      const Text('Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ...List<String>.from(dashboardData!['updates']).map((u) => ListTile(
                        leading: const Icon(Icons.update),
                        title: Text(u),
                      )),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
  Widget _statCardFa(IconData icon, String title, String value, Color color) {
    return Card(
      color: const Color(0xFFFFF8E1),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<double> data) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: (data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) * 1.2 : 1),
        barTouchData: const BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    days[value.toInt() % 7],
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: data[i], color: Colors.green, width: 18)]);
        }),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red];
    int idx = 0;
    return PieChart(
      PieChartData(
        sections: data.entries.map((e) {
          final color = colors[idx % colors.length];
          idx++;
          return PieChartSectionData(
            color: color,
            value: e.value,
            title: e.key,
            radius: 40,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }
}
