import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/shop_widgets.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.controller,
    required this.product,
    super.key,
  });

  final AppController controller;
  final StoreProduct product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final product = widget.controller.products.firstWhere(
          (item) => item.id == widget.product.id,
          orElse: () => widget.product,
        );
        final price = formatProductPrice(
          rawPrice: product.price,
          currencySymbol: product.currencySymbol,
          minorUnit: product.currencyMinorUnit,
        );
        return Scaffold(
          appBar: AppBar(
            title: const Text('تفاصيل المنتج'),
            actions: [
              CartButton(
                count: widget.controller.cartCount,
                onPressed: _openCart,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: ColoredBox(
                        color: AppColors.surface,
                        child: ShopProductImage(
                          url: product.imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                              ),
                              if (product.onSale) ...[
                                const SizedBox(width: 8),
                                const StatusPill(
                                  label: 'عرض',
                                  tone: StatusTone.danger,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            price,
                            style: const TextStyle(
                              color: AppColors.brand,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              StatusPill(
                                label: product.isInStock
                                    ? 'متوفر'
                                    : 'غير متوفر',
                                tone: product.isInStock
                                    ? StatusTone.good
                                    : StatusTone.danger,
                              ),
                              if (product.sku.isNotEmpty)
                                StatusPill(label: 'الصنف ${product.sku}'),
                              ...product.categories.map(
                                (category) => StatusPill(label: category),
                              ),
                            ],
                          ),
                          if (product.averageRating > 0) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: AppColors.gold,
                                  size: 20,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${product.averageRating.toStringAsFixed(1)} (${product.ratingCount})',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          if (_description(product).isNotEmpty) ...[
                            const SectionTitle(title: 'عن المنتج'),
                            Text(
                              _description(product),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Text(
                                'الكمية',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              QuantityStepper(
                                quantity: _quantity,
                                onDecrease: _quantity > 1
                                    ? () => setState(() => _quantity -= 1)
                                    : null,
                                onIncrease: _quantity < 20
                                    ? () => setState(() => _quantity += 1)
                                    : null,
                              ),
                            ],
                          ),
                          if (product.type == 'variable') ...[
                            const SizedBox(height: 14),
                            const Text(
                              'هذا المنتج له مواصفات متعددة. سيتاح اختياره بعد إضافة خياراته إلى المتجر.',
                              style: TextStyle(
                                color: AppColors.amber,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: FilledButton.icon(
              onPressed: product.canAddToCart
                  ? () => _addProduct(product)
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: Text(
                product.canAddToCart
                    ? 'إضافة إلى السلة'
                    : 'غير متاح للطلب حالياً',
              ),
            ),
          ),
        );
      },
    );
  }

  String _description(StoreProduct product) {
    return product.description.isNotEmpty
        ? product.description
        : product.shortDescription;
  }

  Future<void> _addProduct(StoreProduct product) async {
    final result = await widget.controller.addProductToCart(
      product,
      quantity: _quantity,
    );
    if (mounted) {
      showAppMessage(context, result.message, isError: !result.success);
    }
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartScreen(controller: widget.controller),
      ),
    );
  }
}
