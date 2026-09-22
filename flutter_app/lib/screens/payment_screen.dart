import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../data/sample_data.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRequests) {
      return ContentPage(
        children: [
          const ScreenHeading(
            title: 'الدفع',
            subtitle: 'إرسال وسيلة السداد للفريق ومتابعة تأكيدها.',
            icon: Icons.payments_outlined,
          ),
          EmptyStateCard(
            icon: Icons.payments_outlined,
            title: 'لا توجد فاتورة حالية',
            body: 'ستظهر خيارات السداد بعد إنشاء الطلب وإصدار الفاتورة.',
            actionLabel: 'العودة للخدمات',
            onPressed: () => controller.selectTab(AppTab.home),
          ),
        ],
      );
    }

    final paid = controller.isPaymentPaid;
    final submitted = controller.isPaymentSubmitted;
    final invoiceReady = controller.activeInvoiceTotal > 0;
    return ContentPage(
      children: [
        const ScreenHeading(
          title: 'الدفع',
          subtitle: 'اختر وسيلة السداد وأرسلها للفريق لتأكيدها بأمان.',
          icon: Icons.payments_outlined,
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                formatMoney(controller.activeInvoiceTotal),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                paid
                    ? 'تم السداد بنجاح'
                    : submitted
                    ? 'تم الإرسال وجارٍ تأكيد السداد'
                    : !invoiceReady
                    ? 'بانتظار إصدار الفاتورة من فريق الصيانة'
                    : 'المبلغ المستحق لفاتورة الصيانة الحالية',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCAD5DA), fontSize: 13),
              ),
            ],
          ),
        ),
        const SectionTitle(title: 'وسيلة الدفع'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paymentMethods.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 92,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final method = paymentMethods[index];
            final active = controller.selectedPayment == method.id;
            return Card(
              color: active ? AppColors.tealSoft : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: active ? AppColors.teal : AppColors.border,
                  width: active ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: paid || submitted || !invoiceReady
                    ? null
                    : () => controller.selectPayment(method.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        method.icon,
                        color: active ? AppColors.teal : AppColors.muted,
                        size: 27,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        method.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active ? AppColors.teal : AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إيصال مبدئي',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'فاتورة ${controller.activeRequest.id}  •  ${paid
                                ? 'مسددة'
                                : submitted
                                ? 'قيد المراجعة'
                                : 'في انتظار السداد'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusPill(
                      label: paid
                          ? 'مكتمل'
                          : submitted
                          ? 'قيد المراجعة'
                          : 'مطلوب',
                      tone: paid ? StatusTone.good : StatusTone.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AsyncButton(
                  label: paid
                      ? 'تم السداد'
                      : submitted
                      ? 'بانتظار تأكيد الفريق'
                      : !invoiceReady
                      ? 'بانتظار إصدار الفاتورة'
                      : controller.isPaying
                      ? 'جاري تسجيل السداد'
                      : 'إرسال بيانات الدفع',
                  icon: paid
                      ? Icons.check_circle_outline
                      : submitted
                      ? Icons.schedule_outlined
                      : Icons.lock_outline,
                  busy: controller.isPaying,
                  onPressed: paid || submitted || !invoiceReady
                      ? null
                      : () => _pay(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pay(BuildContext context) async {
    final result = await controller.completePayment();
    if (context.mounted) {
      showAppMessage(context, result.message, isError: !result.success);
    }
  }
}
