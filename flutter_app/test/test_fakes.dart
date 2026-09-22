import 'package:new_energy_service/config/app_config.dart';
import 'package:new_energy_service/models/service_models.dart';
import 'package:new_energy_service/services/new_energy_api.dart';

const localConfig = AppConfig(
  wordpressBaseUrl: 'https://example.com',
  facebookReviewUrl: 'https://example.com/facebook',
  googleMapsReviewUrl: 'https://example.com/maps',
  servicePhone: '01000000000',
);

final testSession = AuthSession(
  token: 'test-session-token-that-is-long-enough',
  expiresAt: DateTime.utc(2035, 1, 1),
  user: const AccountUser(
    id: 7,
    displayName: 'سارة أحمد',
    email: 'sara@example.com',
    phone: '01011111111',
  ),
);

const testProduct = StoreProduct(
  id: 88,
  name: 'شاحن سيارة كهربائية',
  permalink: 'https://example.com/product/charger',
  sku: 'EV-88',
  description: 'شاحن منزلي موثوق.',
  shortDescription: 'شاحن منزلي.',
  type: 'simple',
  price: '125000',
  regularPrice: '125000',
  salePrice: '',
  currencySymbol: 'ج.م',
  currencyMinorUnit: 2,
  imageUrls: <String>[],
  categories: <String>['الشواحن'],
  isPurchasable: true,
  isInStock: true,
  onSale: false,
  averageRating: 4.8,
  ratingCount: 9,
);

class FakeNewEnergyApi implements NewEnergyApi {
  bool fail = false;
  bool unauthorized = false;
  bool loggedOut = false;
  String sessionToken = '';
  List<ServiceRequest> remoteRequests = <ServiceRequest>[];
  List<StoreProduct> products = <StoreProduct>[];
  List<StoreOrder> shopOrders = <StoreOrder>[];
  String lastShopMutationId = '';

  @override
  void setSessionToken(String? token) {
    sessionToken = token ?? '';
  }

  void _check() {
    if (unauthorized) {
      throw const ApiException(
        'expired',
        statusCode: 401,
        code: 'nem_invalid_session',
      );
    }
    if (fail) throw const ApiException('offline');
  }

  @override
  Future<void> checkConnection() async => _check();

  @override
  Future<AuthSession> registerAccount({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _check();
    return AuthSession(
      token: testSession.token,
      expiresAt: testSession.expiresAt,
      user: AccountUser(
        id: 7,
        displayName: displayName,
        email: email,
        phone: phone,
      ),
    );
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    _check();
    return testSession;
  }

  @override
  Future<AuthSession> refreshSession(AuthSession current) async {
    _check();
    return current;
  }

  @override
  Future<AuthSession> validateSession(AuthSession current) async {
    _check();
    return current;
  }

  @override
  Future<void> logout() async {
    _check();
    loggedOut = true;
  }

  @override
  Future<void> requestPasswordReset(String identifier) async {
    _check();
  }

  @override
  Future<ServiceRequest> createServiceRequest(
    ServiceItem service,
    RequestDraft draft, {
    required String clientMutationId,
  }) async {
    _check();
    final existing = remoteRequests.where(
      (item) => item.clientMutationId == clientMutationId,
    );
    if (existing.isNotEmpty) return existing.first;

    final request = ServiceRequest(
      id: 'NE-9001',
      wordpressId: 9001,
      serviceId: service.id,
      title: service.title,
      status: 'تم التسجيل',
      createdAt: 'الآن',
      priority: draft.priority,
      customerName: draft.customerName,
      phone: draft.phone,
      vehicle: draft.vehicle,
      location: draft.location,
      notes: draft.notes,
      synced: true,
      clientMutationId: clientMutationId,
    );
    remoteRequests = [request, ...remoteRequests];
    return request;
  }

  @override
  Future<List<StoreProduct>> fetchProducts({int limit = 100}) async {
    _check();
    return products.take(limit).toList();
  }

  @override
  Future<List<StoreOrder>> listShopOrders() async {
    _check();
    return shopOrders;
  }

  @override
  Future<StoreOrder> createShopOrder({
    required List<CartItem> items,
    required ShopCheckoutDraft checkout,
    required String clientMutationId,
  }) async {
    _check();
    lastShopMutationId = clientMutationId;
    final order = StoreOrder(
      id: 501,
      number: '501',
      status: 'on-hold',
      total: items.fold(0, (sum, item) => sum + item.total),
      currency: 'EGP',
      createdAt: DateTime.utc(2030).toIso8601String(),
      itemCount: items.fold(0, (sum, item) => sum + item.quantity),
    );
    shopOrders = [order, ...shopOrders];
    return order;
  }

  @override
  Future<List<ServiceRequest>> listServiceRequests() async {
    _check();
    return remoteRequests;
  }

  @override
  Future<SyncSnapshot> syncRequests({
    String since = '',
    String reason = 'automatic',
  }) async {
    _check();
    return SyncSnapshot(
      requests: remoteRequests,
      cursor: DateTime.utc(2030).toIso8601String(),
    );
  }

  @override
  Future<ServiceRequest> recordPayment({
    required int requestId,
    required String paymentMethod,
    required double amount,
  }) async {
    _check();
    final request = remoteRequests.firstWhere(
      (item) => item.wordpressId == requestId,
    );
    return request.copyWith(paymentStatus: 'paid', status: 'تم السداد');
  }

  @override
  Future<void> submitReview({
    required int requestId,
    required int rating,
    String message = '',
  }) async {
    _check();
  }
}
