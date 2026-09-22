import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRequests) {
      return ContentPage(
        children: [
          const ScreenHeading(
            title: 'التقرير والفاتورة',
            subtitle: 'ملخص فني واضح مع بنود التكلفة قبل السداد.',
            icon: Icons.receipt_long_outlined,
          ),
          EmptyStateCard(
            icon: Icons.receipt_long_outlined,
            title: 'لا يوجد تقرير حتى الآن',
            body: 'يظهر التقرير والفاتورة هنا بعد إنشاء طلب وفحص السيارة.',
            actionLabel: 'العودة للخدمات',
            onPressed: () => controller.selectTab(AppTab.home),
          ),
        ],
      );
    }

    final request = controller.activeRequest;
    return ContentPage(
      children: [
        ScreenHeading(
          title: 'التقرير والفاتورة',
          subtitle: 'ملخص فني واضح مع بنود التكلفة قبل السداد.',
          icon: Icons.receipt_long_outlined,
          trailing: Tooltip(
            message: 'العودة',
            child: IconButton(
              onPressed: () => controller.selectTab(AppTab.tracking),
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            'تقرير فني رقم ${request.id}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'مركز خدمة القاهرة',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: controller.isPaymentPaid ? 'مدفوعة' : 'غير مدفوعة',
                      tone: controller.isPaymentPaid
                          ? StatusTone.good
                          : StatusTone.danger,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نتيجة الفحص',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        request.reportText.isNotEmpty
                            ? request.reportText
                            : 'لم يضف الفريق نتيجة الفحص بعد.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (controller.activeInvoiceItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'لم تصدر بنود الفاتورة بعد.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...controller.activeInvoiceItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatMoney(item.amount),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Divider(height: 25),
                Row(
                  children: [
                    Text(
                      'الإجمالي',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(controller.activeInvoiceTotal),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: AsyncButton(
                        label: 'نسخ التقرير',
                        icon: Icons.copy_outlined,
                        outlined: true,
                        onPressed: () => _copyReport(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AsyncButton(
                        label: controller.isPaymentPaid
                            ? 'تم السداد'
                            : 'سداد الآن',
                        icon: controller.isPaymentPaid
                            ? Icons.check_circle_outline
                            : Icons.payments_outlined,
                        onPressed: controller.isPaymentPaid
                            ? null
                            : () => controller.selectTab(AppTab.payment),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _copyReport(BuildContext context) async {
    final request = controller.activeRequest;
    final lines = <String>[
      'تقرير New Energy - ${request.id}',
      request.reportText.isNotEmpty
          ? request.reportText
          : 'نتيجة الفحص متاحة داخل التطبيق.',
      ...controller.activeInvoiceItems.map(
        (item) => '${item.label}: ${formatMoney(item.amount)}',
      ),
      'الإجمالي: ${formatMoney(controller.activeInvoiceTotal)}',
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (context.mounted) showAppMessage(context, 'تم نسخ التقرير والفاتورة.');
  }
}
