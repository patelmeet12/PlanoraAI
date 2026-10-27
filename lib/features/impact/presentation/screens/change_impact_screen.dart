import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../budget/domain/models/budget_category.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/services/change_impact_analyzer.dart';

class ChangeImpactScreen extends ConsumerStatefulWidget {
  const ChangeImpactScreen({super.key});

  @override
  ConsumerState<ChangeImpactScreen> createState() => _ChangeImpactScreenState();
}

class _ChangeImpactScreenState extends ConsumerState<ChangeImpactScreen> {
  int? _simulatedGuestCount;
  double? _simulatedBudget;
  DateTime? _simulatedDate;

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.compare_arrows,
            title: 'No Event Active',
            message: 'Create an event to simulate change impacts.',
          );
        }

        final originalEvent = aggregate.event;
        final guestCount = _simulatedGuestCount ?? originalEvent.guestCount;
        final totalBudget = _simulatedBudget ?? originalEvent.totalBudget;
        final eventDate = _simulatedDate ?? originalEvent.date;

        final proposedEvent = originalEvent.copyWith(
          guestCount: guestCount,
          totalBudget: totalBudget,
          date: eventDate,
        );

        final impact = ChangeImpactAnalyzer.analyze(
          originalEvent: originalEvent,
          proposedEvent: proposedEvent,
          currentBudgetItems: aggregate.budgetItems,
          currentTasks: aggregate.tasks,
          currentVendors: aggregate.vendors,
        );

        final cur = originalEvent.currency;
        final hasDeltas = impact.guestCountDelta != 0 || impact.budgetDelta != 0 || impact.daysShiftDelta != 0;

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
                      Text('Change Impact Analyzer', style: theme.textTheme.headlineMedium),
                      Text(
                        'Signature adaptive planning: simulate changes before committing them',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (hasDeltas)
                    ElevatedButton.icon(
                      onPressed: () => _applyChanges(proposedEvent),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Apply Changes to Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Simulation Control Sliders Card
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Simulation Controls', style: theme.textTheme.titleMedium),
                        if (hasDeltas)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _simulatedGuestCount = null;
                                _simulatedBudget = null;
                                _simulatedDate = null;
                              });
                            },
                            child: const Text('Reset to Current'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Guest Count Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Guest Count: $guestCount attendees', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          impact.guestCountDelta > 0
                              ? '+${impact.guestCountDelta} guests'
                              : (impact.guestCountDelta < 0 ? '${impact.guestCountDelta} guests' : 'No change'),
                          style: TextStyle(
                            color: impact.guestCountDelta != 0 ? theme.colorScheme.primary : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: guestCount.toDouble(),
                      min: 10,
                      max: 500,
                      divisions: 49,
                      label: '$guestCount guests',
                      onChanged: (v) => setState(() => _simulatedGuestCount = v.round()),
                    ),
                    const SizedBox(height: 12),

                    // Budget Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Budget: ${CurrencyFormatter.format(totalBudget, currency: cur)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          impact.budgetDelta > 0
                              ? '+${CurrencyFormatter.format(impact.budgetDelta, currency: cur)}'
                              : (impact.budgetDelta < 0
                                  ? '-${CurrencyFormatter.format(impact.budgetDelta.abs(), currency: cur)}'
                                  : 'No change'),
                          style: TextStyle(
                            color: impact.budgetDelta != 0 ? theme.colorScheme.primary : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: totalBudget.clamp(1000.0, 100000.0),
                      min: 1000,
                      max: 100000,
                      divisions: 99,
                      label: CurrencyFormatter.format(totalBudget, currency: cur),
                      onChanged: (v) => setState(() => _simulatedBudget = v),
                    ),
                    const SizedBox(height: 12),

                    // Date Shifter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Date: ${DateFormatter.formatMediumDate(eventDate)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: eventDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                            );
                            if (picked != null) {
                              setState(() => _simulatedDate = picked);
                            }
                          },
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Before & After Delta Comparison Cards
              Text('Before vs. After Delta Comparison', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final beforeCard = AccessibleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('CURRENT PLAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            StatusBadge(label: impact.originalBudgetState.label, type: BadgeType.neutral, compact: true),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildMetricRow('Guest Count', '${originalEvent.guestCount} guests'),
                        _buildMetricRow('Total Budget', CurrencyFormatter.format(originalEvent.totalBudget, currency: cur)),
                        _buildMetricRow('Cost per Guest', CurrencyFormatter.format(impact.originalCostPerGuest, currency: cur)),
                        _buildMetricRow('Target Date', DateFormatter.formatMediumDate(originalEvent.date)),
                      ],
                    ),
                  );

                  final afterCard = AccessibleCard(
                    borderColor: theme.colorScheme.primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROPOSED IMPACT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1, color: theme.colorScheme.primary),
                            ),
                            StatusBadge(
                              label: impact.proposedBudgetState.label,
                              type: impact.proposedBudgetState == BudgetThresholdState.overBudget
                                  ? BadgeType.error
                                  : (impact.proposedBudgetState == BudgetThresholdState.approachingLimit
                                      ? BadgeType.warning
                                      : BadgeType.success),
                              compact: true,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildMetricRow('Guest Count', '$guestCount guests (${impact.guestCountDelta >= 0 ? "+" : ""}${impact.guestCountDelta})'),
                        _buildMetricRow('Total Budget', CurrencyFormatter.format(totalBudget, currency: cur)),
                        _buildMetricRow('Cost per Guest', CurrencyFormatter.format(impact.proposedCostPerGuest, currency: cur)),
                        _buildMetricRow('Estimated Catering Shift', '${impact.estimatedCateringImpact >= 0 ? "+" : ""}${CurrencyFormatter.format(impact.estimatedCateringImpact, currency: cur)}'),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: beforeCard),
                        const SizedBox(width: 16),
                        Expanded(child: afterCard),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      beforeCard,
                      const SizedBox(height: 16),
                      afterCard,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Warnings and Actionable Recommendations
              if (impact.warnings.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning, color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Text('Risk Alerts & Constraints Flagged', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...impact.warnings.map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $w', style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D))),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (impact.recommendations.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Strategic Planning Recommendations', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...impact.recommendations.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $r', style: theme.textTheme.bodySmall),
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error analyzing impact: $e')),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _applyChanges(EventModel proposed) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Apply Simulated Adjustments?',
      content: 'This will update your event baseline (Guest Count: ${proposed.guestCount}, Budget: \$${proposed.totalBudget.toStringAsFixed(0)}). '
          'Confirmed bookings and expenses will remain locked.',
      confirmLabel: 'Confirm & Apply',
    );

    if (confirm == true) {
      await ref.read(activeEventProvider.notifier).updateEventProfile(proposed);
      if (!mounted) return;

      setState(() {
        _simulatedGuestCount = null;
        _simulatedBudget = null;
        _simulatedDate = null;
      });

      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('✓ Changes applied to active event!'),
        ),
      );
    }
  }
}
