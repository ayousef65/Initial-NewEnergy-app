import 'dart:convert';

import '../models/service_models.dart';
import 'secure_storage.dart';

abstract interface class RequestStore {
  Future<List<ServiceRequest>> loadRequests(String accountKey);

  Future<void> saveRequests(String accountKey, List<ServiceRequest> requests);

  Future<void> clearRequests(String accountKey);
}

class SecureRequestStore implements RequestStore {
  String _requestsKey(String accountKey) =>
      'new_energy_service_requests_v2_$accountKey';

  @override
  Future<List<ServiceRequest>> loadRequests(String accountKey) async {
    final raw = await appSecureStorage.read(key: _requestsKey(accountKey));
    if (raw == null || raw.isEmpty) return <ServiceRequest>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ServiceRequest>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ServiceRequest.fromJson)
          .toList();
    } on FormatException {
      return <ServiceRequest>[];
    }
  }

  @override
  Future<void> saveRequests(String accountKey, List<ServiceRequest> requests) {
    return appSecureStorage.write(
      key: _requestsKey(accountKey),
      value: jsonEncode(requests.map((request) => request.toJson()).toList()),
    );
  }

  @override
  Future<void> clearRequests(String accountKey) {
    return appSecureStorage.delete(key: _requestsKey(accountKey));
  }
}

class MemoryRequestStore implements RequestStore {
  MemoryRequestStore([List<ServiceRequest> initial = const []])
    : _requests = List<ServiceRequest>.of(initial);

  List<ServiceRequest> _requests;

  @override
  Future<List<ServiceRequest>> loadRequests(String accountKey) async {
    return List<ServiceRequest>.of(_requests);
  }

  @override
  Future<void> saveRequests(
    String accountKey,
    List<ServiceRequest> requests,
  ) async {
    _requests = List<ServiceRequest>.of(requests);
  }

  @override
  Future<void> clearRequests(String accountKey) async {
    _requests = <ServiceRequest>[];
  }
}
