import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergen_check.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/shopping_list.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';

  String? _accessToken;
  String? _refreshToken;

  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  Future<String?> get token async {
    if (_accessToken != null) return _accessToken;
    await _loadTokens();
    return _accessToken;
  }

  Future<Map<String, String>> get _headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_profile');
    // Note: on ne supprime PAS 'biometric_refresh_token' ici,
    // il est géré par le logout et la désactivation biométrique
  }

  /// Tente de se reconnecter via le token biométrique sauvegardé
  Future<bool> tryBiometricRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final bioToken = prefs.getString('biometric_refresh_token');
    if (bioToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': bioToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        // Mettre à jour aussi le token biométrique avec le nouveau
        await prefs.setString('biometric_refresh_token', data['refreshToken'] as String);
        if (data['user'] != null) {
          await prefs.setString('user_profile', jsonEncode(data['user']));
        }
        return true;
      }
    } catch (_) {}
    // Token invalide, le supprimer
    await prefs.remove('biometric_refresh_token');
    return false;
  }

  Future<bool> tryRefreshToken() async {
    if (_refreshToken == null) {
      await _loadTokens();
      if (_refreshToken == null) return false;
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(
          data['accessToken'] as String,
          data['refreshToken'] as String,
        );
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(data['user']));
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<http.Response> _authRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _headers;
    var response = await request(headers);
    if (response.statusCode == 401) {
      final refreshed = await tryRefreshToken();
      if (refreshed) {
        headers = await _headers;
        response = await request(headers);
      }
    }
    return response;
  }

  // ==================== AUTH ====================

  Future<(Map<String, dynamic>?, String?)> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final body = {
        'username': username,
        'email': email,
        'password': password,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(data['user']));
        }
        return (data, null);
      }
      final error = jsonDecode(response.body);
      return (null, error['message'] as String? ?? 'Erreur lors de l\'inscription');
    } catch (e) {
      return (null, 'Erreur de connexion au serveur');
    }
  }

  Future<(Map<String, dynamic>?, String?)> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
        if (data['user'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile', jsonEncode(data['user']));
        }
        return (data, null);
      }
      final error = jsonDecode(response.body);
      return (null, error['message'] as String? ?? 'Email ou mot de passe incorrect');
    } catch (e) {
      return (null, 'Erreur de connexion au serveur');
    }
  }

  Future<void> logout() async {
    try {
      if (_refreshToken == null) {
        await _loadTokens();
      }
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      if (_refreshToken != null) {
        final response = await _authRequest((headers) => http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: headers,
          body: jsonEncode({
            'refreshToken': _refreshToken,
            'keepBiometric': biometricEnabled,
          }),
        ));
        // Stocker le token biométrique retourné par le serveur
        if (biometricEnabled && response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final bioToken = data['biometricToken'] as String?;
          if (bioToken != null) {
            await prefs.setString('biometric_refresh_token', bioToken);
          }
        }
      }
    } catch (_) {}
    await clearTokens();
  }

  Future<void> logoutAll() async {
    try {
      await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/auth/logout-all'),
        headers: headers,
      ));
    } catch (_) {}
    await clearTokens();
  }

  // ==================== PROFILE ====================

  Future<UserProfile?> getProfile() async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(data));
        return UserProfile.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<(UserProfile?, String?)> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (firstName != null) body['firstName'] = firstName;
      if (lastName != null) body['lastName'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final response = await _authRequest((headers) => http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
        body: jsonEncode(body),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(data));
        return (UserProfile.fromJson(data), null);
      }
      final error = jsonDecode(response.body);
      return (null, error['message'] as String?);
    } catch (e) {
      return (null, 'Erreur de connexion');
    }
  }

  Future<(UserProfile?, String?)> updatePreferences({
    String? dietType,
    String? allergies,
    String? dietaryGoals,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? language,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (dietType != null) body['dietType'] = dietType;
      if (allergies != null) body['allergies'] = allergies;
      if (dietaryGoals != null) body['dietaryGoals'] = dietaryGoals;
      if (notificationsEnabled != null) body['notificationsEnabled'] = notificationsEnabled;
      if (darkModeEnabled != null) body['darkModeEnabled'] = darkModeEnabled;
      if (language != null) body['language'] = language;

      final response = await _authRequest((headers) => http.put(
        Uri.parse('$baseUrl/auth/preferences'),
        headers: headers,
        body: jsonEncode(body),
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', jsonEncode(data));
        return (UserProfile.fromJson(data), null);
      }
      final error = jsonDecode(response.body);
      return (null, error['message'] as String?);
    } catch (e) {
      return (null, 'Erreur de connexion');
    }
  }

  Future<UserStats?> getStats() async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/auth/stats'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return UserStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  // ==================== PASSWORD ====================

  Future<(bool, String?)> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: headers,
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      ));
      if (response.statusCode == 200) return (true, null);
      final error = jsonDecode(response.body);
      return (false, error['message'] as String?);
    } catch (e) {
      return (false, 'Erreur de connexion');
    }
  }

  Future<(bool, String?)> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) return (true, null);
      return (false, 'Erreur');
    } catch (e) {
      return (false, 'Erreur de connexion');
    }
  }

  Future<(bool, String?)> resetPassword(String token, String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'email': email, 'newPassword': newPassword}),
      );
      if (response.statusCode == 200) return (true, null);
      final error = jsonDecode(response.body);
      return (false, error['message'] as String?);
    } catch (e) {
      return (false, 'Erreur de connexion');
    }
  }

  // ==================== DELETE ACCOUNT ====================

  Future<(bool, String?)> deleteAccount(String password) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/auth/delete-account'),
        headers: headers,
        body: jsonEncode({'password': password}),
      ));
      if (response.statusCode == 200) {
        await clearTokens();
        return (true, null);
      }
      final error = jsonDecode(response.body);
      return (false, error['message'] as String?);
    } catch (e) {
      return (false, 'Erreur de connexion');
    }
  }

  // ==================== PRODUCTS ====================

  Future<List<ProductSearch>> getProducts({String? search, String? category, String? nutriScore}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null) params['category'] = category;
    if (nutriScore != null) params['nutriScore'] = nutriScore;

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await http.get(uri, headers: await _headers);
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ProductSearch.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/barcode/$barcode'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<Product?> getProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<Product?> scanProduct(String barcode) async {
    final t = await token;
    if (t != null) {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/products/scan/$barcode'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    }
    final response = await http.post(
      Uri.parse('$baseUrl/products/scan-anonymous/$barcode'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<ProductSearch>> searchOpenFoodFacts(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/search-off?query=${Uri.encodeComponent(query)}'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ProductSearch.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<ScanHistoryItem>> getHistory() async {
    final response = await _authRequest((headers) => http.get(
      Uri.parse('$baseUrl/products/history'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ScanHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> addFavorite(int productId) async {
    final response = await _authRequest((headers) => http.post(
      Uri.parse('$baseUrl/products/favorites/$productId'),
      headers: headers,
    ));
    return response.statusCode == 200;
  }

  Future<bool> removeFavorite(int productId) async {
    final response = await _authRequest((headers) => http.delete(
      Uri.parse('$baseUrl/products/favorites/$productId'),
      headers: headers,
    ));
    return response.statusCode == 200;
  }

  Future<List<ProductSearch>> getFavorites() async {
    final response = await _authRequest((headers) => http.get(
      Uri.parse('$baseUrl/products/favorites'),
      headers: headers,
    ));
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => ProductSearch.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ==================== REVIEWS ====================

  Future<ProductReviewSummary?> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/product/$productId'),
        headers: await _headers,
      );
      if (response.statusCode == 200) {
        return ProductReviewSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<Review?> createReview(int productId, int rating, String? comment) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/reviews/product/$productId'),
        headers: headers,
        body: jsonEncode({'rating': rating, 'comment': comment}),
      ));
      if (response.statusCode == 200) {
        return Review.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteReview(int reviewId) async {
    final response = await _authRequest((headers) => http.delete(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: headers,
    ));
    return response.statusCode == 200;
  }

  Future<List<Review>> getMyReviews() async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/reviews/my'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  // ==================== SHOPPING LISTS ====================

  Future<List<ShoppingListModel>> getShoppingLists() async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/shoppinglists'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.map((e) => ShoppingListModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<ShoppingListModel?> createShoppingList(String name) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/shoppinglists'),
        headers: headers,
        body: jsonEncode({'name': name}),
      ));
      if (response.statusCode == 200) {
        return ShoppingListModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<ShoppingListDetail?> getShoppingListDetail(int listId) async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/shoppinglists/$listId'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return ShoppingListDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteShoppingList(int listId) async {
    final response = await _authRequest((headers) => http.delete(
      Uri.parse('$baseUrl/shoppinglists/$listId'),
      headers: headers,
    ));
    return response.statusCode == 200;
  }

  Future<ShoppingListItemModel?> addShoppingListItem(int listId, {int? productId, required String name, int quantity = 1}) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/shoppinglists/$listId/items'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'quantity': quantity,
          if (productId != null) 'productId': productId,
        }),
      ));
      if (response.statusCode == 200) {
        return ShoppingListItemModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<ShoppingListItemModel?> updateShoppingListItem(int listId, int itemId, {String? name, int? quantity, bool? isChecked}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (quantity != null) body['quantity'] = quantity;
      if (isChecked != null) body['isChecked'] = isChecked;

      final response = await _authRequest((headers) => http.put(
        Uri.parse('$baseUrl/shoppinglists/$listId/items/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      ));
      if (response.statusCode == 200) {
        return ShoppingListItemModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> removeShoppingListItem(int listId, int itemId) async {
    final response = await _authRequest((headers) => http.delete(
      Uri.parse('$baseUrl/shoppinglists/$listId/items/$itemId'),
      headers: headers,
    ));
    return response.statusCode == 200;
  }

  // ==================== COMPARE ====================

  Future<Map<String, dynamic>?> compareProducts(List<int> productIds) async {
    try {
      final response = await _authRequest((headers) => http.post(
        Uri.parse('$baseUrl/products/compare'),
        headers: headers,
        body: jsonEncode({'productIds': productIds}),
      ));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ==================== ALLERGENS ====================

  Future<AllergenCheckResult?> checkAllergens(int productId) async {
    try {
      final response = await _authRequest((headers) => http.get(
        Uri.parse('$baseUrl/products/allergen-check/$productId'),
        headers: headers,
      ));
      if (response.statusCode == 200) {
        return AllergenCheckResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}
