import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/tracking_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _api;
  List<ProductSearch> _products = [];
  List<ProductSearch> _favorites = [];
  List<ScanHistoryItem> _history = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;

  ProductProvider(this._api);

  List<ProductSearch> get products => _products;
  List<ProductSearch> get favorites => _favorites;
  List<ScanHistoryItem> get history => _history;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts({String? search, String? category, String? nutriScore}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _api.getProducts(search: search, category: category, nutriScore: nutriScore);
    } catch (e) {
      _error = 'Impossible de charger les produits';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProductById(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedProduct = await _api.getProductById(id);
    } catch (e) {
      _error = 'Impossible de charger le produit';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> scanBarcode(String barcode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // scanProduct essaie d'abord auth, puis anonyme (avec Open Food Facts)
      _selectedProduct = await _api.scanProduct(barcode);
    } catch (e) {
      _error = 'Produit non trouvé';
    }

    _isLoading = false;
    notifyListeners();
    return _selectedProduct;
  }

  /// Recherche hybride : base locale + Open Food Facts
  Future<void> searchOpenFoodFacts(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _api.searchOpenFoodFacts(query);
    } catch (e) {
      _error = 'Erreur de recherche';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _api.getHistory();
    } catch (e) {
      _error = 'Impossible de charger l\'historique';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _api.getFavorites();
    } catch (e) {
      _error = 'Impossible de charger les favoris';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> toggleFavorite(int productId) async {
    final isFav = _favorites.any((f) => f.id == productId);
    if (isFav) {
      final success = await _api.removeFavorite(productId);
      if (success) {
        _favorites.removeWhere((f) => f.id == productId);
        try { TrackingService.instance.trackEvent('favorite_remove', data: {'productId': productId}); } catch (_) {}
        notifyListeners();
      }
      return !success;
    } else {
      final success = await _api.addFavorite(productId);
      if (success) {
        try { TrackingService.instance.trackEvent('favorite_add', data: {'productId': productId}); } catch (_) {}
        await loadFavorites();
      }
      return success;
    }
  }

  List<ProductSearch> _alternatives = [];
  List<ProductSearch> get alternatives => _alternatives;

  /// Charge les meilleures alternatives dans la même catégorie
  Future<void> loadAlternatives(String? categories, int? currentHealthScore, int currentProductId) async {
    _alternatives = [];
    if (categories == null || categories.isEmpty) return;

    try {
      // Cherche dans la même catégorie
      final firstCategory = categories.split(',').first.trim();
      final results = await _api.getProducts(category: firstCategory);
      // Filtre : meilleur score, pas le même produit
      _alternatives = results
          .where((p) => p.id != currentProductId && (p.healthScore ?? 0) > (currentHealthScore ?? 0))
          .toList()
        ..sort((a, b) => (b.healthScore ?? 0).compareTo(a.healthScore ?? 0));
      if (_alternatives.length > 5) {
        _alternatives = _alternatives.sublist(0, 5);
      }
    } catch (_) {}
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    _alternatives = [];
    notifyListeners();
  }
}
