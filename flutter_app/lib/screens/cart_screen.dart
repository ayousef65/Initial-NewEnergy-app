import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/shop_widgets.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('سلة المشتريات')),
          body: controller.cartItems.isEmpty
              ? _EmptyCart(onBack: () => Navigator.of(context).pop())
              : ContentPage(
                  children: [
                    ...controller.cartItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CartItemTile(
                          item: item,
                          onDecrease: () => controller.updateCartQuantity(
                            item.product.id,
                            item.quantity - 1,
                          ),
                          onIncrease: item.quantity < 20
                              ? () => controller.updateCartQuantity(
                                  item.product.id,
                                  item.quantity + 1,
                                )
                              : null,
                          onRemove: () =>
                              controller.removeCartItem(item.product.id),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: controller.clearCart,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('إفراغ السلة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.red,
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: controller.cartItems.isEmpty
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'الإجمالي المبدئي',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${controller.cartCurrency}${formatDecimal(controller.cartTotal)}',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () => _openCheckout(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('متابعة الطلب'),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(controller: controller),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: ShopProductImage(url: item.product.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatProductPrice(
                          rawPrice: item.product.price,
                          currencySymbol: item.product.currencySymbol,
                          minorUnit: item.product.currencyMinorUnit,
                        ),
                        style: const TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف المنتج',
                  onPressed: onRemove,
                  color: AppColors.red,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                QuantityStepper(
                  quantity: item.quantity,
                  onDecrease: onDecrease,
                  onIncrease: onIncrease,
                ),
                const Spacer(),
                Text(
                  '${item.product.currencySymbol}${formatDecimal(item.total)}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 54,
              color: AppColors.muted,
            ),
            const SizedBox(height: 14),
            Text(
              'السلة فارغة',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف المنتجات التي تحتاجها من المتجر.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('العودة للمتجر'),
            ),
          ],
        ),
      ),
    );
  }
}
