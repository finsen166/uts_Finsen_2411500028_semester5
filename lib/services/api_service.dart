// lib/services/api_service.dart
import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ApiService {
  late final Dio _dio;
  static const String _baseUrl = 'https://dummyjson.com';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  // Get list of products
  Future<List<ProductModel>> getProducts({int limit = 30, int skip = 0}) async {
    final response = await _dio.get(
      '/products',
      queryParameters: {
        'limit': limit,
        'skip': skip,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final products = (data['products'] as List<dynamic>)
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return products;
  }

  // Get product by ID
  Future<ProductModel> getProductById(int id) async {
    final response = await _dio.get('/products/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }
}
