import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/models/run_sheet_item.dart';
import '../../domain/services/run_sheet_generator.dart';

class RunSheetScreen extends ConsumerWidget {
  const RunSheetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.schedule_outlined,
            title: 'No Event Active',
            message: 'Create an event to view the event-day run sheet.',
          );
        }

        final runSheet = aggregate.runSheet;
        final anomalies = RunSheetGenerator.detectAnomalies(runSheet);
        final completedCount = runSheet.where((r) => r.isCompleted).length;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Event-Day Run Sheet', style: theme.textTheme.headlineMedium),
                      Text(
                        'Chronological minute-by-minute coordinator schedule ($completedCount of ${runSheet.length} completed)',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🖨️ Ready for printing! Use browser Print (Cmd+P / Ctrl+P) to generate hardcopy.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Schedule'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scheduling Anomalies & Buffer Warnings
              if (anomalies.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber, color: AppColors.warning),
                          SizedBox(width: 8),
                          Text(
                            'Schedule Anomalies Detected',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...anomalies.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${a.title}: ${a.description}', style: const TextStyle(fontSize: 13, color: Color(0xFF78350F))),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Chronological Items List
              if (runSheet.isEmpty)
                const EmptyStateView(
                  icon: Icons.access_time,
                  title: 'No Run Sheet Items',
                  message: 'Generate a plan to establish the master day-of schedule.',
                )
              else
                ...runSheet.map((item) => _buildRunSheetItemCard(context, ref, item)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading run sheet: $e')),
    );
  }

  Widget _buildRunSheetItemCard(BuildContext context, WidgetRef ref, RunSheetItem item) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AccessibleCard(
        backgroundColor: item.isCompleted ? theme.colorScheme.surfaceContainerHighest.withAlpha(80) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: item.isCompleted,
              onChanged: (_) {
                ref.read(activeEventProvider.notifier).toggleRunSheetItem(item.id);
              },
            ),
            const SizedBox(width: 10),
            // Time Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${item.startTime} - ${item.endTime}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      StatusBadge(label: item.category, type: BadgeType.neutral, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.description, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 16,
                    children: [
                      if (item.location != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item.location!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      if (item.leadPerson != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(item.leadPerson!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
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
