import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/models/budget_adjustment.dart';
import '../../domain/models/budget_category.dart';
import '../../domain/models/budget_item.dart';
import '../../domain/services/budget_optimizer_service.dart';

class BudgetPlannerScreen extends ConsumerStatefulWidget {
  const BudgetPlannerScreen({super.key});

  @override
  ConsumerState<BudgetPlannerScreen> createState() => _BudgetPlannerScreenState();
}

class _BudgetPlannerScreenState extends ConsumerState<BudgetPlannerScreen> {
  BudgetCategory? _filterCategory;
  final Set<String> _dismissedProposals = {};

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.pie_chart_outline,
            title: 'No Event Active',
            message: 'Please create an event first to manage budgets.',
          );
        }

        final event = aggregate.event;
        final cur = event.currency;
        final summary = BudgetOptimizerService.calculateSummary(
          totalBudget: event.totalBudget,
          guestCount: event.guestCount,
          items: aggregate.budgetItems,
        );

        final overage = summary.totalPlannedExpenses - event.totalBudget;
        final allProposals = overage > 0 || summary.thresholdState == BudgetThresholdState.approachingLimit
            ? BudgetOptimizerService.generateAdjustments(
                totalBudget: event.totalBudget,
                items: aggregate.budgetItems,
                overageAmount: overage > 0 ? overage : (summary.totalPlannedExpenses * 0.1),
              )
            : <BudgetAdjustmentProposal>[];

        final activeProposals = allProposals.where((p) => !_dismissedProposals.contains(p.id)).toList();

        final filteredItems = _filterCategory == null
            ? aggregate.budgetItems
            : aggregate.budgetItems.where((i) => i.category == _filterCategory).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Intelligent Budget Optimizer', style: theme.textTheme.headlineMedium),
                      Text(
                        'Real-time cost tracking, category breakdowns, and non-destructive optimizations',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExpenseDialog(context, aggregate.event.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Expense Item'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Benchmark Disclaimer Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurface.withAlpha(160)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estimated prices represent intelligent planning benchmarks. Mark expenses as Confirmed once signed contracts are finalized.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // KPI Summary Metrics Card
              _buildMetricsHeaderCard(context, event, summary),
              const SizedBox(height: 24),

              // Smart Optimization Proposals Alert (if approaching or over budget)
              if (activeProposals.isNotEmpty)
                _buildOptimizationProposals(context, activeProposals, overage, cur),
              if (activeProposals.isNotEmpty) const SizedBox(height: 24),

              // Category Allocation Visualizer
              _buildCategoryAllocationVisualizer(context, summary, cur),
              const SizedBox(height: 24),

              // Filter Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All Categories'),
                    selected: _filterCategory == null,
                    onSelected: (_) => setState(() => _filterCategory = null),
                  ),
                  ...BudgetCategory.values.map((cat) {
                    final isSel = _filterCategory == cat;
                    return FilterChip(
                      label: Text(cat.displayName),
                      selected: isSel,
                      onSelected: (val) {
                        setState(() => _filterCategory = val ? cat : null);
                      },
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Expense Items Table / List
              AccessibleCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Itemized Expenses (${filteredItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tap item to edit or toggle confirmed status',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    if (filteredItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('No expense items found in this category.')),
                      ),

                    ...filteredItems.map((item) => _buildExpenseItemTile(context, item, cur)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading budget: $e')),
    );
  }

  Widget _buildMetricsHeaderCard(BuildContext context, dynamic event, BudgetSummary summary) {
    final theme = Theme.of(context);
    final cur = event.currency;

    BadgeType badgeType;
    IconData badgeIcon;
    switch (summary.thresholdState) {
      case BudgetThresholdState.withinBudget:
        badgeType = BadgeType.success;
        badgeIcon = Icons.check_circle_outline;
        break;
      case BudgetThresholdState.approachingLimit:
        badgeType = BadgeType.warning;
        badgeIcon = Icons.warning_amber_outlined;
        break;
      case BudgetThresholdState.overBudget:
        badgeType = BadgeType.error;
        badgeIcon = Icons.error_outline;
        break;
    }

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Budget Performance', style: theme.textTheme.titleLarge),
              StatusBadge(
                label: summary.thresholdState.label,
                icon: badgeIcon,
                type: badgeType,
              ),
            ],
          ),
          const SizedBox(height: 20),

          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _buildStatMetric(
                context,
                'Total Budget',
                CurrencyFormatter.format(summary.totalBudget, currency: cur),
                subtitle: 'Fixed planning ceiling',
              ),
              _buildStatMetric(
                context,
                'Confirmed Committed',
                CurrencyFormatter.format(summary.confirmedExpenses, currency: cur),
                subtitle: 'Locked contracts & deposits',
                color: theme.colorScheme.primary,
              ),
              _buildStatMetric(
                context,
                'Estimated Remaining',
                CurrencyFormatter.format(summary.estimatedExpenses, currency: cur),
                subtitle: 'Unconfirmed allocations',
              ),
              _buildStatMetric(
                context,
                'Balance Available',
                CurrencyFormatter.format(summary.remainingBalance, currency: cur),
                subtitle: summary.remainingBalance < 0 ? 'Deficit amount' : 'Under budget',
                color: summary.remainingBalance < 0 ? AppColors.error : AppColors.success,
              ),
              _buildStatMetric(
                context,
                'Cost Per Guest',
                CurrencyFormatter.format(summary.costPerGuest, currency: cur),
                subtitle: 'Based on ${event.guestCount} guests',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Utilization bar with accessible text
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (summary.utilizationPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: theme.colorScheme.outline.withAlpha(50),
              valueColor: AlwaysStoppedAnimation(
                summary.thresholdState == BudgetThresholdState.overBudget
                    ? AppColors.error
                    : (summary.thresholdState == BudgetThresholdState.approachingLimit
                        ? AppColors.warning
                        : AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.utilizationPercentage.toStringAsFixed(1)}% utilized (${CurrencyFormatter.format(summary.totalPlannedExpenses, currency: cur)} of ${CurrencyFormatter.format(summary.totalBudget, currency: cur)})',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildOptimizationProposals(
    BuildContext context,
    List<BudgetAdjustmentProposal> proposals,
    double overage,
    String cur,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overage > 0
                      ? 'Action Required: Plan Exceeds Budget by ${CurrencyFormatter.format(overage, currency: cur)}'
                      : 'Optimization Recommendations: Approaching Budget Limit',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Planora AI analyzed your allocations and identified smart adjustments in flexible categories without touching your confirmed expenses or essential accessibility needs.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF78350F)),
          ),
          const SizedBox(height: 16),

          ...proposals.map((prop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withAlpha(120)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prop.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prop.rationale,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reduce estimate from \$${prop.currentAmount.toStringAsFixed(0)} to \$${prop.proposedAmount.toStringAsFixed(0)} (Save \$${prop.potentialSavings.toStringAsFixed(0)})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _dismissedProposals.add(prop.id));
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // Apply the proposal to the item
                      final active = ref.read(activeEventProvider).value;
                      if (active == null) return;
                      final target = active.budgetItems.firstWhere((i) => i.id == prop.budgetItemId);
                      final updated = target.copyWith(estimatedAmount: prop.proposedAmount);
                      await ref.read(activeEventProvider.notifier).updateBudgetItem(updated);
                      setState(() => _dismissedProposals.add(prop.id));

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text('✓ Applied optimization: saved \$${prop.potentialSavings.toStringAsFixed(0)}!'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Apply Cut', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryAllocationVisualizer(
    BuildContext context,
    BudgetSummary summary,
    String cur,
  ) {
    final theme = Theme.of(context);

    // Filter categories with active spend
    final activeCategories = summary.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList();

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Allocation Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: activeCategories.map((entry) {
              final pct = summary.categoryPercentages[entry.key] ?? 0.0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 5,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${CurrencyFormatter.format(entry.value, currency: cur)} (${pct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItemTile(BuildContext context, BudgetItem item, String cur) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showEditExpenseDialog(context, item),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            // Category Icon / Pill
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.isConfirmed ? Icons.lock : Icons.edit_note,
                size: 18,
                color: item.isConfirmed ? AppColors.success : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),

            // Item Name & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${item.category.displayName} • Priority ${item.priority == 1 ? "High (Essential)" : (item.priority == 2 ? "Medium" : "Flexible")}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Amount & Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(item.effectiveAmount, currency: cur),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                StatusBadge(
                  label: item.isConfirmed ? 'Confirmed' : 'Estimated',
                  type: item.isConfirmed ? BadgeType.success : BadgeType.neutral,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Delete item button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              tooltip: 'Delete item',
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete Expense Item?',
                  content: 'Are you sure you want to remove "${item.name}" from your budget plan?',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref.read(activeEventProvider.notifier).deleteBudgetItem(item.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context, String eventId) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    BudgetCategory selectedCat = BudgetCategory.venue;
    bool isConfirmed = false;
    int priority = 2;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('Add Expense Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Expense Name *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BudgetCategory>(
                      initialValue: selectedCat,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: BudgetCategory.values.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => selectedCat = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount *', prefixText: '\$ '),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is this confirmed with contract?'),
                      value: isConfirmed,
                      onChanged: (v) => setDlgState(() => isConfirmed = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                    if (name.isEmpty || amt <= 0) return;

                    const uuid = Uuid();
                    final newItem = BudgetItem(
                      id: uuid.v4(),
                      eventId: eventId,
                      category: selectedCat,
                      name: name,
                      estimatedAmount: isConfirmed ? amt : amt,
                      confirmedAmount: isConfirmed ? amt : 0.0,
                      isConfirmed: isConfirmed,
                      priority: priority,
                    );

                    await ref.read(activeEventProvider.notifier).updateBudgetItem(newItem);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Expense'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditExpenseDialog(BuildContext context, BudgetItem item) {
    final nameCtrl = TextEditingController(text: item.name);
    final amountCtrl = TextEditingController(text: item.effectiveAmount.toStringAsFixed(0));
    bool isConfirmed = item.isConfirmed;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: Text('Edit "${item.name}"'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Mark Confirmed (Contract/Deposit Paid)'),
                    subtitle: const Text('Confirmed items are locked from automated cuts'),
                    value: isConfirmed,
                    onChanged: (v) => setDlgState(() => isConfirmed = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final amt = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? item.effectiveAmount;

                    final updated = item.copyWith(
                      name: name.isNotEmpty ? name : item.name,
                      isConfirmed: isConfirmed,
                      confirmedAmount: isConfirmed ? amt : item.confirmedAmount,
                      estimatedAmount: !isConfirmed ? amt : item.estimatedAmount,
                    );

                    await ref.read(activeEventProvider.notifier).updateBudgetItem(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
