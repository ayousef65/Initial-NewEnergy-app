import 'package:flutter/material.dart';

import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class CartButton extends StatelessWidget {
  const CartButton({required this.count, required this.onPressed, super.key});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'سلة المشتريات',
      child: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        offset: const Offset(-3, 5),
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ),
    );
  }
}

class ShopProductImage extends StatelessWidget {
  const ShopProductImage({this.url, this.fit = BoxFit.cover, super.key});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: fit,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: AppColors.blueSoft,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return const ColoredBox(
      color: AppColors.blueSoft,
      child: Center(
        child: Icon(
          Icons.electric_bolt_outlined,
          color: AppColors.blue,
          size: 34,
        ),
      ),
    );
  }
}

class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
    super.key,
  });

  final StoreProduct product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final price = formatProductPrice(
      rawPrice: product.price,
      currencySymbol: product.currencySymbol,
      minorUnit: product.currencyMinorUnit,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ShopProductImage(url: product.imageUrl),
                  if (product.onSale)
                    const PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: _SaleLabel(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton.filled(
                          padding: EdgeInsets.zero,
                          tooltip: product.canAddToCart
                              ? 'إضافة إلى السلة'
                              : 'عرض المنتج',
                          onPressed: product.canAddToCart ? onAdd : onTap,
                          icon: Icon(
                            product.canAddToCart
                                ? Icons.add_shopping_cart
                                : Icons.tune,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final int quantity;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              tooltip: 'تقليل الكمية',
              padding: EdgeInsets.zero,
              onPressed: onDecrease,
              icon: const Icon(Icons.remove, size: 18),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            height: 38,
            child: IconButton(
              tooltip: 'زيادة الكمية',
              padding: EdgeInsets.zero,
              onPressed: onIncrease,
              icon: const Icon(Icons.add, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaleLabel extends StatelessWidget {
  const _SaleLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'عرض',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
