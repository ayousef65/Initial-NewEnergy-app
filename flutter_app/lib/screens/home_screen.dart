import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../data/sample_data.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/external_actions.dart';
import '../widgets/common_widgets.dart';
import '../widgets/account_sheet.dart';
import '../widgets/service_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.controller,
    required this.onServiceSelected,
    required this.onOpenShop,
    required this.onProductSelected,
    super.key,
  });

  final AppController controller;
  final ValueChanged<ServiceItem> onServiceSelected;
  final VoidCallback onOpenShop;
  final ValueChanged<StoreProduct> onProductSelected;

  @override
  Widget build(BuildContext context) {
    return ContentPage(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        _HomeHeader(controller: controller),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ConnectionBanner(
            status: controller.apiStatus,
            message: controller.apiMessage,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle(title: 'الخدمات'),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 650 ? 3 : 2;
                  return GridView.builder(
                    itemCount: services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 180,
                    ),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return ServiceCard(
                        service: service,
                        onTap: () => onServiceSelected(service),
                      );
                    },
                  );
                },
              ),
              SectionTitle(
                title: 'متجر New Energy',
                action: TextButton.icon(
                  onPressed: onOpenShop,
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('عرض الكل'),
                ),
              ),
              if (controller.products.isEmpty)
                _ShopPreviewPlaceholder(
                  loading: controller.isShopLoading,
                  onTap: onOpenShop,
                )
              else
                ...controller.products
                    .take(4)
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: ProductTile(
                          product: product,
                          onTap: () => onProductSelected(product),
                        ),
                      ),
                    ),
              if (controller.hasRequests) ...[
                SectionTitle(
                  title: 'متابعة الصيانة',
                  action: TextButton(
                    onPressed: () => controller.selectTab(AppTab.tracking),
                    child: const Text('عرض التفاصيل'),
                  ),
                ),
                _MaintenancePreview(controller: controller),
              ] else ...[
                const SectionTitle(title: 'ابدأ أول طلب'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.assignment_add,
                          size: 38,
                          color: AppColors.brand,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'لا توجد طلبات في حسابك بعد',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'اختر الخدمة المناسبة وسيتابع الفريق حالتها معك هنا.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 14),
                        AsyncButton(
                          label: 'حجز الصيانة',
                          icon: Icons.car_repair_outlined,
                          onPressed: () => onServiceSelected(services.first),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopPreviewPlaceholder extends StatelessWidget {
  const _ShopPreviewPlaceholder({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(9),
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.brand,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loading
                      ? 'جارٍ تحميل منتجات المتجر'
                      : 'استعرض المنتجات المتاحة داخل التطبيق',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final lastUpdate = DateFormat(
      'EEEE، h:mm a',
      'ar_EG',
    ).format(DateTime.now());
    return ColoredBox(
      color: AppColors.brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      'assets/newenergy_logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                      semanticLabel: 'New Energy',
                    ),
                  ),
                ),
                Tooltip(
                  message: 'اتصال بخدمة العملاء',
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => openExternalUrl(
                      context,
                      'tel:${controller.config.servicePhone}',
                    ),
                    icon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(width: 7),
                Tooltip(
                  message: 'الحساب',
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _openAccount(context),
                    icon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Text(
              'لوحة الخدمة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'اطلب الخدمة وتابع الصيانة والفاتورة من مكان واحد.',
              style: TextStyle(
                color: Color(0xFFD7E0E4),
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryValue(
                      value: '${controller.requests.length}',
                      label: 'طلب نشط',
                    ),
                  ),
                  const _SummaryDivider(),
                  Expanded(
                    child: _SummaryValue(
                      value: controller.isPaymentPaid ? 'مدفوع' : 'مفتوح',
                      label: 'الفاتورة',
                    ),
                  ),
                  const _SummaryDivider(),
                  Expanded(
                    flex: 2,
                    child: _SummaryValue(value: lastUpdate, label: 'آخر تحديث'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAccount(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => AccountSheet(controller: controller),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFCBD1), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 32, color: Colors.white24);
  }
}

class _MaintenancePreview extends StatelessWidget {
  const _MaintenancePreview({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final request = controller.activeRequest;
    return Card(
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
                        '${request.id}  •  ${request.location}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill(label: request.status, tone: StatusTone.warning),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0.38,
                minHeight: 7,
                backgroundColor: AppColors.border,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              request.reportText.isNotEmpty ? request.reportText : 'تم فحص نظام الشحن وتسجيل الملاحظات. يمكنك مراجعة المراحل والتقرير الفني.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: AsyncButton(
                    label: 'التقرير',
                    icon: Icons.description_outlined,
                    outlined: true,
                    onPressed: () => controller.selectTab(AppTab.invoice),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AsyncButton(
                    label: 'الدفع',
                    icon: Icons.payments_outlined,
                    onPressed: () => controller.selectTab(AppTab.payment),
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
