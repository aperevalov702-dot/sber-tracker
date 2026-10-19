class RecommendationService {
  /// Простая рекомендация на основе RSI и SMA
  Map<String, dynamic> getRecommendation(List<Map<String, dynamic>> candles) {
    if (candles.length < 30) {
      return {
        'action': 'НЕДОСТАТОЧНО ДАННЫХ',
        'confidence': 0.0,
        'reason': 'Нужно минимум 30 торговых дней',
        'color': 0xFF9E9E9E,
      };
    }

    final closes = candles
        .map((c) => (c['close'] as num).toDouble())
        .toList();

    final rsi = _calculateRSI(closes, 14);
    final sma20 = _calculateSMA(closes, 20);
    final sma50 = closes.length >= 50 ? _calculateSMA(closes, 50) : sma20;
    final lastClose = closes.last;

    int score = 0;
    final reasons = <String>[];

    // RSI
    if (rsi < 30) {
      score += 2;
      reasons.add('RSI ${rsi.toStringAsFixed(1)} — сильная перепроданность');
    } else if (rsi < 40) {
      score += 1;
      reasons.add('RSI ${rsi.toStringAsFixed(1)} — лёгкая перепроданность');
    } else if (rsi > 70) {
      score -= 2;
      reasons.add('RSI ${rsi.toStringAsFixed(1)} — сильная перекупленность');
    } else if (rsi > 60) {
      score -= 1;
      reasons.add('RSI ${rsi.toStringAsFixed(1)} — лёгкая перекупленность');
    } else {
      reasons.add('RSI ${rsi.toStringAsFixed(1)} — нейтрально');
    }

    // Цена vs SMA
    if (lastClose > sma20 && sma20 > sma50) {
      score += 1;
      reasons.add('Цена выше SMA20 и SMA50 — восходящий тренд');
    } else if (lastClose < sma20 && sma20 < sma50) {
      score -= 1;
      reasons.add('Цена ниже SMA20 и SMA50 — нисходящий тренд');
    }

    // Отклонение от SMA20
    final deviation = ((lastClose - sma20) / sma20) * 100;
    if (deviation < -5) {
      score += 1;
      reasons.add('Цена на ${deviation.abs().toStringAsFixed(1)}% ниже SMA20');
    } else if (deviation > 5) {
      score -= 1;
      reasons.add('Цена на ${deviation.toStringAsFixed(1)}% выше SMA20');
    }

    String action;
    int color;
    double confidence = (score.abs() / 4).clamp(0.0, 1.0);

    if (score >= 2) {
      action = 'ПОКУПАТЬ';
      color = 0xFF4CAF50;
    } else if (score <= -2) {
      action = 'ПРОДАВАТЬ';
      color = 0xFFF44336;
    } else {
      action = 'ДЕРЖАТЬ';
      color = 0xFFFFC107;
    }

    return {
      'action': action,
      'confidence': confidence,
      'reason': reasons.join('\n'),
      'color': color,
      'rsi': rsi,
      'sma20': sma20,
      'lastClose': lastClose,
    };
  }

  double _calculateSMA(List<double> data, int period) {
    if (data.length < period) return data.last;
    final slice = data.sublist(data.length - period);
    return slice.reduce((a, b) => a + b) / period;
  }

  double _calculateRSI(List<double> closes, int period) {
    if (closes.length < period + 1) return 50.0;

    double gains = 0;
    double losses = 0;

    for (int i = closes.length - period; i < closes.length; i++) {
      final change = closes[i] - closes[i - 1];
      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    final avgGain = gains / period;
    final avgLoss = losses / period;

    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }
}
