import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CompareProvider extends ChangeNotifier {
  final ApiService _api;

  final List<ProductSearch> _selectedProducts = [];
  List<Product> _comparedProducts = [];
  int? _bestHealthScoreId;
  int? _bestNutriScoreId;
  bool _isLoading = false;
  String? _error;

  CompareProvider(this._api);

  List<ProductSearch> get selectedProducts => _selectedProducts;
  List<Product> get comparedProducts => _comparedProducts;
  int? get bestHealthScoreId => _bestHealthScoreId;
  int? get bestNutriScoreId => _bestNutriScoreId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedCount => _selectedProducts.length;
  bool get canCompare => _selectedProducts.length >= 2;

  bool isSelected(int productId) => _selectedProducts.any((p) => p.id == productId);

  bool toggleProduct(ProductSearch product) {
    final idx = _selectedProducts.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _selectedProducts.removeAt(idx);
      notifyListeners();
      return false;
    }
    if (_selectedProducts.length >= 4) return true; // already at max
    _selectedProducts.add(product);
    notifyListeners();
    return true;
  }

  void removeProduct(int productId) {
    _selectedProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedProducts.clear();
    _comparedProducts.clear();
    _bestHealthScoreId = null;
    _bestNutriScoreId = null;
    notifyListeners();
  }

  Future<bool> compare() async {
    if (!canCompare) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _api.compareProducts(_selectedProducts.map((p) => p.id).toList());
      if (result != null) {
        final products = (result['products'] as List?)
                ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        _comparedProducts = products;
        _bestHealthScoreId = result['bestHealthScoreProductId'] as int?;
        _bestNutriScoreId = result['bestNutriScoreProductId'] as int?;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = 'Erreur lors de la comparaison';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
