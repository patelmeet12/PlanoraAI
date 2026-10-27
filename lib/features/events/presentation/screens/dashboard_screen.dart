import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../budget/domain/models/budget_category.dart';
import '../../../budget/domain/services/budget_optimizer_service.dart';
import '../../../timeline/domain/models/timeline_task.dart';
import '../../../vendors/domain/services/vendor_service.dart';
import '../providers/event_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return EmptyStateView(
            icon: Icons.event_busy,
            title: 'No Active Event Found',
            message: 'Create a new event plan or explore one of the showcase templates to begin.',
            actionLabel: 'Create Event Plan',
            onAction: () => context.go('/wizard'),
          );
        }

        final event = aggregate.event;
        final budgetSummary = BudgetOptimizerService.calculateSummary(
          totalBudget: event.totalBudget,
          guestCount: event.guestCount,
          items: aggregate.budgetItems,
        );

        final daysRemaining = DateFormatter.daysRemaining(event.date);
        final completedTasks = aggregate.tasks.where((t) => t.isCompleted).length;
        final totalTasks = aggregate.tasks.length;
        final taskProgress = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
        final bookingProgress = VendorService.calculateBookingProgress(aggregate.vendors);

        // Compute Overdue & Due Soon tasks
        final now = DateTime.now();
        final overdueTasks = aggregate.tasks.where((t) => t.isOverdue(now)).toList();
        final upcomingTasks = aggregate.tasks
            .where((t) => !t.isCompleted && !t.isOverdue(now))
            .take(3)
            .toList();

        // Determine Next Best Action
        TimelineTask? nextActionTask;
        if (overdueTasks.isNotEmpty) {
          nextActionTask = overdueTasks.first;
        } else {
          final pending = aggregate.tasks.where((t) => !t.isCompleted).toList();
          if (pending.isNotEmpty) {
            // Sort by priority (urgent first), then due date
            pending.sort((a, b) {
              final p = a.priority.index.compareTo(b.priority.index);
              if (p != 0) return p;
              return a.dueDate.compareTo(b.dueDate);
            });
            nextActionTask = pending.first;
          }
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner with Event Countdown
              _buildEventHeaderCard(context, event, daysRemaining),
              const SizedBox(height: 24),

              // Prominent Next Best Action Banner
              if (nextActionTask != null)
                _buildNextBestActionCard(context, ref, nextActionTask, isOverdue: nextActionTask.isOverdue(now)),
              const SizedBox(height: 24),

              // Overview Metrics Grid (Progress, Budget Health, Vendors)
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildBudgetHealthCard(context, event, budgetSummary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildProgressCard(context, completedTasks, totalTasks, taskProgress, bookingProgress),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildBudgetHealthCard(context, event, budgetSummary),
                      const SizedBox(height: 16),
                      _buildProgressCard(context, completedTasks, totalTasks, taskProgress, bookingProgress),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Priority Task Alerts & Quick Navigation
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 850;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: _buildUrgentTasksSection(context, ref, overdueTasks, upcomingTasks),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _buildQuickToolsSection(context, aggregate),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildUrgentTasksSection(context, ref, overdueTasks, upcomingTasks),
                      const SizedBox(height: 16),
                      _buildQuickToolsSection(context, aggregate),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading dashboard: $e')),
    );
  }

  Widget _buildEventHeaderCard(BuildContext context, dynamic event, int daysRemaining) {
    final theme = Theme.of(context);
    final isUrgent = daysRemaining <= 7;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUrgent
              ? [const Color(0xFF7F1D1D), const Color(0xFFB91C1C)]
              : [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? AppColors.error : AppColors.primary).withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '• ${event.city}',
                      style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${DateFormatter.formatFullDate(event.date)} • ${event.guestCount} Expected Guests • ${event.theme}',
                  style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Countdown Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  daysRemaining >= 0 ? '$daysRemaining' : '0',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isUrgent ? AppColors.error : AppColors.primary,
                  ),
                ),
                Text(
                  daysRemaining == 1 ? 'Day Left' : (daysRemaining < 0 ? 'Concluded' : 'Days Left'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? AppColors.error : AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextBestActionCard(
    BuildContext context,
    WidgetRef ref,
    TimelineTask task, {
    required bool isOverdue,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isOverdue ? AppColors.errorContainer : theme.colorScheme.primaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? AppColors.error : theme.colorScheme.primary.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverdue ? AppColors.error : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOverdue ? Icons.priority_high : Icons.flag,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOverdue ? 'CRITICAL OVERDUE ACTION' : 'NEXT RECOMMENDED ACTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isOverdue ? AppColors.error : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: task.priority.displayName,
                      compact: true,
                      type: isOverdue ? BadgeType.error : BadgeType.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${task.description} (Due: ${DateFormatter.formatShortDate(task.dueDate)})',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(activeEventProvider.notifier).toggleTaskCompleted(task.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('✓ Marked "${task.title}" as completed!'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Mark Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? AppColors.error : theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetHealthCard(BuildContext context, dynamic event, BudgetSummary budget) {
    final theme = Theme.of(context);
    final cur = event.currency;

    BadgeType badgeType;
    IconData badgeIcon;
    switch (budget.thresholdState) {
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
      onTap: () => context.go('/budget'),
      semanticLabel: 'View Intelligent Budget Optimizer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget Health', style: theme.textTheme.titleLarge),
              StatusBadge(
                label: budget.thresholdState.label,
                icon: badgeIcon,
                type: badgeType,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Primary numbers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planned Expenses', style: theme.textTheme.bodySmall),
                  Text(
                    CurrencyFormatter.format(budget.totalPlannedExpenses, currency: cur),
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Remaining Balance', style: theme.textTheme.bodySmall),
                  Text(
                    CurrencyFormatter.format(budget.remainingBalance, currency: cur),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: budget.remainingBalance < 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Utilization bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (budget.utilizationPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: theme.colorScheme.outline.withAlpha(50),
              valueColor: AlwaysStoppedAnimation(
                budget.thresholdState == BudgetThresholdState.overBudget
                    ? AppColors.error
                    : (budget.thresholdState == BudgetThresholdState.approachingLimit
                        ? AppColors.warning
                        : AppColors.success),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${budget.utilizationPercentage.toStringAsFixed(1)}% Utilized of ${CurrencyFormatter.format(budget.totalBudget, currency: cur)}',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '~${CurrencyFormatter.format(budget.costPerGuest, currency: cur)} / guest',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    int completedTasks,
    int totalTasks,
    double taskProgress,
    double bookingProgress,
  ) {
    final theme = Theme.of(context);

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Planning Readiness', style: theme.textTheme.titleLarge),
          const SizedBox(height: 20),

          // Tasks Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones Completed', style: theme.textTheme.bodyMedium),
              Text(
                '$completedTasks / $totalTasks (${(taskProgress * 100).round()}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: taskProgress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outline.withAlpha(60),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 18),

          // Vendor Booking Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vendors Booked', style: theme.textTheme.bodyMedium),
              Text(
                '${bookingProgress.round()}% Confirmed',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (bookingProgress / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.outline.withAlpha(60),
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.go('/timeline'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All Milestones'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentTasksSection(
    BuildContext context,
    WidgetRef ref,
    List<TimelineTask> overdue,
    List<TimelineTask> upcoming,
  ) {
    final theme = Theme.of(context);

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Urgent & Upcoming Tasks', style: theme.textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () => context.go('/timeline'),
                child: const Text('Manage Timeline'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (overdue.isEmpty && upcoming.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('All tasks are up to date! 🎉')),
            ),

          // Overdue tasks
          ...overdue.map((t) => _buildTaskRow(context, ref, t, isOverdue: true)),

          // Upcoming tasks
          ...upcoming.map((t) => _buildTaskRow(context, ref, t, isOverdue: false)),
        ],
      ),
    );
  }

  Widget _buildTaskRow(
    BuildContext context,
    WidgetRef ref,
    TimelineTask task, {
    required bool isOverdue,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (_) {
              ref.read(activeEventProvider.notifier).toggleTaskCompleted(task.id);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  '${task.category} • Due ${DateFormatter.formatShortDate(task.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? AppColors.error : theme.colorScheme.onSurface.withAlpha(160),
                    fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: task.priority.displayName,
            type: isOverdue ? BadgeType.error : BadgeType.neutral,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToolsSection(BuildContext context, dynamic aggregate) {
    final theme = Theme.of(context);

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Copilot Suite', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildToolShortcut(
            context,
            icon: Icons.smart_toy,
            title: 'AI Planning Copilot',
            subtitle: 'Ask changes naturally or test cuts',
            route: '/copilot',
            color: AppColors.primary,
          ),
          const Divider(height: 16),
          _buildToolShortcut(
            context,
            icon: Icons.compare_arrows,
            title: 'Change Impact Analyzer',
            subtitle: 'Before-and-after change review',
            route: '/impact',
            color: AppColors.secondary,
          ),
          const Divider(height: 16),
          _buildToolShortcut(
            context,
            icon: Icons.storefront,
            title: 'Vendor Organizer (${aggregate.vendors.length})',
            subtitle: 'Side-by-side comparison & quotes',
            route: '/vendors',
            color: AppColors.tertiary,
          ),
          const Divider(height: 16),
          _buildToolShortcut(
            context,
            icon: Icons.schedule,
            title: 'Event-Day Run Sheet (${aggregate.runSheet.length})',
            subtitle: 'Minute-by-minute schedule & checks',
            route: '/run-sheet',
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildToolShortcut(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
