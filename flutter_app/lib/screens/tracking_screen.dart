import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/stage_timeline.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRequests) {
      return ContentPage(
        children: [
          const ScreenHeading(
            title: 'متابعة الصيانة',
            subtitle: 'مراحل الصيانة والمشاكل والإصلاحات تظهر أولاً بأول.',
            icon: Icons.timeline_outlined,
          ),
          EmptyStateCard(
            icon: Icons.car_repair_outlined,
            title: 'لا يوجد طلب للمتابعة',
            body: 'احجز خدمة أولاً لتظهر مراحل العمل والتقرير الفني هنا.',
            actionLabel: 'العودة للخدمات',
            onPressed: () => controller.selectTab(AppTab.home),
          ),
        ],
      );
    }

    final request = controller.activeRequest;
    return ContentPage(
      children: [
        const ScreenHeading(
          title: 'متابعة الصيانة',
          subtitle: 'مراحل الصيانة والمشاكل والإصلاحات تظهر أولاً بأول.',
          icon: Icons.timeline_outlined,
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
                            request.id,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${request.vehicle}  •  ${request.location}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(label: request.status, tone: StatusTone.good),
                  ],
                ),
                const SizedBox(height: 22),
                StageTimeline(
                  currentIndex: maintenanceStageIndex(request.status),
                ),
              ],
            ),
          ),
        ),
        const SectionTitle(title: 'المشاكل والإصلاحات'),
        if (controller.activeRepairItems.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'لم يضف الفريق بنود الفحص أو الإصلاح بعد.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...controller.activeRepairItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.tealSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.build_outlined,
                          color: AppColors.teal,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.issue,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                StatusPill(
                                  label: item.status,
                                  tone: _repairTone(item.status),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.fix,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  StatusTone _repairTone(String status) {
    if (status == 'تم الإصلاح' || status == 'غير مطلوب') return StatusTone.good;
    if (status == 'مطلوب') return StatusTone.danger;
    return StatusTone.warning;
  }
}
