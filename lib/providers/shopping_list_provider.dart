import 'package:flutter/material.dart';
import '../models/shopping_list.dart';
import '../services/api_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final ApiService _api;

  List<ShoppingListModel> _lists = [];
  ShoppingListDetail? _currentDetail;
  bool _isLoading = false;
  String? _error;

  ShoppingListProvider(this._api);

  List<ShoppingListModel> get lists => _lists;
  ShoppingListDetail? get currentDetail => _currentDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadLists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lists = await _api.getShoppingLists();
    } catch (e) {
      _error = 'Impossible de charger les listes';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createList(String name) async {
    final list = await _api.createShoppingList(name);
    if (list != null) {
      _lists.insert(0, list);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteList(int listId) async {
    final success = await _api.deleteShoppingList(listId);
    if (success) {
      _lists.removeWhere((l) => l.id == listId);
      notifyListeners();
    }
    return success;
  }

  Future<void> loadDetail(int listId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentDetail = await _api.getShoppingListDetail(listId);
    } catch (e) {
      _error = 'Impossible de charger la liste';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addItem(int listId, {int? productId, required String name, int quantity = 1}) async {
    final item = await _api.addShoppingListItem(listId, productId: productId, name: name, quantity: quantity);
    if (item != null) {
      await loadDetail(listId);
      return true;
    }
    return false;
  }

  Future<bool> toggleItemChecked(int listId, int itemId, bool isChecked) async {
    final item = await _api.updateShoppingListItem(listId, itemId, isChecked: isChecked);
    if (item != null) {
      if (_currentDetail != null) {
        final idx = _currentDetail!.items.indexWhere((i) => i.id == itemId);
        if (idx >= 0) {
          _currentDetail = ShoppingListDetail(
            id: _currentDetail!.id,
            name: _currentDetail!.name,
            isArchived: _currentDetail!.isArchived,
            items: List.from(_currentDetail!.items)..[idx] = item,
            createdAt: _currentDetail!.createdAt,
            updatedAt: _currentDetail!.updatedAt,
          );
          notifyListeners();
        }
      }
      return true;
    }
    return false;
  }

  Future<bool> removeItem(int listId, int itemId) async {
    final success = await _api.removeShoppingListItem(listId, itemId);
    if (success) {
      await loadDetail(listId);
    }
    return success;
  }
}
