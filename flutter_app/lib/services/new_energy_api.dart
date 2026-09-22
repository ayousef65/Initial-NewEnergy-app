import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/service_models.dart';
import '../utils/formatters.dart';

abstract interface class NewEnergyApi {
  void setSessionToken(String? token);

  Future<void> checkConnection();

  Future<AuthSession> registerAccount({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  });

  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  Future<AuthSession> refreshSession(AuthSession current);

  Future<AuthSession> validateSession(AuthSession current);

  Future<void> logout();

  Future<void> requestPasswordReset(String identifier);

  Future<List<StoreProduct>> fetchProducts({int limit = 100});

  Future<List<StoreOrder>> listShopOrders();

  Future<StoreOrder> createShopOrder({
    required List<CartItem> items,
    required ShopCheckoutDraft checkout,
    required String clientMutationId,
  });

  Future<ServiceRequest> createServiceRequest(
    ServiceItem service,
    RequestDraft draft, {
    required String clientMutationId,
  });

  Future<List<ServiceRequest>> listServiceRequests();

  Future<SyncSnapshot> syncRequests({
    String since = '',
    String reason = 'automatic',
  });

  Future<ServiceRequest> recordPayment({
    required int requestId,
    required String paymentMethod,
    required double amount,
  });

  Future<void> submitReview({
    required int requestId,
    required int rating,
    String message = '',
  });
}

class WordpressApi implements NewEnergyApi {
  WordpressApi(this.config, {http.Client? client})
    : _client = client ?? http.Client();

  static const _namespace = 'newenergy/v1';
  static const _timeout = Duration(seconds: 15);

  final AppConfig config;
  final http.Client _client;
  String _sessionToken = '';

  @override
  void setSessionToken(String? token) {
    _sessionToken = token?.trim() ?? '';
  }

  @override
  Future<void> checkConnection() async {
    await _request('/health', requireAuth: false);
  }

  @override
  Future<AuthSession> registerAccount({
    required String displayName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final data = await _request(
      '/auth/register',
      method: 'POST',
      requireAuth: false,
      body: {
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'password': password,
        'device_label': 'New Energy Flutter app',
      },
    );
    return _sessionFromData(data);
  }

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    final data = await _request(
      '/auth/login',
      method: 'POST',
      requireAuth: false,
      body: {
        'identifier': identifier,
        'password': password,
        'device_label': 'New Energy Flutter app',
      },
    );
    return _sessionFromData(data);
  }

  @override
  Future<AuthSession> refreshSession(AuthSession current) async {
    final data = await _request('/auth/refresh', method: 'POST');
    return _sessionFromData(data);
  }

  @override
  Future<AuthSession> validateSession(AuthSession current) async {
    final data = await _request('/auth/me');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('تعذر قراءة بيانات الحساب.');
    }
    final rawUser = data['user'];
    final expiresAt = DateTime.tryParse(data['expiresAt']?.toString() ?? '');
    return current.copyWith(
      user: rawUser is Map<String, dynamic>
          ? AccountUser.fromJson(rawUser)
          : current.user,
      expiresAt: expiresAt?.toUtc(),
    );
  }

  @override
  Future<void> logout() async {
    await _request('/auth/logout', method: 'POST');
  }

  @override
  Future<void> requestPasswordReset(String identifier) async {
    await _request(
      '/auth/forgot-password',
      method: 'POST',
      requireAuth: false,
      body: {'identifier': identifier},
    );
  }

  @override
  Future<List<StoreProduct>> fetchProducts({int limit = 100}) async {
    if (!config.isWordpressConfigured) return <StoreProduct>[];
    final uri = Uri.parse(
      '${config.wordpressBaseUrl}/wp-json/wc/store/v1/products',
    ).replace(queryParameters: {'per_page': '$limit'});
    final response = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(_timeout);
    final decoded = _decodeResponse(response, context: 'تحميل منتجات المتجر');
    if (decoded is! List) return <StoreProduct>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(StoreProduct.fromJson)
        .toList();
  }

  @override
  Future<List<StoreOrder>> listShopOrders() async {
    final data = await _request('/shop/orders');
    if (data is! List) return <StoreOrder>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(StoreOrder.fromJson)
        .toList();
  }

  @override
  Future<StoreOrder> createShopOrder({
    required List<CartItem> items,
    required ShopCheckoutDraft checkout,
    required String clientMutationId,
  }) async {
    final data = await _request(
      '/shop/orders',
      method: 'POST',
      body: {
        'client_mutation_id': clientMutationId,
        'items': items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              },
            )
            .toList(),
        'customer_name': checkout.customerName,
        'phone': checkout.phone,
        'address': checkout.address,
        'city': checkout.city,
        'notes': checkout.notes,
      },
    );
    return StoreOrder.fromJson(_mapData(data));
  }

  @override
  Future<ServiceRequest> createServiceRequest(
    ServiceItem service,
    RequestDraft draft, {
    required String clientMutationId,
  }) async {
    final data = await _request(
      '/service-requests',
      method: 'POST',
      body: {
        'service_id': service.id,
        'service_title': service.title,
        'priority': draft.priority,
        'customer_name': draft.customerName,
        'phone': draft.phone,
        'vehicle': draft.vehicle,
        'location': draft.location,
        'preferred_date': draft.preferredDate,
        'notes': draft.notes,
        'client_mutation_id': clientMutationId,
      },
    );
    return _requestFromData(_mapData(data));
  }

  @override
  Future<List<ServiceRequest>> listServiceRequests() async {
    final data = await _request('/service-requests');
    if (data is! List) return <ServiceRequest>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(_requestFromData)
        .toList();
  }

  @override
  Future<SyncSnapshot> syncRequests({
    String since = '',
    String reason = 'automatic',
  }) async {
    final data = await _request(
      '/sync',
      queryParameters: {if (since.isNotEmpty) 'since': since, 'reason': reason},
    );
    final map = _mapData(data);
    final rawItems = map['items'];
    return SyncSnapshot(
      requests: rawItems is List
          ? rawItems
                .whereType<Map<String, dynamic>>()
                .map(_requestFromData)
                .toList()
          : <ServiceRequest>[],
      cursor: map['cursor']?.toString() ?? '',
    );
  }

  @override
  Future<ServiceRequest> recordPayment({
    required int requestId,
    required String paymentMethod,
    required double amount,
  }) async {
    final data = await _request(
      '/service-requests/$requestId/payment',
      method: 'POST',
      body: {
        'payment_method': paymentMethod,
        'amount': amount,
        'status': 'submitted',
      },
    );
    return _requestFromData(_mapData(data));
  }

  @override
  Future<void> submitReview({
    required int requestId,
    required int rating,
    String message = '',
  }) async {
    await _request(
      '/service-requests/$requestId/review',
      method: 'POST',
      body: {'rating': rating, 'message': message},
    );
  }

  Future<dynamic> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    if (!config.isWordpressConfigured) {
      throw const ApiException('تعذر الاتصال بالخدمة حالياً.');
    }
    if (requireAuth && _sessionToken.isEmpty) {
      throw const ApiException(
        'سجّل الدخول للمتابعة.',
        statusCode: 401,
        code: 'nem_invalid_session',
      );
    }

    var uri = Uri.parse('${config.wordpressBaseUrl}/wp-json/$_namespace$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters);
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (requireAuth) 'Authorization': 'Bearer $_sessionToken',
    };

    final http.Response response;
    if (method == 'POST') {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(_timeout);
    } else {
      response = await _client.get(uri, headers: headers).timeout(_timeout);
    }

    return _decodeResponse(response, context: 'الاتصال بالخدمة');
  }

  dynamic _decodeResponse(http.Response response, {required String context}) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } on FormatException {
      data = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = data is Map<String, dynamic>
          ? data['code']?.toString() ?? ''
          : '';
      final serverMessage = data is Map<String, dynamic>
          ? data['message']?.toString() ?? ''
          : '';
      throw ApiException(
        _localizedApiError(code, serverMessage, context, response.statusCode),
        statusCode: response.statusCode,
        code: code,
      );
    }
    return data;
  }

  AuthSession _sessionFromData(dynamic data) {
    final session = AuthSession.fromJson(_mapData(data));
    if (session.token.isEmpty || session.user.id <= 0) {
      throw const ApiException('تعذر إنشاء جلسة آمنة للحساب.');
    }
    return session;
  }

  Map<String, dynamic> _mapData(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('استجابة الخدمة غير مكتملة.');
  }

  ServiceRequest _requestFromData(Map<String, dynamic> data) {
    final request = ServiceRequest.fromJson(data);
    return request.copyWith(
      status: localizeStatus(request.status),
      createdAt: formatApiDate(request.createdAt),
      repairItems: request.repairItems
          .map(
            (item) => RepairItem(
              issue: item.issue,
              fix: item.fix,
              status: localizeRepairStatus(item.status),
            ),
          )
          .toList(),
      synced: true,
    );
  }

  String _localizedApiError(
    String code,
    String serverMessage,
    String context,
    int statusCode,
  ) {
    return switch (code) {
      'nem_invalid_credentials' => 'بيانات الدخول غير صحيحة.',
      'nem_invalid_session' => 'انتهت جلسة الحساب. سجّل الدخول مرة أخرى.',
      'nem_too_many_attempts' =>
        'تم إيقاف المحاولات مؤقتاً للحماية. حاول لاحقاً.',
      'nem_invalid_registration' =>
        'راجع الاسم والبريد والهاتف، واستخدم كلمة مرور من 10 أحرف على الأقل.',
      'nem_account_unavailable' => 'تعذر إنشاء الحساب بهذه البيانات. جرّب تسجيل الدخول أو استعادة كلمة المرور.',
      'nem_https_required' => 'يجب استخدام اتصال آمن لحماية الحساب.',
      'nem_registration_disabled' => 'إنشاء الحسابات متوقف مؤقتاً.',
      'nem_invoice_not_ready' =>
        'لم تصدر الفاتورة بعد. ستظهر خيارات السداد فور اعتمادها.',
      'nem_woocommerce_unavailable' => 'المتجر غير متاح مؤقتاً.',
      'nem_invalid_shop_order' =>
        'راجع بيانات التوصيل والمنتجات ثم حاول مرة أخرى.',
      'nem_product_unavailable' => 'أحد المنتجات لم يعد متاحاً للطلب.',
      'nem_product_out_of_stock' => 'الكمية المطلوبة غير متاحة حالياً.',
      'nem_shop_order_failed' => 'تعذر تسجيل طلب المتجر. حاول مرة أخرى.',
      _ when serverMessage.isNotEmpty => serverMessage,
      _ => '$context تعذر الآن ($statusCode).',
    };
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code = ''});

  final String message;
  final int? statusCode;
  final String code;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}
