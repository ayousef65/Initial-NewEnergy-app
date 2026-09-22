import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_energy_service/config/app_config.dart';
import 'package:new_energy_service/models/service_models.dart';
import 'package:new_energy_service/services/new_energy_api.dart';

import 'test_fakes.dart';

const _config = AppConfig(
  wordpressBaseUrl: 'https://example.com',
  facebookReviewUrl: 'https://example.com/facebook',
  googleMapsReviewUrl: 'https://example.com/maps',
  servicePhone: '01000000000',
);

void main() {
  test('login sends credentials only to the public auth route', () async {
    final api = WordpressApi(
      _config,
      client: MockClient((request) async {
        expect(request.url.path, '/wp-json/newenergy/v1/auth/login');
        expect(request.headers['authorization'], isNull);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['identifier'], 'sara@example.com');
        expect(body['password'], 'a-secure-password');
        return http.Response(
          jsonEncode({
            'token': 'opaque-session-token-that-is-long-enough',
            'expiresAt': '2035-01-01T00:00:00Z',
            'user': {
              'id': 7,
              'displayName': 'سارة أحمد',
              'email': 'sara@example.com',
              'phone': '01011111111',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await api.login(
      identifier: 'sara@example.com',
      password: 'a-secure-password',
    );

    expect(session.user.id, 7);
    expect(session.token, startsWith('opaque-session'));
  });

  test('sync uses the revocable bearer session', () async {
    final api = WordpressApi(
      _config,
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer opaque-session-token');
        expect(request.url.queryParameters['reason'], 'automatic');
        return http.Response(
          jsonEncode({'items': <dynamic>[], 'cursor': '2030-01-01T00:00:00Z'}),
          200,
        );
      }),
    )..setSessionToken('opaque-session-token');

    final snapshot = await api.syncRequests();

    expect(snapshot.requests, isEmpty);
    expect(snapshot.cursor, '2030-01-01T00:00:00Z');
  });

  test('expired server sessions surface as unauthorized', () async {
    final api = WordpressApi(
      _config,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'nem_invalid_session', 'message': 'expired'}),
          401,
        ),
      ),
    )..setSessionToken('expired-token');

    await expectLater(
      api.syncRequests(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.isUnauthorized, 'unauthorized', isTrue)
            .having(
              (error) => error.message,
              'localized message',
              contains('انتهت جلسة الحساب'),
            ),
      ),
    );
  });

  test('shop checkout sends only product IDs and delivery details', () async {
    final api = WordpressApi(
      _config,
      client: MockClient((request) async {
        expect(request.url.path, '/wp-json/newenergy/v1/shop/orders');
        expect(request.headers['authorization'], 'Bearer opaque-session-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final items = body['items'] as List<dynamic>;
        expect(items.single, {'product_id': 88, 'quantity': 2});
        expect(body.containsKey('total'), isFalse);
        expect(body['address'], 'شارع النصر 10');
        return http.Response(
          jsonEncode({
            'id': 501,
            'number': '501',
            'status': 'on-hold',
            'total': 2500,
            'currency': 'EGP',
            'createdAt': '2030-01-01T00:00:00Z',
            'itemCount': 2,
          }),
          201,
        );
      }),
    )..setSessionToken('opaque-session-token');

    final order = await api.createShopOrder(
      items: const [CartItem(product: testProduct, quantity: 2)],
      checkout: const ShopCheckoutDraft(
        customerName: 'سارة أحمد',
        phone: '01011111111',
        address: 'شارع النصر 10',
        city: 'القاهرة',
        notes: '',
      ),
      clientMutationId: 'shop_test_mutation_123',
    );

    expect(order.number, '501');
    expect(order.itemCount, 2);
  });
}
