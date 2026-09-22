import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;

enum ApiStatus { checking, connected, local, error }

enum AuthStatus { checking, signedOut, signedIn }

enum AppTab { home, requests, tracking, invoice, payment, reviews }

class AccountUser {
  const AccountUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.phone,
  });

  factory AccountUser.fromJson(Map<String, dynamic> json) {
    return AccountUser(
      id: _asNullableInt(json['id']) ?? 0,
      displayName: _readString(json, 'displayName', 'display_name'),
      email: _readString(json, 'email'),
      phone: _readString(json, 'phone'),
    );
  }

  final int id;
  final String displayName;
  final String email;
  final String phone;

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'phone': phone,
  };
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    return AuthSession(
      token: _readString(json, 'token'),
      expiresAt:
          DateTime.tryParse(_readString(json, 'expiresAt'))?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      user: AccountUser.fromJson(
        rawUser is Map<String, dynamic> ? rawUser : const <String, dynamic>{},
      ),
    );
  }

  final String token;
  final DateTime expiresAt;
  final AccountUser user;

  bool get isExpired => expiresAt.isBefore(
    DateTime.now().toUtc().add(const Duration(minutes: 1)),
  );

  AuthSession copyWith({
    String? token,
    DateTime? expiresAt,
    AccountUser? user,
  }) {
    return AuthSession(
      token: token ?? this.token,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'user': user.toJson(),
  };
}

class SyncSnapshot {
  const SyncSnapshot({required this.requests, required this.cursor});

  final List<ServiceRequest> requests;
  final String cursor;
}

class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tint,
    required this.priorityOptions,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Color tint;
  final List<String> priorityOptions;
}

class RequestDraft {
  const RequestDraft({
    required this.customerName,
    required this.phone,
    required this.vehicle,
    required this.location,
    required this.preferredDate,
    required this.notes,
    required this.priority,
  });

  final String customerName;
  final String phone;
  final String vehicle;
  final String location;
  final String preferredDate;
  final String notes;
  final String priority;
}

class InvoiceItem {
  const InvoiceItem({required this.label, required this.amount});

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      label: json['label']?.toString() ?? '',
      amount: _asDouble(json['amount']),
    );
  }

  final String label;
  final double amount;

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};
}

class RepairItem {
  const RepairItem({
    required this.issue,
    required this.fix,
    required this.status,
  });

  factory RepairItem.fromJson(Map<String, dynamic> json) {
    return RepairItem(
      issue: json['issue']?.toString() ?? '',
      fix: json['fix']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  final String issue;
  final String fix;
  final String status;

  Map<String, dynamic> toJson() => {
    'issue': issue,
    'fix': fix,
    'status': status,
  };
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.priority,
    required this.customerName,
    required this.phone,
    required this.vehicle,
    required this.location,
    required this.notes,
    this.wordpressId,
    this.synced = false,
    this.paymentStatus = 'pending',
    this.reportText = '',
    this.repairItems = const [],
    this.invoiceItems = const [],
    this.invoiceTotal = 0,
    this.clientMutationId = '',
    this.updatedAt = '',
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final notes = _readString(json, 'notes');
    final preferredDate = _readString(json, 'preferredDate', 'preferred_date');
    final wordpressId = _asNullableInt(json['wordpressId'] ?? json['id']);
    final requestNumber = _readString(json, 'requestNumber', 'request_number');
    final serviceId = _readString(json, 'serviceId', 'service_id');

    return ServiceRequest(
      id: requestNumber.isNotEmpty
          ? requestNumber
          : _readString(json, 'localId', 'local_id').isNotEmpty
          ? _readString(json, 'localId', 'local_id')
          : wordpressId == null
          ? 'NE-LOCAL'
          : 'NE-$wordpressId',
      wordpressId: wordpressId,
      serviceId: serviceId,
      title: _readString(json, 'serviceTitle', 'service_title').isNotEmpty
          ? _readString(json, 'serviceTitle', 'service_title')
          : 'طلب خدمة',
      status: _readString(json, 'status').isNotEmpty
          ? _readString(json, 'status')
          : 'تم التسجيل',
      createdAt: _readString(json, 'createdAt', 'created_at'),
      priority: _readString(json, 'priority').isNotEmpty
          ? _readString(json, 'priority')
          : 'عادي',
      customerName:
          _readString(json, 'customerName', 'customer_name').isNotEmpty
          ? _readString(json, 'customerName', 'customer_name')
          : 'عميل New Energy',
      phone: _readString(json, 'phone'),
      vehicle: _readString(json, 'vehicle').isNotEmpty
          ? _readString(json, 'vehicle')
          : 'غير محدد',
      location: _readString(json, 'location').isNotEmpty
          ? _readString(json, 'location')
          : 'غير محدد',
      notes: notes.isNotEmpty ? notes : preferredDate,
      synced: json['synced'] == true || wordpressId != null,
      paymentStatus: _readString(json, 'paymentStatus', 'payment_status'),
      reportText: _readString(json, 'reportText', 'report_text'),
      repairItems: _mapList(
        json['repairItems'] ?? json['repair_items'],
        RepairItem.fromJson,
      ),
      invoiceItems: _mapList(
        json['invoiceItems'] ?? json['invoice_items'],
        InvoiceItem.fromJson,
      ),
      invoiceTotal: _asDouble(json['invoiceTotal'] ?? json['invoice_total']),
      clientMutationId: _readString(
        json,
        'clientMutationId',
        'client_mutation_id',
      ),
      updatedAt: _readString(json, 'updatedAt', 'updated_at'),
    );
  }

  final String id;
  final int? wordpressId;
  final String serviceId;
  final String title;
  final String status;
  final String createdAt;
  final String priority;
  final String customerName;
  final String phone;
  final String vehicle;
  final String location;
  final String notes;
  final bool synced;
  final String paymentStatus;
  final String reportText;
  final List<RepairItem> repairItems;
  final List<InvoiceItem> invoiceItems;
  final double invoiceTotal;
  final String clientMutationId;
  final String updatedAt;

  ServiceRequest copyWith({
    String? id,
    int? wordpressId,
    String? serviceId,
    String? title,
    String? status,
    String? createdAt,
    String? priority,
    String? customerName,
    String? phone,
    String? vehicle,
    String? location,
    String? notes,
    bool? synced,
    String? paymentStatus,
    String? reportText,
    List<RepairItem>? repairItems,
    List<InvoiceItem>? invoiceItems,
    double? invoiceTotal,
    String? clientMutationId,
    String? updatedAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      wordpressId: wordpressId ?? this.wordpressId,
      serviceId: serviceId ?? this.serviceId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      reportText: reportText ?? this.reportText,
      repairItems: repairItems ?? this.repairItems,
      invoiceItems: invoiceItems ?? this.invoiceItems,
      invoiceTotal: invoiceTotal ?? this.invoiceTotal,
      clientMutationId: clientMutationId ?? this.clientMutationId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'localId': id,
    'wordpressId': wordpressId,
    'serviceId': serviceId,
    'serviceTitle': title,
    'status': status,
    'createdAt': createdAt,
    'priority': priority,
    'customerName': customerName,
    'phone': phone,
    'vehicle': vehicle,
    'location': location,
    'notes': notes,
    'synced': synced,
    'paymentStatus': paymentStatus,
    'reportText': reportText,
    'repairItems': repairItems.map((item) => item.toJson()).toList(),
    'invoiceItems': invoiceItems.map((item) => item.toJson()).toList(),
    'invoiceTotal': invoiceTotal,
    'clientMutationId': clientMutationId,
    'updatedAt': updatedAt,
  };
}

class MaintenanceStage {
  const MaintenanceStage({required this.title, required this.body});

  final String title;
  final String body;
}

class PaymentMethodItem {
  const PaymentMethodItem({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.permalink,
    required this.sku,
    required this.description,
    required this.shortDescription,
    required this.type,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    required this.currencySymbol,
    required this.currencyMinorUnit,
    required this.imageUrls,
    required this.categories,
    required this.isPurchasable,
    required this.isInStock,
    required this.onSale,
    required this.averageRating,
    required this.ratingCount,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final prices = json['prices'] is Map<String, dynamic>
        ? json['prices'] as Map<String, dynamic>
        : <String, dynamic>{};
    final images = json['images'] is List
        ? json['images'] as List<dynamic>
        : <dynamic>[];
    final imageUrls = images
        .whereType<Map<String, dynamic>>()
        .map((image) => image['src']?.toString() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
    final rawCategories = json['categories'] is List
        ? json['categories'] as List<dynamic>
        : <dynamic>[];

    return StoreProduct(
      id: _asNullableInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      permalink: json['permalink']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: _plainText(json['description']),
      shortDescription: _plainText(
        json['short_description'] ?? json['summary'],
      ),
      type: (json['type']?.toString() ?? '').isNotEmpty
          ? json['type'].toString()
          : json['has_options'] == true
          ? 'variable'
          : 'simple',
      price: prices['price']?.toString() ?? '',
      regularPrice: prices['regular_price']?.toString() ?? '',
      salePrice: prices['sale_price']?.toString() ?? '',
      currencySymbol: prices['currency_symbol']?.toString() ?? '',
      currencyMinorUnit: _asNullableInt(prices['currency_minor_unit']) ?? 2,
      imageUrls: imageUrls,
      categories: rawCategories
          .whereType<Map<String, dynamic>>()
          .map((category) => category['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(),
      isPurchasable: json['is_purchasable'] == true,
      isInStock: json['is_in_stock'] == true,
      onSale: json['on_sale'] == true,
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0,
      ratingCount: _asNullableInt(json['review_count']) ?? 0,
    );
  }

  factory StoreProduct.fromStoredJson(Map<String, dynamic> json) {
    return StoreProduct(
      id: _asNullableInt(json['id']) ?? 0,
      name: _readString(json, 'name'),
      permalink: _readString(json, 'permalink'),
      sku: _readString(json, 'sku'),
      description: _readString(json, 'description'),
      shortDescription: _readString(json, 'shortDescription'),
      type: _readString(json, 'type').isEmpty
          ? 'simple'
          : _readString(json, 'type'),
      price: _readString(json, 'price'),
      regularPrice: _readString(json, 'regularPrice'),
      salePrice: _readString(json, 'salePrice'),
      currencySymbol: _readString(json, 'currencySymbol'),
      currencyMinorUnit: _asNullableInt(json['currencyMinorUnit']) ?? 2,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      isPurchasable: json['isPurchasable'] == true,
      isInStock: json['isInStock'] == true,
      onSale: json['onSale'] == true,
      averageRating: _asDouble(json['averageRating']),
      ratingCount: _asNullableInt(json['ratingCount']) ?? 0,
    );
  }

  final int id;
  final String name;
  final String permalink;
  final String sku;
  final String description;
  final String shortDescription;
  final String type;
  final String price;
  final String regularPrice;
  final String salePrice;
  final String currencySymbol;
  final int currencyMinorUnit;
  final List<String> imageUrls;
  final List<String> categories;
  final bool isPurchasable;
  final bool isInStock;
  final bool onSale;
  final double averageRating;
  final int ratingCount;

  String? get imageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  bool get canAddToCart =>
      id > 0 &&
      type == 'simple' &&
      isPurchasable &&
      isInStock &&
      price.isNotEmpty;

  double get priceAmount {
    final raw = double.tryParse(price) ?? 0;
    var divisor = 1;
    for (var index = 0; index < currencyMinorUnit; index += 1) {
      divisor *= 10;
    }
    return raw / divisor;
  }

  Map<String, dynamic> toStoredJson() => {
    'id': id,
    'name': name,
    'permalink': permalink,
    'sku': sku,
    'description': description,
    'shortDescription': shortDescription,
    'type': type,
    'price': price,
    'regularPrice': regularPrice,
    'salePrice': salePrice,
    'currencySymbol': currencySymbol,
    'currencyMinorUnit': currencyMinorUnit,
    'imageUrls': imageUrls,
    'categories': categories,
    'isPurchasable': isPurchasable,
    'isInStock': isInStock,
    'onSale': onSale,
    'averageRating': averageRating,
    'ratingCount': ratingCount,
  };
}

class CartItem {
  const CartItem({required this.product, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawProduct = json['product'];
    return CartItem(
      product: StoreProduct.fromStoredJson(
        rawProduct is Map<String, dynamic>
            ? rawProduct
            : const <String, dynamic>{},
      ),
      quantity: (_asNullableInt(json['quantity']) ?? 1).clamp(1, 20),
    );
  }

  final StoreProduct product;
  final int quantity;

  double get total => product.priceAmount * quantity;

  CartItem copyWith({StoreProduct? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toStoredJson(),
    'quantity': quantity,
  };
}

class ShopCheckoutDraft {
  const ShopCheckoutDraft({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.city,
    required this.notes,
  });

  final String customerName;
  final String phone;
  final String address;
  final String city;
  final String notes;
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.currency,
    required this.createdAt,
    required this.itemCount,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    return StoreOrder(
      id: _asNullableInt(json['id']) ?? 0,
      number: _readString(json, 'number'),
      status: _readString(json, 'status'),
      total: _asDouble(json['total']),
      currency: _readString(json, 'currency'),
      createdAt: _readString(json, 'createdAt', 'created_at'),
      itemCount: _asNullableInt(json['itemCount'] ?? json['item_count']) ?? 0,
    );
  }

  final int id;
  final String number;
  final String status;
  final double total;
  final String currency;
  final String createdAt;
  final int itemCount;
}

class ActionResult {
  const ActionResult({required this.success, required this.message});

  final bool success;
  final String message;
}

String _readString(Map<String, dynamic> json, String first, [String? second]) {
  final value = json[first] ?? (second == null ? null : json[second]);
  return value?.toString().trim() ?? '';
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return <T>[];
  return value.whereType<Map<String, dynamic>>().map(mapper).toList();
}

String _plainText(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return '';
  return html_parser.parseFragment(raw).text?.trim() ?? '';
}
