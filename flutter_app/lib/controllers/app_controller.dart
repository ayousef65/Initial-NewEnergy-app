import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/sample_data.dart';
import '../models/service_models.dart';
import '../services/auth_store.dart';
import '../services/new_energy_api.dart';
import '../services/request_store.dart';
import '../services/shop_store.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.config,
    required this.api,
    required this.store,
    required this.authStore,
    required this.shopStore,
  }) : _apiStatus = config.isWordpressConfigured
           ? ApiStatus.checking
           : ApiStatus.local,
       _apiMessage = config.isWordpressConfigured
           ? 'جارٍ التأكد من اتصال التطبيق بالموقع.'
           : 'تعذر ربط التطبيق بالموقع حالياً.';

  static const _emptyRequest = ServiceRequest(
    id: '-',
    serviceId: '',
    title: 'لا يوجد طلب نشط',
    status: 'ابدأ بطلب خدمة',
    createdAt: '',
    priority: '',
    customerName: '',
    phone: '',
    vehicle: '',
    location: '',
    notes: '',
  );

  final AppConfig config;
  final NewEnergyApi api;
  final RequestStore store;
  final AuthStore authStore;
  final ShopStore shopStore;

  AppTab _activeTab = AppTab.home;
  List<ServiceRequest> _requests = <ServiceRequest>[];
  List<StoreProduct> _products = <StoreProduct>[];
  List<CartItem> _cartItems = <CartItem>[];
  List<StoreOrder> _shopOrders = <StoreOrder>[];
  ApiStatus _apiStatus;
  String _apiMessage;
  AuthStatus _authStatus = AuthStatus.checking;
  AuthSession? _session;
  bool _isAuthBusy = false;
  bool _isSubmitting = false;
  bool _isSyncing = false;
  bool _isPaying = false;
  bool _isReviewing = false;
  bool _isShopLoading = false;
  bool _isPlacingShopOrder = false;
  String _selectedPayment = 'card';
  int _rating = 5;
  String _syncCursor = '';
  String _pendingShopMutationId = '';
  Timer? _syncTimer;
  bool _disposed = false;

  AppTab get activeTab => _activeTab;
  List<ServiceRequest> get requests => List.unmodifiable(_requests);
  List<StoreProduct> get products => List.unmodifiable(_products);
  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  List<StoreOrder> get shopOrders => List.unmodifiable(_shopOrders);
  ApiStatus get apiStatus => _apiStatus;
  String get apiMessage => _apiMessage;
  AuthStatus get authStatus => _authStatus;
  AccountUser? get account => _session?.user;
  bool get isAuthBusy => _isAuthBusy;
  bool get isSubmitting => _isSubmitting;
  bool get isSyncing => _isSyncing;
  bool get isPaying => _isPaying;
  bool get isReviewing => _isReviewing;
  bool get isShopLoading => _isShopLoading;
  bool get isPlacingShopOrder => _isPlacingShopOrder;
  bool get hasRequests => _requests.isNotEmpty;
  int get cartCount =>
      _cartItems.fold(0, (total, item) => total + item.quantity);
  double get cartTotal =>
      _cartItems.fold(0, (total, item) => total + item.total);
  String get cartCurrency =>
      _cartItems.isEmpty ? '' : _cartItems.first.product.currencySymbol;
  String get selectedPayment => _selectedPayment;
  int get rating => _rating;

  ServiceRequest get activeRequest =>
      _requests.isNotEmpty ? _requests.first : _emptyRequest;

  List<RepairItem> get activeRepairItems => activeRequest.repairItems;

  List<InvoiceItem> get activeInvoiceItems => activeRequest.invoiceItems;

  double get activeInvoiceTotal {
    if (activeRequest.invoiceTotal > 0) return activeRequest.invoiceTotal;
    return activeInvoiceItems.fold(0, (sum, item) => sum + item.amount);
  }

  bool get isPaymentPaid =>
      activeRequest.paymentStatus == 'paid' ||
      activeRequest.status == 'تم السداد';

  bool get isPaymentSubmitted =>
      activeRequest.paymentStatus == 'submitted' ||
      activeRequest.paymentStatus == 'قيد المراجعة';

  Future<void> initializeLocalData() async {
    try {
      final savedSession = await authStore.loadSession();
      if (savedSession == null || savedSession.isExpired) {
        await authStore.clearSession();
        api.setSessionToken(null);
        _authStatus = AuthStatus.signedOut;
        _requests = <ServiceRequest>[];
        return;
      }

      _session = savedSession;
      api.setSessionToken(savedSession.token);
      _requests = await store.loadRequests(_accountKey(savedSession.user.id));
      _cartItems = await shopStore.loadCart(_accountKey(savedSession.user.id));
      _authStatus = AuthStatus.signedIn;
      _startAutomaticSync();
    } catch (_) {
      api.setSessionToken(null);
      _session = null;
      _requests = <ServiceRequest>[];
      _cartItems = <CartItem>[];
      _shopOrders = <StoreOrder>[];
      _authStatus = AuthStatus.signedOut;
    } finally {
      _notify();
    }
  }

  Future<void> refreshRemoteData() async {
    try {
      _products = await api.fetchProducts();
      _reconcileCartProducts();
      _notify();
    } catch (_) {
      _products = <StoreProduct>[];
    }

    if (!config.isWordpressConfigured) {
      _apiStatus = ApiStatus.local;
      _notify();
      return;
    }

    _apiStatus = ApiStatus.checking;
    _notify();
    try {
      await api.checkConnection();
      if (_session != null) {
        var validated = await api.validateSession(_session!);
        if (validated.expiresAt.difference(DateTime.now().toUtc()).inDays < 7) {
          validated = await api.refreshSession(validated);
          api.setSessionToken(validated.token);
        }
        _session = validated;
        await authStore.saveSession(validated);
        await syncRequests(manual: false);
        try {
          _shopOrders = await api.listShopOrders();
        } catch (_) {
          // Shopping history is supplementary to the core account connection.
        }
      }
      _apiStatus = ApiStatus.connected;
      _apiMessage = _session == null
          ? 'الموقع والتطبيق متصلان وجاهزان لتسجيل الدخول.'
          : 'يمكنك استخدام حسابك وخدماتك من التطبيق أو الموقع.';
    } on ApiException catch (error) {
      if (error.isUnauthorized && _session != null) {
        await _clearAccount(clearCachedData: true);
      }
      _apiStatus = ApiStatus.error;
      _apiMessage = error.message;
    } catch (error) {
      _apiStatus = ApiStatus.error;
      _apiMessage = _friendlyError(error);
    }
    _notify();
  }

  Future<ActionResult> login(String identifier, String password) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      return const ActionResult(
        success: false,
        message: 'أدخل البريد أو الهاتف وكلمة المرور.',
      );
    }

    _isAuthBusy = true;
    _notify();
    try {
      final session = await api.login(
        identifier: identifier.trim(),
        password: password,
      );
      await _activateSession(session);
      unawaited(syncRequests(manual: false));
      return const ActionResult(
        success: true,
        message: 'تم تسجيل الدخول وتحميل سجل الحساب.',
      );
    } catch (error) {
      return ActionResult(success: false, message: _friendlyError(error));
    } finally {
      _isAuthBusy = false;
      _notify();
    }
  }

  Future<ActionResult> register({
    required String displayName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (displayName.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty) {
      return const ActionResult(
        success: false,
        message: 'أكمل الاسم والبريد ورقم الهاتف.',
      );
    }
    if (password.length < 10) {
      return const ActionResult(
        success: false,
        message: 'استخدم كلمة مرور من 10 أحرف على الأقل.',
      );
    }
    if (password != passwordConfirmation) {
      return const ActionResult(
        success: false,
        message: 'كلمتا المرور غير متطابقتين.',
      );
    }

    _isAuthBusy = true;
    _notify();
    try {
      final session = await api.registerAccount(
        displayName: displayName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );
      await _activateSession(session);
      unawaited(syncRequests(manual: false));
      return const ActionResult(
        success: true,
        message: 'تم إنشاء الحساب وتأمين سجل الخدمة.',
      );
    } catch (error) {
      return ActionResult(success: false, message: _friendlyError(error));
    } finally {
      _isAuthBusy = false;
      _notify();
    }
  }

  Future<ActionResult> requestPasswordReset(String identifier) async {
    if (identifier.trim().isEmpty) {
      return const ActionResult(
        success: false,
        message: 'أدخل البريد الإلكتروني أو رقم الهاتف أولاً.',
      );
    }

    _isAuthBusy = true;
    _notify();
    try {
      await api.requestPasswordReset(identifier.trim());
      return const ActionResult(
        success: true,
        message: 'إذا كان الحساب موجوداً فستصلك رسالة استعادة كلمة المرور.',
      );
    } catch (error) {
      return ActionResult(success: false, message: _friendlyError(error));
    } finally {
      _isAuthBusy = false;
      _notify();
    }
  }

  Future<ActionResult> logout() async {
    _isAuthBusy = true;
    _notify();
    try {
      await api.logout();
    } catch (_) {
      // Local sign-out still protects this device when the network is unavailable.
    }
    await _clearAccount(clearCachedData: true);
    _isAuthBusy = false;
    _notify();
    return const ActionResult(
      success: true,
      message: 'تم تسجيل الخروج ومسح البيانات المحفوظة من هذا الجهاز.',
    );
  }

  void selectTab(AppTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _notify();
  }

  void selectPayment(String paymentMethod) {
    if (_selectedPayment == paymentMethod) return;
    _selectedPayment = paymentMethod;
    _notify();
  }

  void setRating(int value) {
    final next = value.clamp(1, 5).toInt();
    if (_rating == next) return;
    _rating = next;
    _notify();
  }

  Future<ActionResult> refreshShop() async {
    if (_isShopLoading) {
      return const ActionResult(
        success: true,
        message: 'جارٍ تحديث المتجر بالفعل.',
      );
    }

    _isShopLoading = true;
    _notify();
    try {
      _products = await api.fetchProducts();
      _reconcileCartProducts();
      if (_session != null) {
        _shopOrders = await api.listShopOrders();
      }
      return const ActionResult(success: true, message: 'تم تحديث المتجر.');
    } catch (error) {
      return ActionResult(success: false, message: _friendlyError(error));
    } finally {
      _isShopLoading = false;
      _notify();
    }
  }

  Future<ActionResult> addProductToCart(
    StoreProduct product, {
    int quantity = 1,
  }) async {
    if (!product.canAddToCart) {
      final message = product.type == 'variable'
          ? 'هذا المنتج يحتاج إلى اختيار مواصفات قبل إضافته.'
          : 'هذا المنتج غير متاح للطلب حالياً.';
      return ActionResult(success: false, message: message);
    }

    final cleanQuantity = quantity.clamp(1, 20).toInt();
    final index = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (index >= 0) {
      final item = _cartItems[index];
      _cartItems[index] = item.copyWith(
        product: product,
        quantity: (item.quantity + cleanQuantity).clamp(1, 20).toInt(),
      );
    } else {
      _cartItems = [
        ..._cartItems,
        CartItem(product: product, quantity: cleanQuantity),
      ];
    }
    _pendingShopMutationId = '';
    await _persistCart();
    _notify();
    return const ActionResult(
      success: true,
      message: 'تمت إضافة المنتج إلى السلة.',
    );
  }

  Future<void> updateCartQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await removeCartItem(productId);
      return;
    }
    _cartItems = _cartItems
        .map(
          (item) => item.product.id == productId
              ? item.copyWith(quantity: quantity.clamp(1, 20).toInt())
              : item,
        )
        .toList();
    _pendingShopMutationId = '';
    await _persistCart();
    _notify();
  }

  Future<void> removeCartItem(int productId) async {
    _cartItems = _cartItems
        .where((item) => item.product.id != productId)
        .toList();
    _pendingShopMutationId = '';
    await _persistCart();
    _notify();
  }

  Future<void> clearCart() async {
    _cartItems = <CartItem>[];
    _pendingShopMutationId = '';
    await _persistCart();
    _notify();
  }

  Future<ActionResult> placeShopOrder(ShopCheckoutDraft draft) async {
    if (_session == null) {
      return const ActionResult(
        success: false,
        message: 'سجّل الدخول لإكمال طلب المتجر.',
      );
    }
    if (_cartItems.isEmpty) {
      return const ActionResult(success: false, message: 'السلة فارغة.');
    }
    if (draft.customerName.trim().isEmpty ||
        draft.phone.trim().isEmpty ||
        draft.address.trim().isEmpty ||
        draft.city.trim().isEmpty) {
      return const ActionResult(
        success: false,
        message: 'أكمل الاسم والهاتف والعنوان والمدينة.',
      );
    }
    if (_isPlacingShopOrder) {
      return const ActionResult(
        success: false,
        message: 'جارٍ تسجيل طلبك بالفعل.',
      );
    }

    _isPlacingShopOrder = true;
    _pendingShopMutationId = _pendingShopMutationId.isEmpty
        ? _newMutationId('shop')
        : _pendingShopMutationId;
    _notify();
    try {
      final order = await api.createShopOrder(
        items: List<CartItem>.of(_cartItems),
        checkout: ShopCheckoutDraft(
          customerName: draft.customerName.trim(),
          phone: draft.phone.trim(),
          address: draft.address.trim(),
          city: draft.city.trim(),
          notes: draft.notes.trim(),
        ),
        clientMutationId: _pendingShopMutationId,
      );
      _shopOrders = [
        order,
        ..._shopOrders.where((item) => item.id != order.id),
      ];
      _cartItems = <CartItem>[];
      _pendingShopMutationId = '';
      await _persistCart();
      return ActionResult(
        success: true,
        message: 'تم تسجيل طلب المتجر رقم ${order.number}.',
      );
    } catch (error) {
      if (error is ApiException && error.isUnauthorized) {
        await _clearAccount(clearCachedData: true);
      }
      return ActionResult(success: false, message: _friendlyError(error));
    } finally {
      _isPlacingShopOrder = false;
      _notify();
    }
  }

  Future<ActionResult> submitRequest(
    ServiceItem service,
    RequestDraft draft,
  ) async {
    if (_session == null) {
      return const ActionResult(
        success: false,
        message: 'سجّل الدخول أولاً لحفظ الطلب في حسابك.',
      );
    }
    if (draft.phone.trim().isEmpty || draft.location.trim().isEmpty) {
      return const ActionResult(
        success: false,
        message: 'أدخل رقم الهاتف والموقع حتى يستطيع الفريق تأكيد الطلب.',
      );
    }

    final cleanDraft = RequestDraft(
      customerName: _session!.user.displayName.isNotEmpty
          ? _session!.user.displayName
          : draft.customerName.trim(),
      phone: _session!.user.phone.isNotEmpty
          ? _session!.user.phone
          : draft.phone.trim(),
      vehicle: draft.vehicle.trim().isEmpty ? 'غير محدد' : draft.vehicle.trim(),
      location: draft.location.trim(),
      preferredDate: draft.preferredDate.trim(),
      notes: draft.notes.trim(),
      priority: draft.priority,
    );
    _isSubmitting = true;
    _notify();

    final localRequest = _buildLocalRequest(service, cleanDraft);
    _requests = [localRequest, ..._requests];
    await _persist();

    try {
      final remote = await api.createServiceRequest(
        service,
        cleanDraft,
        clientMutationId: localRequest.clientMutationId,
      );
      _replaceRequest(localRequest, remote);
      await _persist();
      _apiStatus = ApiStatus.connected;
      _apiMessage = 'يمكنك استخدام حسابك وخدماتك من التطبيق أو الموقع.';
      _activeTab = AppTab.requests;
      return const ActionResult(
        success: true,
        message: 'تم تسجيل الطلب لدى فريق New Energy.',
      );
    } catch (error) {
      _activeTab = AppTab.requests;
      _apiStatus = ApiStatus.error;
      _apiMessage = _friendlyError(error);
      return const ActionResult(
        success: true,
        message: 'تم حفظ الطلب بأمان، وسيُرسل تلقائياً عند عودة الاتصال.',
      );
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  Future<ActionResult> syncRequests({bool manual = true}) async {
    if (_session == null) {
      return const ActionResult(
        success: false,
        message: 'سجّل الدخول لتحديث سجل الطلبات.',
      );
    }
    if (_isSyncing) {
      return const ActionResult(
        success: true,
        message: 'جارٍ تحديث الطلبات بالفعل.',
      );
    }

    _isSyncing = true;
    _notify();
    try {
      final unsynced = _requests.where((request) => !request.synced).toList();
      for (final request in unsynced) {
        final service = services.firstWhere(
          (item) => item.id == request.serviceId,
          orElse: () => services.first,
        );
        final uploaded = await api.createServiceRequest(
          service,
          RequestDraft(
            customerName: request.customerName,
            phone: request.phone,
            vehicle: request.vehicle,
            location: request.location,
            preferredDate: '',
            notes: request.notes,
            priority: request.priority,
          ),
          clientMutationId: request.clientMutationId,
        );
        _replaceRequest(request, uploaded);
        await _persist();
      }

      final initialSync = _syncCursor.isEmpty;
      final snapshot = await api.syncRequests(
        since: _syncCursor,
        reason: manual ? 'manual' : 'automatic',
      );
      _requests = initialSync
          ? [
              ...snapshot.requests,
              ..._requests.where((request) => !request.synced),
            ]
          : _mergeRemoteChanges(_requests, snapshot.requests);
      _syncCursor = snapshot.cursor;
      await _persist();
      _apiStatus = ApiStatus.connected;
      _apiMessage = 'يمكنك استخدام حسابك وخدماتك من التطبيق أو الموقع.';
      return const ActionResult(
        success: true,
        message: 'تم تحديث الطلبات بنجاح.',
      );
    } catch (error) {
      if (error is ApiException && error.isUnauthorized) {
        await _clearAccount(clearCachedData: true);
      }
      _apiStatus = ApiStatus.error;
      _apiMessage = _friendlyError(error);
      return ActionResult(success: false, message: _apiMessage);
    } finally {
      _isSyncing = false;
      _notify();
    }
  }

  Future<ActionResult> completePayment() async {
    if (!hasRequests) {
      return const ActionResult(
        success: false,
        message: 'لا توجد فاتورة مرتبطة بطلب حالي.',
      );
    }
    if (isPaymentPaid) {
      return const ActionResult(
        success: true,
        message: 'الفاتورة مسددة بالفعل.',
      );
    }
    if (activeInvoiceTotal <= 0) {
      return const ActionResult(
        success: false,
        message: 'بانتظار إصدار الفاتورة من فريق الصيانة قبل إرسال الدفع.',
      );
    }

    _isPaying = true;
    _notify();
    try {
      if (activeRequest.wordpressId == null) {
        await syncRequests(manual: false);
      }
      if (activeRequest.wordpressId == null) {
        return const ActionResult(
          success: false,
          message: 'سيتم إرسال بيانات الدفع بعد اكتمال حفظ الطلب.',
        );
      }

      final updated = await api.recordPayment(
        requestId: activeRequest.wordpressId!,
        paymentMethod: _selectedPayment,
        amount: activeInvoiceTotal,
      );
      _replaceActiveRequest(updated);
      await _persist();
      _activeTab = AppTab.reviews;
      unawaited(syncRequests(manual: false));
      return ActionResult(
        success: true,
        message: updated.paymentStatus == 'paid'
            ? 'تم تأكيد سداد الفاتورة.'
            : 'تم إرسال بيانات الدفع للمراجعة، وستظهر النتيجة تلقائياً.',
      );
    } catch (error) {
      _apiStatus = ApiStatus.error;
      _apiMessage = _friendlyError(error);
      return ActionResult(success: false, message: _apiMessage);
    } finally {
      _isPaying = false;
      _notify();
    }
  }

  Future<ActionResult> submitReview() async {
    if (!hasRequests || activeRequest.wordpressId == null) {
      return const ActionResult(
        success: false,
        message: 'انتظر اكتمال حفظ الطلب حتى تتمكن من إضافة التقييم.',
      );
    }

    _isReviewing = true;
    _notify();
    try {
      await api.submitReview(
        requestId: activeRequest.wordpressId!,
        rating: _rating,
        message: 'Submitted from the Flutter mobile app.',
      );
      unawaited(syncRequests(manual: false));
      return const ActionResult(success: true, message: 'شكراً لتقييمك.');
    } catch (error) {
      _apiStatus = ApiStatus.error;
      _apiMessage = _friendlyError(error);
      return ActionResult(success: false, message: _apiMessage);
    } finally {
      _isReviewing = false;
      _notify();
    }
  }

  void handleAppResumed() {
    if (_session != null) {
      unawaited(syncRequests(manual: false));
      unawaited(refreshShop());
    }
  }

  Future<void> _activateSession(AuthSession session) async {
    _session = session;
    api.setSessionToken(session.token);
    await authStore.saveSession(session);
    _requests = await store.loadRequests(_accountKey(session.user.id));
    _cartItems = await shopStore.loadCart(_accountKey(session.user.id));
    _authStatus = AuthStatus.signedIn;
    _syncCursor = '';
    _apiStatus = ApiStatus.connected;
    _apiMessage = 'يمكنك استخدام حسابك وخدماتك من التطبيق أو الموقع.';
    _activeTab = AppTab.home;
    _startAutomaticSync();
  }

  Future<void> _clearAccount({required bool clearCachedData}) async {
    final accountKey = _session == null ? '' : _accountKey(_session!.user.id);
    _syncTimer?.cancel();
    _syncTimer = null;
    api.setSessionToken(null);
    _session = null;
    _authStatus = AuthStatus.signedOut;
    _requests = <ServiceRequest>[];
    _cartItems = <CartItem>[];
    _shopOrders = <StoreOrder>[];
    _syncCursor = '';
    _pendingShopMutationId = '';
    _activeTab = AppTab.home;
    await authStore.clearSession();
    if (clearCachedData && accountKey.isNotEmpty) {
      await store.clearRequests(accountKey);
      await shopStore.clearCart(accountKey);
    }
  }

  void _startAutomaticSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (_session != null && !_isSyncing) {
        unawaited(syncRequests(manual: false));
      }
    });
  }

  ServiceRequest _buildLocalRequest(ServiceItem service, RequestDraft draft) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(36);
    final mutationId = 'flutter_${timestamp.toRadixString(36)}_$nonce';
    final number = 100000 + timestamp % 900000;
    return ServiceRequest(
      id: 'NE-$number',
      serviceId: service.id,
      title: service.title,
      status: service.id == 'tow' || service.id == 'emergency-visit'
          ? 'توجيه الفريق'
          : 'تم التسجيل',
      createdAt: 'الآن',
      priority: draft.priority,
      customerName: draft.customerName,
      phone: draft.phone,
      vehicle: draft.vehicle,
      location: draft.location,
      notes: draft.notes.isNotEmpty ? draft.notes : draft.preferredDate,
      paymentStatus: 'pending',
      clientMutationId: mutationId,
    );
  }

  List<ServiceRequest> _mergeRemoteChanges(
    List<ServiceRequest> current,
    List<ServiceRequest> changed,
  ) {
    final merged = List<ServiceRequest>.of(current);
    for (final remote in changed.reversed) {
      final index = merged.indexWhere((local) => _sameRequest(local, remote));
      if (index >= 0) {
        merged[index] = remote;
      } else {
        merged.insert(0, remote);
      }
    }
    return merged;
  }

  bool _sameRequest(ServiceRequest first, ServiceRequest second) {
    if (first.wordpressId != null && first.wordpressId == second.wordpressId) {
      return true;
    }
    if (first.clientMutationId.isNotEmpty &&
        first.clientMutationId == second.clientMutationId) {
      return true;
    }
    return first.id == second.id;
  }

  void _replaceRequest(ServiceRequest current, ServiceRequest updated) {
    _requests = _requests
        .map((request) => _sameRequest(request, current) ? updated : request)
        .toList();
  }

  void _replaceActiveRequest(ServiceRequest updated) {
    final current = activeRequest;
    _replaceRequest(current, updated);
  }

  Future<void> _persist() async {
    if (_session == null) return;
    await store.saveRequests(_accountKey(_session!.user.id), _requests);
  }

  Future<void> _persistCart() async {
    if (_session == null) return;
    await shopStore.saveCart(_accountKey(_session!.user.id), _cartItems);
  }

  void _reconcileCartProducts() {
    if (_cartItems.isEmpty || _products.isEmpty) return;
    final productsById = {for (final product in _products) product.id: product};
    _cartItems = _cartItems
        .map(
          (item) => item.copyWith(
            product: productsById[item.product.id] ?? item.product,
          ),
        )
        .toList();
    unawaited(_persistCart());
  }

  String _newMutationId(String prefix) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final nonce = Random.secure().nextInt(1 << 32).toRadixString(36);
    return '${prefix}_${timestamp.toRadixString(36)}_$nonce';
  }

  String _accountKey(int userId) => 'user_$userId';

  String _friendlyError(Object error) {
    if (error is TimeoutException) {
      return 'استغرق الاتصال وقتاً أطول من المتوقع. حاول مرة أخرى.';
    }
    if (error is ApiException) return error.message;
    return 'تعذر الاتصال بالخدمة الآن. التغييرات المحلية ما زالت محفوظة.';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
    super.dispose();
  }
}
