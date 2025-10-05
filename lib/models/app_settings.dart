import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  String shopName = '';
  String currency = 'KSh';
  bool darkTheme = false;

  AppSettings() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    shopName = prefs.getString('shopName') ?? '';
    currency = prefs.getString('currency') ?? 'KSh';
    darkTheme = prefs.getBool('darkTheme') ?? false;
    notifyListeners();
  }

  Future<void> updateShopName(String name) async {
    shopName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopName', name);
    notifyListeners();
  }

  Future<void> updateCurrency(String value) async {
    currency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    darkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', value);
    notifyListeners();
  }
}
