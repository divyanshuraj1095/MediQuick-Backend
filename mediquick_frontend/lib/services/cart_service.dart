import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String image;
  final bool requiresPrescription;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.quantity,
    this.requiresPrescription = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'quantity': quantity,
        'requiresPrescription': requiresPrescription,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      image: json['image'],
      quantity: json['quantity'],
      requiresPrescription: json['requiresPrescription'] ?? false,
    );
  }

  double get subtotal => price * quantity;
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();

  factory CartService() => _instance;

  CartService._internal() {
    _loadCart();
  }

  List<CartItem> _items = [];
  bool _isInit = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isInit => _isInit;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.subtotal);

  bool get hasPrescriptionItems =>
      _items.any((item) => item.requiresPrescription);

  List<CartItem> get prescriptionItems =>
      _items.where((item) => item.requiresPrescription).toList();

  String get formattedTotalPrice {
    final rupees = totalPrice.toStringAsFixed(2);
    final parts = rupees.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    if (intPart.length <= 3) return '₹$rupees';

    final last3 = intPart.substring(intPart.length - 3);
    var remaining = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    final formatted = '${groups.join(',')},$last3.$decPart';
    return '₹$formatted';
  }

  void addItem({
    required String id,
    required String name,
    required double price,
    required String image,
    required int quantity,
    bool requiresPrescription = false,
  }) {
    final existingIndex = _items.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(
        id: id,
        name: name,
        price: price,
        image: image,
        quantity: quantity,
        requiresPrescription: requiresPrescription,
      ));
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(id);
      return;
    }
    final existingIndex = _items.indexWhere((item) => item.id == id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = newQuantity;
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString('cart_items', jsonEncode(jsonList));
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartStr = prefs.getString('cart_items');
    if (cartStr != null && cartStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(cartStr) as List<dynamic>;
        _items = decoded.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error decoding cart: $e');
        _items = [];
      }
    }
    _isInit = true;
    notifyListeners();
  }
}
