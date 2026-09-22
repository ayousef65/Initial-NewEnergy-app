import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';

class StageTimeline extends StatelessWidget {
  const StageTimeline({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < maintenanceStages.length; index += 1)
          _StageRow(
            index: index,
            isLast: index == maintenanceStages.length - 1,
            isComplete: index < currentIndex,
            isCurrent: index == currentIndex,
          ),
      ],
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.index,
    required this.isLast,
    required this.isComplete,
    required this.isCurrent,
  });

  final int index;
  final bool isLast;
  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final stage = maintenanceStages[index];
    final active = isComplete || isCurrent;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isComplete
                        ? AppColors.teal
                        : isCurrent
                        ? AppColors.surface
                        : AppColors.background,
                    border: Border.all(
                      color: active ? AppColors.teal : AppColors.border,
                      width: isCurrent ? 3 : 1.5,
                    ),
                  ),
                  child: isComplete
                      ? const Icon(Icons.check, color: Colors.white, size: 15)
                      : Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: active ? AppColors.teal : AppColors.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isComplete ? AppColors.teal : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.title,
                          style: TextStyle(
                            color: active ? AppColors.ink : AppColors.muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        const Text(
                          'المرحلة الحالية',
                          style: TextStyle(
                            color: AppColors.teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    stage.body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: active
                          ? AppColors.muted
                          : AppColors.muted.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
