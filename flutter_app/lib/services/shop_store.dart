import 'dart:convert';

import '../models/service_models.dart';
import 'secure_storage.dart';

abstract interface class ShopStore {
  Future<List<CartItem>> loadCart(String accountKey);

  Future<void> saveCart(String accountKey, List<CartItem> items);

  Future<void> clearCart(String accountKey);
}

class SecureShopStore implements ShopStore {
  String _cartKey(String accountKey) => 'new_energy_shop_cart_v1_$accountKey';

  @override
  Future<List<CartItem>> loadCart(String accountKey) async {
    final raw = await appSecureStorage.read(key: _cartKey(accountKey));
    if (raw == null || raw.isEmpty) return <CartItem>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <CartItem>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .where((item) => item.product.id > 0)
          .toList();
    } on FormatException {
      return <CartItem>[];
    }
  }

  @override
  Future<void> saveCart(String accountKey, List<CartItem> items) {
    return appSecureStorage.write(
      key: _cartKey(accountKey),
      value: jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> clearCart(String accountKey) {
    return appSecureStorage.delete(key: _cartKey(accountKey));
  }
}

class MemoryShopStore implements ShopStore {
  MemoryShopStore([List<CartItem> initial = const <CartItem>[]])
    : _items = List<CartItem>.of(initial);

  List<CartItem> _items;

  @override
  Future<List<CartItem>> loadCart(String accountKey) async {
    return List<CartItem>.of(_items);
  }

  @override
  Future<void> saveCart(String accountKey, List<CartItem> items) async {
    _items = List<CartItem>.of(items);
  }

  @override
  Future<void> clearCart(String accountKey) async {
    _items = <CartItem>[];
  }
}
