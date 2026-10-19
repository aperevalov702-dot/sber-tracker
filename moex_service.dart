import 'dart:convert';
import 'package:http/http.dart' as http;

class MoexService {
  static const String _baseUrl = 'https://iss.moex.com/iss';

  /// Текущая цена и рыночные данные SBER
  Future<Map<String, dynamic>?> getCurrentPrice() async {
    try {
      final url = Uri.parse(
        '$_baseUrl/engines/stock/markets/shares/boards/TQBR/securities/SBER.json'
        '?iss.meta=off&iss.only=securities,marketdata',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final marketdata = data['marketdata'];
      final securities = data['securities'];

      if (marketdata == null || marketdata['data'] == null || marketdata['data'].isEmpty) {
        return null;
      }

      final columns = List<String>.from(marketdata['columns']);
      final values = List.from(marketdata['data'][0]);
      final map = Map<String, dynamic>.fromIterables(columns, values);

      // Дополнительно берём название
      if (securities != null && securities['data'] != null && securities['data'].isNotEmpty) {
        final secColumns = List<String>.from(securities['columns']);
        final secValues = List.from(securities['data'][0]);
        final secMap = Map<String, dynamic>.fromIterables(secColumns, secValues);
        map['SHORTNAME'] = secMap['SHORTNAME'] ?? 'Сбербанк';
        map['SECNAME'] = secMap['SECNAME'] ?? 'Сбербанк России';
      }

      return map;
    } catch (e) {
      print('Ошибка получения цены: $e');
      return null;
    }
  }

  /// Исторические свечи (дневные)
  Future<List<Map<String, dynamic>>> getCandles({int days = 60}) async {
    try {
      final now = DateTime.now();
      final from = now.subtract(Duration(days: days));
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';

      final url = Uri.parse(
        '$_baseUrl/engines/stock/markets/shares/boards/TQBR/securities/SBER/candles.json'
        '?from=$fromStr&interval=24&iss.meta=off',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final candles = data['candles'];
      if (candles == null || candles['data'] == null) return [];

      final columns = List<String>.from(candles['columns']);
      final result = <Map<String, dynamic>>[];

      for (var row in candles['data']) {
        final map = Map<String, dynamic>.fromIterables(columns, row);
        result.add(map);
      }
      return result;
    } catch (e) {
      print('Ошибка получения свечей: $e');
      return [];
    }
  }
}
