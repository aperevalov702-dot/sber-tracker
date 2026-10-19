import 'package:shared_preferences/shared_preferences.dart';

class PortfolioService {
  static const _keyQty = 'portfolio_qty';
  static const _keyAvgPrice = 'portfolio_avg_price';

  Future<void> savePosition({required double quantity, required double avgPrice}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyQty, quantity);
    await prefs.setDouble(_keyAvgPrice, avgPrice);
  }

  Future<Map<String, double>> getPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'quantity': prefs.getDouble(_keyQty) ?? 0.0,
      'avgPrice': prefs.getDouble(_keyAvgPrice) ?? 0.0,
    };
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyQty);
    await prefs.remove(_keyAvgPrice);
  }

  /// Расчёт P&L
  Map<String, dynamic> calculatePnL({
    required double quantity,
    required double avgPrice,
    required double currentPrice,
  }) {
    if (quantity <= 0 || avgPrice <= 0) {
      return {
        'value': 0.0,
        'cost': 0.0,
        'pnl': 0.0,
        'pnlPercent': 0.0,
      };
    }

    final cost = quantity * avgPrice;
    final value = quantity * currentPrice;
    final pnl = value - cost;
    final pnlPercent = (pnl / cost) * 100;

    return {
      'value': value,
      'cost': cost,
      'pnl': pnl,
      'pnlPercent': pnlPercent,
    };
  }
}
