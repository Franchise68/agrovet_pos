import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database.dart';
import 'pages/dashboard_page.dart';
import 'pages/sales_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/inventory_page.dart';
import 'pages/farm_services_page.dart';
import 'pages/customers_page.dart';
import 'pages/auth_page.dart';

import 'desktop_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://anxmsyuturtnqhbdkgyd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFueG1zeXV0dXJ0bnFoYmRrZ3lkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkyNTA4ODEsImV4cCI6MjA3NDgyNjg4MX0.TgWVHkbMwB_HyPSPG1cAWL05VKB4aoh6tlgiiEfThRw',
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const AgrovetApp(),
    ),
  );
}

class AgrovetApp extends StatelessWidget {
  // Sync offline accounts to Supabase when online
  static Future<void> syncOfflineAccounts() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('offline_users') ?? [];
      final client = Supabase.instance.client;
      for (final userJson in usersJson) {
        final parts = userJson.split('|');
        if (parts.length >= 4) {
          final name = parts[0];
          final email = parts[1];
          final password = parts[2];
          final mobile = parts[3];
          try {
            await client.auth.signUp(email: email, password: password, data: {
              'name': name,
              'mobile': mobile,
            });
          } catch (_) {}
        }
      }
      // Clear offline accounts after sync
      await prefs.setStringList('offline_users', []);
    }
  }
  static Future<void> syncToSupabase() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      try {
        final client = Supabase.instance.client;
        final dbProducts = await POSDatabase.getProducts();
        await client.from('products').upsert(dbProducts);
        final dbCustomers = await POSDatabase.getCustomers();
        await client.from('customers').upsert(dbCustomers);
        final dbSales = await POSDatabase.getSales();
        await client.from('sales').upsert(dbSales);
        final dbFarmServices = await POSDatabase.getFarmServices();
        await client.from('farm_services').upsert(dbFarmServices);
        final dbInventory = await POSDatabase.getInventory();
        await client.from('inventory').upsert(dbInventory);
      } catch (_) {}
    }
  }

  void startConnectivitySync() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile || result == ConnectivityResult.wifi) {
        syncToSupabase();
        syncOfflineAccounts();
      }
    });
  }
  void startAutoSync() {
    Future<void> syncIfOnline() async {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
        try {
          final client = Supabase.instance.client;
          final dbProducts = await POSDatabase.getProducts();
          await client.from('products').upsert(dbProducts);
          final dbCustomers = await POSDatabase.getCustomers();
          await client.from('customers').upsert(dbCustomers);
          final dbSales = await POSDatabase.getSales();
          await client.from('sales').upsert(dbSales);
          final dbFarmServices = await POSDatabase.getFarmServices();
          await client.from('farm_services').upsert(dbFarmServices);
          final dbInventory = await POSDatabase.getInventory();
          await client.from('inventory').upsert(dbInventory);
        } catch (_) {}
      }
    }
    // Run every 5 minutes
    Future.doWhile(() async {
      await syncIfOnline();
      await Future.delayed(const Duration(minutes: 5));
      return true;
    });
  }
  const AgrovetApp({super.key});

  @override
  Widget build(BuildContext context) {
  // Start connectivity-based auto-sync when app launches
  startConnectivitySync();
  // Start auto-sync when app launches
  startAutoSync();
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        // Use DesktopHomePage for Windows desktop, otherwise use normal routing
        if (Theme.of(context).platform == TargetPlatform.windows) {
          return MaterialApp(
            title: 'Agrovet POS Desktop',
            themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            debugShowCheckedModeBanner: false,
            home: const DesktopHomePage(),
          );
        } else {
          return MaterialApp(
            title: 'Agrovet POS',
            themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            debugShowCheckedModeBanner: false,
            initialRoute: '/auth',
            routes: {
              '/auth': (context) => const AuthPage(),
              '/dashboard': (context) => const DashboardPage(),
              '/inventory': (context) => const InventoryPage(),
              '/sales': (context) => const SalesPage(),
              '/farm_services': (context) => const FarmServicesPage(),
              '/customers': (context) => const CustomersPage(),
              '/reports': (context) => const ReportsPage(),
              '/settings': (context) => const SettingsPage(),
            },
          );
        }
      },
    );
  }
}

