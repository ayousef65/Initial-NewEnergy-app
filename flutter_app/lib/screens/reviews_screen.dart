import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/service_models.dart';
import '../theme/app_theme.dart';
import '../utils/external_actions.dart';
import '../widgets/common_widgets.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.hasRequests) {
      return ContentPage(
        children: [
          const ScreenHeading(
            title: 'التقييم',
            subtitle: 'بعد إتمام الخدمة، شارك تقييمك على فيسبوك وجوجل ماب.',
            icon: Icons.star_outline,
          ),
          EmptyStateCard(
            icon: Icons.star_outline,
            title: 'لا توجد خدمة للتقييم',
            body: 'يتاح التقييم بعد إتمام طلب الخدمة وتأكيد السداد.',
            actionLabel: 'العودة للخدمات',
            onPressed: () => controller.selectTab(AppTab.home),
          ),
        ],
      );
    }

    final enabled = controller.isPaymentPaid;
    return ContentPage(
      children: [
        const ScreenHeading(
          title: 'التقييم',
          subtitle: 'بعد إتمام الخدمة، شارك تقييمك على فيسبوك وجوجل ماب.',
          icon: Icons.star_outline,
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: enabled ? AppColors.tealSoft : AppColors.redSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.verified_outlined
                            : Icons.schedule_outlined,
                        color: enabled ? AppColors.teal : AppColors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enabled
                                ? 'الخدمة جاهزة للتقييم'
                                : 'التقييم بعد السداد',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            enabled
                                ? 'شكراً لاستخدامك New Energy. اختر عدد النجوم ثم منصة التقييم.'
                                : 'ستتاح روابط التقييم بمجرد تسجيل دفع الفاتورة.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.ltr,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    return IconButton(
                      tooltip: '$star من 5',
                      onPressed: enabled
                          ? () => controller.setRating(star)
                          : null,
                      iconSize: 34,
                      color: AppColors.gold,
                      disabledColor: AppColors.border,
                      icon: Icon(
                        star <= controller.rating
                            ? Icons.star
                            : Icons.star_outline,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AsyncButton(
                        label: 'فيسبوك',
                        icon: Icons.facebook,
                        outlined: true,
                        busy: controller.isReviewing,
                        onPressed: enabled
                            ? () => _review(
                                context,
                                controller.config.facebookReviewUrl,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AsyncButton(
                        label: 'جوجل ماب',
                        icon: Icons.location_on_outlined,
                        busy: controller.isReviewing,
                        onPressed: enabled
                            ? () => _review(
                                context,
                                controller.config.googleMapsReviewUrl,
                              )
                            : null,
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

  Future<void> _review(BuildContext context, String url) async {
    final result = await controller.submitReview();
    if (!context.mounted) return;
    if (!result.success) {
      showAppMessage(context, result.message, isError: true);
      return;
    }
    await openExternalUrl(context, url);
  }
}
