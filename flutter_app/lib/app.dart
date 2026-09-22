import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/app_controller.dart';
import 'models/service_models.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/requests_screen.dart';
import 'screens/reviews_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/tracking_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/common_widgets.dart';
import 'widgets/request_sheet.dart';

class NewEnergyApp extends StatefulWidget {
  const NewEnergyApp({required this.controller, super.key});

  final AppController controller;

  @override
  State<NewEnergyApp> createState() => _NewEnergyAppState();
}

class _NewEnergyAppState extends State<NewEnergyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.handleAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New Energy Service',
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      home: _AppRoot(controller: widget.controller),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: switch (controller.authStatus) {
            AuthStatus.checking => const _AuthLoadingView(
              key: ValueKey('auth-loading'),
            ),
            AuthStatus.signedOut => AuthScreen(
              key: const ValueKey('auth-screen'),
              controller: controller,
            ),
            AuthStatus.signedIn => AppShell(
              key: const ValueKey('app-shell'),
              controller: controller,
            ),
          },
        );
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brand,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/newenergy_logo.png',
                width: 280,
                semanticLabel: 'New Energy',
              ),
              const SizedBox(height: 30),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({required this.controller, super.key});

  final AppController controller;

  static const _navigationTabs = <AppTab>[
    AppTab.home,
    AppTab.requests,
    AppTab.tracking,
    AppTab.payment,
    AppTab.reviews,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(controller.activeTab),
                child: _activeScreen(context),
              ),
            ),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: NavigationBar(
              selectedIndex: _selectedNavigationIndex,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (index) {
                controller.selectTab(_navigationTabs[index]);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'الرئيسية',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'الطلبات',
                ),
                NavigationDestination(
                  icon: Icon(Icons.car_repair_outlined),
                  selectedIcon: Icon(Icons.car_repair),
                  label: 'الصيانة',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments),
                  label: 'الدفع',
                ),
                NavigationDestination(
                  icon: Icon(Icons.star_outline),
                  selectedIcon: Icon(Icons.star),
                  label: 'التقييم',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _selectedNavigationIndex {
    if (controller.activeTab == AppTab.invoice) return 2;
    final index = _navigationTabs.indexOf(controller.activeTab);
    return index < 0 ? 0 : index;
  }

  Widget _activeScreen(BuildContext context) {
    return switch (controller.activeTab) {
      AppTab.home => HomeScreen(
        controller: controller,
        onServiceSelected: (service) => _openRequestSheet(context, service),
        onOpenShop: () => _openShop(context),
        onProductSelected: (product) => _openProduct(context, product),
      ),
      AppTab.requests => RequestsScreen(controller: controller),
      AppTab.tracking => TrackingScreen(controller: controller),
      AppTab.invoice => InvoiceScreen(controller: controller),
      AppTab.payment => PaymentScreen(controller: controller),
      AppTab.reviews => ReviewsScreen(controller: controller),
    };
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShopScreen(controller: controller),
      ),
    );
  }

  void _openProduct(BuildContext context, StoreProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProductDetailsScreen(controller: controller, product: product),
      ),
    );
  }

  Future<void> _openRequestSheet(
    BuildContext context,
    ServiceItem service,
  ) async {
    final result = await showModalBottomSheet<ActionResult>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.ink.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) =>
          RequestSheet(controller: controller, service: service),
    );
    if (result != null && context.mounted) {
      showAppMessage(context, result.message, isError: !result.success);
    }
  }
}
