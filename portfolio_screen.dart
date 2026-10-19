import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/portfolio_service.dart';
import '../providers/stock_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pos = await context.read<PortfolioService>().getPosition();
    _qtyController.text = pos['quantity']! > 0 ? pos['quantity']!.toStringAsFixed(0) : '';
    _priceController.text = pos['avgPrice']! > 0 ? pos['avgPrice']!.toStringAsFixed(2) : '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;

    if (qty < 0 || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректные значения')),
      );
      return;
    }

    await context.read<PortfolioService>().savePosition(
          quantity: qty,
          avgPrice: price,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Портфель сохранён')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _clear() async {
    await context.read<PortfolioService>().clear();
    _qtyController.clear();
    _priceController.clear();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Портфель очищен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrice =
        (context.watch<StockProvider>().currentPrice?['LAST'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Мой портфель')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Количество акций SBER',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Например: 100',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Средняя цена покупки (₽)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Например: 280.50',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _save,
                                child: const Text('Сохранить'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _clear,
                              child: const Text('Очистить'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (currentPrice > 0)
                  FutureBuilder<Map<String, double>>(
                    future: context.read<PortfolioService>().getPosition(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final qty = snapshot.data!['quantity'] ?? 0;
                      final avg = snapshot.data!['avgPrice'] ?? 0;
                      if (qty <= 0) return const SizedBox.shrink();

                      final pnl = context.read<PortfolioService>().calculatePnL(
                            quantity: qty,
                            avgPrice: avg,
                            currentPrice: currentPrice,
                          );

                      final isProfit = (pnl['pnl'] as double) >= 0;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Текущий результат', style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              _row('Количество', '${qty.toStringAsFixed(0)} шт.'),
                              _row('Средняя цена', '${avg.toStringAsFixed(2)} ₽'),
                              _row('Текущая цена', '${currentPrice.toStringAsFixed(2)} ₽'),
                              const Divider(),
                              _row('Стоимость покупки', '${(pnl['cost'] as double).toStringAsFixed(0)} ₽'),
                              _row('Текущая стоимость', '${(pnl['value'] as double).toStringAsFixed(0)} ₽'),
                              _row(
                                'Прибыль / Убыток',
                                '${isProfit ? '+' : ''}${(pnl['pnl'] as double).toStringAsFixed(0)} ₽ '
                                '(${(pnl['pnlPercent'] as double).toStringAsFixed(1)}%)',
                                color: isProfit ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Пока официальной интеграции с «СберИнвестиции» нет. '
                  'Вводите данные вручную или импортируйте из брокерского отчёта.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
