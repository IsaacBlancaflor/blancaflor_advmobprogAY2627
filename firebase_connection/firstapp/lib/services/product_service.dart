import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products';

  // limit=0 returns the entire catalog (all 194 items) from DummyJSON
  Future<List<Product>> getProducts({int limit = 0}) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl?limit=$limit'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsJson = data['products'] ?? [];
        return productsJson.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/search?q=$query&limit=0'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List productsJson = data['products'] ?? [];
        return productsJson.map((e) => Product.fromJson(e)).toList();
      } else {
        throw Exception('Failed to search products');
      }
    } catch (e) {
      rethrow;
    }
  }
}