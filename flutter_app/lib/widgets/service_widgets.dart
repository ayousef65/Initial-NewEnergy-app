import 'package:flutter/material.dart';

import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'common_widgets.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({required this.service, required this.onTap, super.key});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: service.color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: service.tint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(service.icon, color: service.color, size: 25),
                    ),
                    const Spacer(),
                    Text(
                      service.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onTap, super.key});

  final StoreProduct product;
  final VoidCallback onTap;

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
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _ProductImage(url: product.imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      price,
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_left, size: 22, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _fallback();
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: AppColors.blueSoft,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return const ColoredBox(
      color: AppColors.blueSoft,
      child: Icon(Icons.electric_bolt_outlined, color: AppColors.blue),
    );
  }
}

class RequestCard extends StatelessWidget {
  const RequestCard({
    required this.request,
    required this.onTrack,
    required this.onInvoice,
    super.key,
  });

  final ServiceRequest request;
  final VoidCallback onTrack;
  final VoidCallback onInvoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${request.id}  •  ${request.createdAt}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: request.status,
                    tone: _requestTone(request.status),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 12) / 3;
                  return Wrap(
                    spacing: 6,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: InfoItem(
                          icon: Icons.directions_car_outlined,
                          label: 'السيارة',
                          value: request.vehicle,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: InfoItem(
                          icon: Icons.location_on_outlined,
                          label: 'الموقع',
                          value: request.location,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: InfoItem(
                          icon: Icons.bolt_outlined,
                          label: 'الأولوية',
                          value: request.priority,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  request.notes,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: AsyncButton(
                      label: 'متابعة',
                      icon: Icons.timeline_outlined,
                      onPressed: onTrack,
                      outlined: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AsyncButton(
                      label: 'الفاتورة',
                      icon: Icons.receipt_long_outlined,
                      onPressed: onInvoice,
                      outlined: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

StatusTone _requestTone(String status) {
  if (status == 'تم السداد' || status == 'مغلق') return StatusTone.good;
  if (status == 'فشل الدفع') return StatusTone.danger;
  return StatusTone.warning;
}
