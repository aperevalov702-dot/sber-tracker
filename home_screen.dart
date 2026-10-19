import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/stock_provider.dart';
import '../services/portfolio_service.dart';
import 'settings_screen.dart';
import 'portfolio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sber Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StockProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.currentPrice == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentPrice == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final price = provider.currentPrice;
          final change = (price?['LASTCHANGEPRCNT'] as num?)?.toDouble() ?? 0.0;
          final last = (price?['LAST'] as num?)?.toDouble() ?? 0.0;
          final isUp = change >= 0;

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Цена
                _PriceCard(
                  price: last,
                  change: change,
                  isUp: isUp,
                  lastUpdate: provider.lastUpdate,
                ),
                const SizedBox(height: 16),

                // Рекомендация
                if (provider.recommendation != null)
                  _RecommendationCard(rec: provider.recommendation!),

                const SizedBox(height: 16),

                // Портфель (кратко)
                _PortfolioSummary(currentPrice: last),

                const SizedBox(height: 16),

                // График
                if (provider.candles.isNotEmpty)
                  _ChartCard(candles: provider.candles),

                const SizedBox(height: 24),

                // Кнопка портфеля
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Мой портфель'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final double price;
  final double change;
  final bool isUp;
  final DateTime? lastUpdate;

  const _PriceCard({
    required this.price,
    required this.change,
    required this.isUp,
    this.lastUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUp ? Colors.greenAccent : Colors.redAccent;
    final formatter = NumberFormat('#,##0.00', 'ru');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF21A038),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Сбербанк',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Text('SBER • MOEX', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${formatter.format(price)} ₽',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (lastUpdate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Обновлено: ${DateFormat('HH:mm:ss').format(lastUpdate!)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;

  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final color = Color(rec['color'] as int);
    final confidence = ((rec['confidence'] as double) * 100).toInt();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Рекомендация',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    rec['action'] as String,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'уверенность $confidence%',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rec['reason'] as String,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Это не финансовый совет. Используйте на свой страх и риск.',
              style: TextStyle(fontSize: 11, color: Colors.orangeAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final double currentPrice;

  const _PortfolioSummary({required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, double>>(
      future: context.read<PortfolioService>().getPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final qty = snapshot.data!['quantity'] ?? 0;
        final avg = snapshot.data!['avgPrice'] ?? 0;

        if (qty <= 0) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Портфель пуст'),
              subtitle: const Text('Добавьте свои акции SBER'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                );
              },
            ),
          );
        }

        final pnl = context.read<PortfolioService>().calculatePnL(
              quantity: qty,
              avgPrice: avg,
              currentPrice: currentPrice,
            );

        final isProfit = (pnl['pnl'] as double) >= 0;
        final color = isProfit ? Colors.greenAccent : Colors.redAccent;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Мой портфель SBER', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '${qty.toStringAsFixed(0)} шт. × ${avg.toStringAsFixed(2)} ₽',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'P&L: ${isProfit ? '+' : ''}${(pnl['pnl'] as double).toStringAsFixed(0)} ₽ '
                  '(${(pnl['pnlPercent'] as double).toStringAsFixed(1)}%)',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  final List<Map<String, dynamic>> candles;

  const _ChartCard({required this.candles});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < candles.length; i++) {
      final close = (candles[i]['close'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), close));
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('График (90 дней)', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF21A038),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF21A038).withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
