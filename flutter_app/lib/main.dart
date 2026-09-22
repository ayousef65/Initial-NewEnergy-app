import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'controllers/app_controller.dart';
import 'services/auth_store.dart';
import 'services/new_energy_api.dart';
import 'services/request_store.dart';
import 'services/shop_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_EG');

  final config = AppConfig.fromEnvironment();
  final controller = AppController(
    config: config,
    api: WordpressApi(config),
    store: SecureRequestStore(),
    authStore: SecureAuthStore(),
    shopStore: SecureShopStore(),
  );

  await controller.initializeLocalData();
  runApp(NewEnergyApp(controller: controller));
  unawaited(controller.refreshRemoteData());
}
