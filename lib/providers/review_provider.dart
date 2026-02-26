import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ApiService _api;

  ProductReviewSummary? _summary;
  List<Review> _myReviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewProvider(this._api);

  ProductReviewSummary? get summary => _summary;
  List<Review> get myReviews => _myReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadReviews(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _api.getProductReviews(productId);
    } catch (e) {
      _error = 'Impossible de charger les avis';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitReview(int productId, int rating, String? comment) async {
    _isLoading = true;
    notifyListeners();

    try {
      final review = await _api.createReview(productId, rating, comment);
      if (review != null) {
        await loadReviews(productId);
        return true;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteReview(int reviewId, int productId) async {
    final success = await _api.deleteReview(reviewId);
    if (success) {
      await loadReviews(productId);
    }
    return success;
  }

  Future<void> loadMyReviews() async {
    _isLoading = true;
    notifyListeners();

    try {
      _myReviews = await _api.getMyReviews();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
