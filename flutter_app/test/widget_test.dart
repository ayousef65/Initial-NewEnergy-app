import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:new_energy_service/app.dart';
import 'package:new_energy_service/controllers/app_controller.dart';
import 'package:new_energy_service/services/auth_store.dart';
import 'package:new_energy_service/services/request_store.dart';
import 'package:new_energy_service/services/shop_store.dart';

import 'test_fakes.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar_EG');
  });

  testWidgets('renders the Arabic dashboard and opens the request form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController(
      config: localConfig,
      api: FakeNewEnergyApi(),
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();

    await tester.pumpWidget(NewEnergyApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('New Energy'), findsOneWidget);
    expect(find.text('لوحة الخدمة'), findsOneWidget);
    expect(find.text('حجز الصيانة'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('حجز الصيانة').first);
    await tester.pumpAndSettle();

    expect(find.text('رقم الهاتف'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('request-form-list')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(find.text('تأكيد الطلب'), findsOneWidget);
  });

  testWidgets('navigates to the requests tab', (tester) async {
    final controller = AppController(
      config: localConfig,
      api: FakeNewEnergyApi(),
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();
    await tester.pumpWidget(NewEnergyApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    expect(find.text('طلباتك'), findsOneWidget);
    expect(find.textContaining('WordPress'), findsNothing);
    expect(find.byIcon(Icons.cloud_sync_outlined), findsNothing);
  });

  testWidgets('opens the native shop without leaving the app', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeNewEnergyApi()..products = [testProduct];
    final controller = AppController(
      config: localConfig,
      api: api,
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();
    await controller.refreshRemoteData();
    await tester.pumpWidget(NewEnergyApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('شاحن سيارة كهربائية'), findsOneWidget);
    await tester.ensureVisible(find.text('عرض الكل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عرض الكل'));
    await tester.pumpAndSettle();

    expect(find.text('متجر New Energy'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows login and account registration at a narrow phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController(
      config: localConfig,
      api: FakeNewEnergyApi(),
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();
    await tester.pumpWidget(NewEnergyApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('New Energy'), findsOneWidget);
    expect(find.text('مرحباً بعودتك'), findsOneWidget);
    expect(find.byKey(const Key('login-identifier')), findsOneWidget);

    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حساب الخدمة'), findsOneWidget);
    expect(find.byKey(const Key('register-name')), findsOneWidget);
    expect(find.byKey(const Key('register-email')), findsOneWidget);
    expect(find.byKey(const Key('register-phone')), findsOneWidget);
  });
}
