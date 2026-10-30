// lib/providers/api_provider.dart
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'view_state.dart';

class ApiProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ViewState _state = ViewState.initial;
  String? _errorMessage;
  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  bool _isLoadingDetail = false;
  String? _detailError;
  bool _hasFetched = false;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get detailError => _detailError;

  void _setState(ViewState state, {String? error}) {
    _state = state;
    _errorMessage = error;
    notifyListeners();
  }

  Future<void> fetchProducts({bool force = false}) async {
    if (_hasFetched && !force) return;

    _setState(ViewState.loading);
    try {
      final products = await _apiService.getProducts();
      _products = products;
      _hasFetched = true;
      _setState(products.isEmpty ? ViewState.empty : ViewState.loaded);
    } on DioException catch (e) {
      _setState(ViewState.error, error: _getDioErrorMessage(e));
    } catch (e) {
      _setState(ViewState.error, error: 'Terjadi kesalahan: $e');
    }
  }

  Future<void> fetchProductById(int id) async {
    _isLoadingDetail = true;
    _detailError = null;
    _selectedProduct = null;
    notifyListeners();

    try {
      _selectedProduct = await _apiService.getProductById(id);
      _isLoadingDetail = false;
      notifyListeners();
    } on DioException catch (e) {
      _isLoadingDetail = false;
      _detailError = _getDioErrorMessage(e);
      notifyListeners();
    } catch (e) {
      _isLoadingDetail = false;
      _detailError = 'Terjadi kesalahan: $e';
      notifyListeners();
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      case DioExceptionType.badResponse:
        return 'Server mengembalikan error ${e.response?.statusCode ?? ""}';
      default:
        return 'Gagal mengambil data: ${e.message}';
    }
  }

  void retry() {
    _hasFetched = false;
    fetchProducts(force: true);
  }
}
