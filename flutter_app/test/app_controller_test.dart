import 'package:flutter_test/flutter_test.dart';
import 'package:new_energy_service/controllers/app_controller.dart';
import 'package:new_energy_service/data/sample_data.dart';
import 'package:new_energy_service/models/service_models.dart';
import 'package:new_energy_service/services/auth_store.dart';
import 'package:new_energy_service/services/request_store.dart';
import 'package:new_energy_service/services/shop_store.dart';

import 'test_fakes.dart';

void main() {
  test(
    'stores a service request with account identity and sync metadata',
    () async {
      final store = MemoryRequestStore();
      final controller = AppController(
        config: localConfig,
        api: FakeNewEnergyApi(),
        store: store,
        authStore: MemoryAuthStore(testSession),
        shopStore: MemoryShopStore(),
      );
      await controller.initializeLocalData();

      final result = await controller.submitRequest(
        services.first,
        const RequestDraft(
          customerName: 'سارة',
          phone: '01011111111',
          vehicle: 'BYD Atto 3',
          location: 'مدينة نصر',
          preferredDate: 'غداً',
          notes: 'فحص دوري',
          priority: 'قريب',
        ),
      );

      expect(result.success, isTrue);
      expect(controller.activeTab, AppTab.requests);
      expect(controller.activeRequest.customerName, 'سارة أحمد');
      expect(controller.activeRequest.synced, isTrue);
      expect((await store.loadRequests('user_7')).first.phone, '01011111111');
    },
  );

  test('records local payment and unlocks reviews', () async {
    final paidRequest = starterRequests.first.copyWith(
      wordpressId: 42,
      synced: true,
      invoiceItems: invoiceItems,
      invoiceTotal: invoiceItems.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      ),
    );
    final api = FakeNewEnergyApi()..remoteRequests = [paidRequest];
    final controller = AppController(
      config: localConfig,
      api: api,
      store: MemoryRequestStore([paidRequest]),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();

    final result = await controller.completePayment();

    expect(result.success, isTrue);
    expect(controller.isPaymentPaid, isTrue);
    expect(controller.activeTab, AppTab.reviews);
  });

  test('waits for a server-issued invoice before submitting payment', () async {
    final request = starterRequests.first.copyWith(
      wordpressId: 42,
      synced: true,
    );
    final api = FakeNewEnergyApi()..remoteRequests = [request];
    final controller = AppController(
      config: localConfig,
      api: api,
      store: MemoryRequestStore([request]),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();

    final result = await controller.completePayment();

    expect(result.success, isFalse);
    expect(result.message, contains('إصدار الفاتورة'));
    expect(controller.isPaymentPaid, isFalse);
  });

  test('logs out and clears account data from the device', () async {
    final api = FakeNewEnergyApi();
    final authStore = MemoryAuthStore(testSession);
    final store = MemoryRequestStore(starterRequests);
    final controller = AppController(
      config: localConfig,
      api: api,
      store: store,
      authStore: authStore,
      shopStore: MemoryShopStore(),
    );
    await controller.initializeLocalData();

    final result = await controller.logout();

    expect(result.success, isTrue);
    expect(api.loggedOut, isTrue);
    expect(controller.authStatus, AuthStatus.signedOut);
    expect(controller.requests, isEmpty);
    expect(await authStore.loadSession(), isNull);
  });

  test('persists the account cart and places a WooCommerce order', () async {
    final api = FakeNewEnergyApi()..products = [testProduct];
    final shopStore = MemoryShopStore();
    final controller = AppController(
      config: localConfig,
      api: api,
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(testSession),
      shopStore: shopStore,
    );
    addTearDown(controller.dispose);
    await controller.initializeLocalData();

    final added = await controller.addProductToCart(testProduct, quantity: 2);
    expect(added.success, isTrue);
    expect(controller.cartCount, 2);
    expect((await shopStore.loadCart('user_7')).single.quantity, 2);

    final result = await controller.placeShopOrder(
      const ShopCheckoutDraft(
        customerName: 'سارة أحمد',
        phone: '01011111111',
        address: 'شارع النصر 10',
        city: 'القاهرة',
        notes: 'الاتصال قبل التوصيل',
      ),
    );

    expect(result.success, isTrue);
    expect(api.lastShopMutationId, startsWith('shop_'));
    expect(controller.cartItems, isEmpty);
    expect(controller.shopOrders.single.number, '501');
  });

  test('signs in and restores the account session', () async {
    final authStore = MemoryAuthStore();
    final controller = AppController(
      config: localConfig,
      api: FakeNewEnergyApi(),
      store: MemoryRequestStore(),
      authStore: authStore,
      shopStore: MemoryShopStore(),
    );
    addTearDown(controller.dispose);
    await controller.initializeLocalData();

    expect(controller.authStatus, AuthStatus.signedOut);
    final result = await controller.login('sara@example.com', 'long-password');

    expect(result.success, isTrue);
    expect(controller.authStatus, AuthStatus.signedIn);
    expect(controller.account?.id, 7);
    expect((await authStore.loadSession())?.token, testSession.token);
  });

  test('retries an offline request without creating a duplicate', () async {
    final api = FakeNewEnergyApi()..fail = true;
    final controller = AppController(
      config: localConfig,
      api: api,
      store: MemoryRequestStore(),
      authStore: MemoryAuthStore(testSession),
      shopStore: MemoryShopStore(),
    );
    addTearDown(controller.dispose);
    await controller.initializeLocalData();

    final saved = await controller.submitRequest(
      services.first,
      const RequestDraft(
        customerName: 'سارة',
        phone: '01011111111',
        vehicle: 'BYD Atto 3',
        location: 'مدينة نصر',
        preferredDate: 'غداً',
        notes: 'فحص دوري',
        priority: 'قريب',
      ),
    );
    expect(saved.success, isTrue);
    expect(controller.requests.single.synced, isFalse);
    final mutationId = controller.requests.single.clientMutationId;

    api.fail = false;
    expect((await controller.syncRequests()).success, isTrue);
    expect(controller.requests, hasLength(1));
    expect(controller.requests.single.synced, isTrue);
    expect(controller.requests.single.clientMutationId, mutationId);

    expect((await controller.syncRequests()).success, isTrue);
    expect(controller.requests, hasLength(1));
    expect(api.remoteRequests, hasLength(1));
  });
}
