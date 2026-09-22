import 'package:flutter_test/flutter_test.dart';
import 'package:new_energy_service/models/service_models.dart';
import 'package:new_energy_service/utils/formatters.dart';

void main() {
  group('formatters', () {
    test('localizes service and repair statuses', () {
      expect(localizeStatus('inspection'), 'الفحص الفني');
      expect(localizeRepairStatus('fixed'), 'تم الإصلاح');
      expect(maintenanceStageIndex('quality_check'), 4);
    });

    test('formats prices using WooCommerce minor units', () {
      expect(
        formatProductPrice(
          rawPrice: '125050',
          currencySymbol: 'ج.م',
          minorUnit: 2,
        ),
        contains('ج.م'),
      );
      expect(formatMoney(3190), contains('جنيه'));
    });

    test('maps WooCommerce product options without exposing HTML', () {
      final product = StoreProduct.fromJson({
        'id': 88,
        'name': 'شاحن منزلي',
        'description': '<p>شحن آمن <strong>وسريع</strong></p>',
        'has_options': true,
        'is_purchasable': true,
        'is_in_stock': true,
        'prices': {
          'price': '125000',
          'regular_price': '125000',
          'sale_price': '125000',
          'currency_symbol': 'ج.م',
          'currency_minor_unit': 2,
        },
      });

      expect(product.description, 'شحن آمن وسريع');
      expect(product.type, 'variable');
      expect(product.canAddToCart, isFalse);
    });
  });

  test('maps the WordPress response contract', () {
    final request = ServiceRequest.fromJson({
      'id': 42,
      'requestNumber': 'NE-42',
      'serviceId': 'maintenance',
      'serviceTitle': 'حجز الصيانة',
      'status': 'inspection',
      'customerName': 'أحمد',
      'phone': '01000000000',
      'vehicle': 'BYD',
      'location': 'القاهرة',
      'priority': 'قريب',
      'createdAt': '2026-09-21T10:30:00Z',
      'invoiceItems': [
        {'label': 'فحص', 'amount': 450},
      ],
      'invoiceTotal': 450,
    });

    expect(request.wordpressId, 42);
    expect(request.id, 'NE-42');
    expect(request.invoiceItems.single.amount, 450);
    expect(request.synced, isTrue);
  });
}
