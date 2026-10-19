import 'package:flutter/foundation.dart';
import '../services/moex_service.dart';
import '../services/notification_service.dart';
import '../services/recommendation_service.dart';

class StockProvider extends ChangeNotifier {
  final MoexService _moex = MoexService();
  final NotificationService _notifications = NotificationService();
  final RecommendationService _recommender = RecommendationService();

  Map<String, dynamic>? currentPrice;
  List<Map<String, dynamic>> candles = [];
  Map<String, dynamic>? recommendation;
  bool isLoading = false;
  String? error;
  DateTime? lastUpdate;

  Future<void> refresh() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final price = await _moex.getCurrentPrice();
      final hist = await _moex.getCandles(days: 90);

      if (price != null) {
        currentPrice = price;
        await _notifications.checkAndNotify(price);
      }

      if (hist.isNotEmpty) {
        candles = hist;
        recommendation = _recommender.getRecommendation(hist);
      }

      lastUpdate = DateTime.now();
    } catch (e) {
      error = 'Ошибка загрузки данных: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
