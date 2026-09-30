import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart.dart';
import '../models/product.dart';

final ValueNotifier<CartService> cartService = ValueNotifier(CartService());

class CartService {
  final ValueNotifier<Cart?> cartNotifier = ValueNotifier<Cart?>(null);
  String? appliedPromoCode;
  double promoDiscountPercent = 0.0;

  Cart? get currentCart => cartNotifier.value;

  void initCart({int userId = 1}) {
    cartNotifier.value ??= Cart(
      id: 1,
      products: [],
      total: 0.0,
      discountedTotal: 0.0,
      userId: userId,
      totalProducts: 0,
      totalQuantity: 0,
    );
  }

  Future<Cart?> getCartByUserId(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('https://dummyjson.com/carts/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cartsList = data['carts'] as List?;
        if (cartsList != null && cartsList.isNotEmpty) {
          final fetchedCart = Cart.fromJson(cartsList.first);
          cartNotifier.value = fetchedCart;
          return fetchedCart;
        }
      }
    } catch (_) {}

    if (cartNotifier.value != null && cartNotifier.value!.userId == userId) {
      return cartNotifier.value;
    }

    initCart(userId: userId);
    return cartNotifier.value;
  }

  Future<void> addToCart({
    required int userId,
    required List<Map<String, dynamic>> products,
  }) async {
    initCart(userId: userId);

    try {
      final response = await http.post(
        Uri.parse('https://dummyjson.com/carts/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'products': products,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final incomingCart = Cart.fromJson(data);
        _mergeProductsIntoCart(incomingCart.products);
        return;
      }
    } catch (_) {
      for (var item in products) {
        final id = item['id'] as int;
        final qty = (item['quantity'] as int?) ?? 1;
        incrementQuantity(id, by: qty);
      }
    }
  }

  void addProduct(Product product) {
    initCart();
    final currentProducts =
        List<CartProduct>.from(cartNotifier.value?.products ?? []);
    final index = currentProducts.indexWhere((p) => p.id == product.id);

    if (index != -1) {
      final existing = currentProducts[index];
      final newQty = existing.quantity + 1;
      final newTotal = existing.price * newQty;
      final newDiscountedTotal =
          (existing.price * (1.0 - (existing.discountPercentage / 100.0))) *
              newQty;

      currentProducts[index] = CartProduct(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: newQty,
        total: newTotal,
        discountPercentage: existing.discountPercentage,
        discountedTotal: newDiscountedTotal,
        thumbnail: existing.thumbnail,
      );
    } else {
      final price = product.price;
      final discount = product.discountPercentage;
      final discountedPrice = price * (1.0 - (discount / 100.0));

      currentProducts.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: price,
          quantity: 1,
          total: price,
          discountPercentage: discount,
          discountedTotal: discountedPrice,
          thumbnail: product.thumbnail.isNotEmpty
              ? product.thumbnail
              : (product.images.isNotEmpty ? product.images.first : ''),
        ),
      );
    }

    _recalculateCart(currentProducts);
  }

  void _mergeProductsIntoCart(List<CartProduct> newProducts) {
    final currentProducts =
        List<CartProduct>.from(cartNotifier.value?.products ?? []);

    for (var incoming in newProducts) {
      final index = currentProducts.indexWhere((p) => p.id == incoming.id);
      if (index != -1) {
        final existing = currentProducts[index];
        final newQty = existing.quantity + incoming.quantity;
        final newTotal = existing.price * newQty;
        final newDiscountedTotal =
            (existing.price * (1.0 - (existing.discountPercentage / 100.0))) *
                newQty;

        currentProducts[index] = CartProduct(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: newQty,
          total: newTotal,
          discountPercentage: existing.discountPercentage,
          discountedTotal: newDiscountedTotal,
          thumbnail: existing.thumbnail,
        );
      } else {
        currentProducts.add(incoming);
      }
    }

    _recalculateCart(currentProducts);
  }

  void incrementQuantity(int productId, {int by = 1}) {
    if (cartNotifier.value == null) return;
    final currentProducts =
        List<CartProduct>.from(cartNotifier.value!.products);
    final index = currentProducts.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final existing = currentProducts[index];
    final newQty = existing.quantity + by;
    final newTotal = existing.price * newQty;
    final newDiscountedTotal =
        (existing.price * (1.0 - (existing.discountPercentage / 100.0))) *
            newQty;

    currentProducts[index] = CartProduct(
      id: existing.id,
      title: existing.title,
      price: existing.price,
      quantity: newQty,
      total: newTotal,
      discountPercentage: existing.discountPercentage,
      discountedTotal: newDiscountedTotal,
      thumbnail: existing.thumbnail,
    );

    _recalculateCart(currentProducts);
  }

  void decrementQuantity(int productId) {
    if (cartNotifier.value == null) return;
    final currentProducts =
        List<CartProduct>.from(cartNotifier.value!.products);
    final index = currentProducts.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final existing = currentProducts[index];
    if (existing.quantity > 1) {
      final newQty = existing.quantity - 1;
      final newTotal = existing.price * newQty;
      final newDiscountedTotal =
          (existing.price * (1.0 - (existing.discountPercentage / 100.0))) *
              newQty;

      currentProducts[index] = CartProduct(
        id: existing.id,
        title: existing.title,
        price: existing.price,
        quantity: newQty,
        total: newTotal,
        discountPercentage: existing.discountPercentage,
        discountedTotal: newDiscountedTotal,
        thumbnail: existing.thumbnail,
      );
    } else {
      currentProducts.removeAt(index);
    }

    _recalculateCart(currentProducts);
  }

  void removeProduct(int productId) {
    if (cartNotifier.value == null) return;
    final currentProducts =
        List<CartProduct>.from(cartNotifier.value!.products)
          ..removeWhere((p) => p.id == productId);
    _recalculateCart(currentProducts);
  }

  void clearCart() {
    appliedPromoCode = null;
    promoDiscountPercent = 0.0;
    initCart();
    _recalculateCart([]);
  }

  bool applyPromo(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode == 'SAVE10') {
      promoDiscountPercent = 0.10;
      appliedPromoCode = cleanCode;
      _recalculateCart(cartNotifier.value?.products ?? []);
      return true;
    } else if (cleanCode == 'SAVE20' || cleanCode == 'ADVPROG') {
      promoDiscountPercent = 0.20;
      appliedPromoCode = cleanCode;
      _recalculateCart(cartNotifier.value?.products ?? []);
      return true;
    }
    return false;
  }

  void _recalculateCart(List<CartProduct> products) {
    double totalRaw = 0.0;
    double totalDiscounted = 0.0;
    int totalQty = 0;

    for (var p in products) {
      totalRaw += p.total;
      totalDiscounted += p.discountedTotal;
      totalQty += p.quantity;
    }

    final finalDiscountedTotal =
        totalDiscounted * (1.0 - promoDiscountPercent);

    cartNotifier.value = Cart(
      id: cartNotifier.value?.id ?? 1,
      products: products,
      total: totalRaw,
      discountedTotal: finalDiscountedTotal > 0 ? finalDiscountedTotal : 0.0,
      userId: cartNotifier.value?.userId ?? 1,
      totalProducts: products.length,
      totalQuantity: totalQty,
    );
  }
}