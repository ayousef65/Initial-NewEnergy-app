import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../widgets/common_widgets.dart';
import '../widgets/service_widgets.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final result = await controller.syncRequests();
        if (!result.success && context.mounted) {
          showAppMessage(context, result.message, isError: true);
        }
      },
      child: ContentPage(
        children: [
          const ScreenHeading(
            title: 'طلباتك',
            subtitle:
                'كل طلب صيانة أو زيارة أو شراء يظهر هنا مع حالته الحالية.',
            icon: Icons.assignment_outlined,
          ),
          if (controller.requests.isEmpty)
            EmptyStateCard(
              icon: Icons.assignment_add,
              title: 'لا توجد طلبات بعد',
              body: 'ابدأ طلب خدمة جديد وسيظهر سجله وتحديثاته هنا.',
              actionLabel: 'العودة للخدمات',
              onPressed: () => controller.selectTab(AppTab.home),
            )
          else
            ...controller.requests.map(
              (request) => RequestCard(
                request: request,
                onTrack: () => controller.selectTab(AppTab.tracking),
                onInvoice: () => controller.selectTab(AppTab.invoice),
              ),
            ),
        ],
      ),
    );
  }
}
