import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/shop_widgets.dart';
import 'cart_screen.dart';
import 'product_details_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final products = _filteredProducts(widget.controller.products);
        final categories =
            widget.controller.products
                .expand((product) => product.categories)
                .toSet()
                .toList()
              ..sort();
        return Scaffold(
          appBar: AppBar(
            title: const Text('متجر New Energy'),
            actions: [
              CartButton(
                count: widget.controller.cartCount,
                onPressed: _openCart,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ContentPage(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'ابحث عن منتج أو رقم الصنف',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 7),
                          child: FilterChip(
                            label: const Text('الكل'),
                            selected: _selectedCategory.isEmpty,
                            onSelected: (_) {
                              setState(() => _selectedCategory = '');
                            },
                          ),
                        ),
                        ...categories.map(
                          (category) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 7),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) {
                                setState(() => _selectedCategory = category);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (widget.controller.isShopLoading &&
                    widget.controller.products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (products.isEmpty)
                  _ShopEmptyState(hasSearch: _hasFilter)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 650 ? 3 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 262,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return StoreProductCard(
                            product: product,
                            onTap: () => _openProduct(product),
                            onAdd: () => _addProduct(product),
                          );
                        },
                      );
                    },
                  ),
                if (widget.controller.shopOrders.isNotEmpty) ...[
                  const SectionTitle(title: 'طلبات المتجر الأخيرة'),
                  ...widget.controller.shopOrders
                      .take(5)
                      .map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _OrderTile(order: order),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool get _hasFilter =>
      _searchController.text.trim().isNotEmpty || _selectedCategory.isNotEmpty;

  List<StoreProduct> _filteredProducts(List<StoreProduct> products) {
    final search = _searchController.text.trim().toLowerCase();
    return products.where((product) {
      final matchesCategory =
          _selectedCategory.isEmpty ||
          product.categories.contains(_selectedCategory);
      final haystack = [
        product.name,
        product.sku,
        ...product.categories,
      ].join(' ').toLowerCase();
      return matchesCategory && (search.isEmpty || haystack.contains(search));
    }).toList();
  }

  Future<void> _refresh() async {
    final result = await widget.controller.refreshShop();
    if (!result.success && mounted) {
      showAppMessage(context, result.message, isError: true);
    }
  }

  Future<void> _addProduct(StoreProduct product) async {
    final result = await widget.controller.addProductToCart(product);
    if (mounted) {
      showAppMessage(context, result.message, isError: !result.success);
    }
  }

  void _openProduct(StoreProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(
          controller: widget.controller,
          product: product,
        ),
      ),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartScreen(controller: widget.controller),
      ),
    );
  }
}

class _ShopEmptyState extends StatelessWidget {
  const _ShopEmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            hasSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد منتجات متاحة حالياً',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'طلب #${order.number}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.itemCount} منتج  •  ${formatApiDate(order.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(
                  label: localizeOrderStatus(order.status),
                  tone: order.status == 'completed'
                      ? StatusTone.good
                      : StatusTone.warning,
                ),
                const SizedBox(height: 5),
                Text(
                  '${order.currency} ${formatDecimal(order.total)}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
