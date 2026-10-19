import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'services/moex_service.dart';
import 'services/notification_service.dart';
import 'services/portfolio_service.dart';
import 'services/recommendation_service.dart';
import 'providers/stock_provider.dart';
import 'screens/home_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Фоновая проверка цены
    final moex = MoexService();
    final priceData = await moex.getCurrentPrice();
    if (priceData != null) {
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.checkAndNotify(priceData);
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация уведомлений
  final notificationService = NotificationService();
  await notificationService.init();

  // Фоновые задачи (каждые 15 минут)
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    "sber-price-check",
    "checkSberPrice",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StockProvider()),
        Provider(create: (_) => PortfolioService()),
        Provider(create: (_) => RecommendationService()),
      ],
      child: const SberTrackerApp(),
    ),
  );
}

class SberTrackerApp extends StatelessWidget {
  const SberTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sber Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF21A038), // зелёный Сбера
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        cardColor: const Color(0xFF161B22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
