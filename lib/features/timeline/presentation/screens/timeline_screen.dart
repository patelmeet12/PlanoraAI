import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/models/timeline_task.dart';
import '../../domain/services/timeline_generator_service.dart';

enum TaskFilter {
  all,
  pending,
  overdue,
  blocked,
  completed;

  String get displayName {
    switch (this) {
      case TaskFilter.all:
        return 'All Tasks';
      case TaskFilter.pending:
        return 'Pending';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.blocked:
        return 'Blocked';
      case TaskFilter.completed:
        return 'Completed';
    }
  }
}

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  TaskFilter _selectedFilter = TaskFilter.all;

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final now = DateTime.now();

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.event_note_outlined,
            title: 'No Event Active',
            message: 'Create an event to view and manage its timeline.',
          );
        }

        final tasks = aggregate.tasks;
        final daysRemaining = DateFormatter.daysRemaining(aggregate.event.date);

        final filteredTasks = tasks.where((t) {
          switch (_selectedFilter) {
            case TaskFilter.all:
              return true;
            case TaskFilter.pending:
              return !t.isCompleted;
            case TaskFilter.overdue:
              return t.isOverdue(now);
            case TaskFilter.blocked:
              return t.isBlocked(tasks) && !t.isCompleted;
            case TaskFilter.completed:
              return t.isCompleted;
          }
        }).toList();

        // Sort: overdue first, then priority, then due date
        filteredTasks.sort((a, b) {
          final aOver = a.isOverdue(now) ? 0 : 1;
          final bOver = b.isOverdue(now) ? 0 : 1;
          if (aOver != bOver) return aOver.compareTo(bOver);

          final pComp = a.priority.index.compareTo(b.priority.index);
          if (pComp != 0) return pComp;

          return a.dueDate.compareTo(b.dueDate);
        });

        final overdueCount = tasks.where((t) => t.isOverdue(now)).length;
        final blockedCount = tasks.where((t) => t.isBlocked(tasks) && !t.isCompleted).length;

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
                      Text('Adaptive Event Timeline', style: theme.textTheme.headlineMedium),
                      Text(
                        'Deadline-aware milestones adapted to $daysRemaining days remaining',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTaskDialog(context, aggregate.event.id, tasks),
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Add Milestone Task'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sprint Urgency Notice (if <= 7 days)
              if (daysRemaining <= 7)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY SPRINT MODE ACTIVATED',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 13),
                            ),
                            Text(
                              'Only $daysRemaining days until event day. Milestones are prioritized for immediate day-of readiness.',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Filter Chips Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskFilter.values.map((f) {
                  final isSel = _selectedFilter == f;
                  String count = '';
                  if (f == TaskFilter.overdue && overdueCount > 0) count = ' ($overdueCount)';
                  if (f == TaskFilter.blocked && blockedCount > 0) count = ' ($blockedCount)';

                  return FilterChip(
                    label: Text('${f.displayName}$count'),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = f);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Tasks List
              if (filteredTasks.isEmpty)
                const EmptyStateView(
                  icon: Icons.checklist,
                  title: 'No Tasks Match Filter',
                  message: 'Try switching filters or add a custom task milestone.',
                )
              else
                ...filteredTasks.map((t) => _buildTaskCard(context, t, tasks, now)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading timeline: $e')),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TimelineTask task,
    List<TimelineTask> allTasks,
    DateTime now,
  ) {
    final theme = Theme.of(context);
    final isOver = task.isOverdue(now);
    final isBlocked = task.isBlocked(allTasks);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AccessibleCard(
        borderColor: isOver ? AppColors.error.withAlpha(140) : null,
        backgroundColor: isOver ? AppColors.errorContainer.withAlpha(40) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) async {
                await ref.read(activeEventProvider.notifier).toggleTaskCompleted(task.id);
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: task.priority.displayName,
                        type: isOver ? BadgeType.error : BadgeType.neutral,
                        compact: true,
                      ),
                      if (isBlocked) ...[
                        const SizedBox(width: 6),
                        const StatusBadge(
                          label: 'Blocked',
                          icon: Icons.lock_clock,
                          type: BadgeType.warning,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 12,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: isOver ? AppColors.error : theme.colorScheme.onSurface.withAlpha(160),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatMediumDate(task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: isOver ? AppColors.error : null,
                              fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Category: ${task.category}',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      if (task.owner != null && task.owner!.isNotEmpty)
                        Text(
                          'Owner: ${task.owner}',
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        ),
                    ],
                  ),

                  // Dependencies notice
                  if (task.dependencies.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Prerequisites: ${task.dependencies.length} tasks required before kickoff',
                        style: TextStyle(
                          fontSize: 11,
                          color: isBlocked ? AppColors.warning : theme.colorScheme.onSurface.withAlpha(160),
                          fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete Milestone Task?',
                  content: 'Are you sure you want to remove "${task.title}"?',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirm == true) {
                  await ref.read(activeEventProvider.notifier).deleteTask(task.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    String eventId,
    List<TimelineTask> allTasks,
  ) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    TaskPriority priority = TaskPriority.medium;
    String category = 'General';
    final List<String> selectedDeps = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              title: const Text('Add Milestone Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Task Title *'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Due: ${DateFormatter.formatMediumDate(dueDate)}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) setDlgState(() => dueDate = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskPriority>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.values.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p.displayName));
                      }).toList(),
                      onChanged: (v) => setDlgState(() => priority = v!),
                    ),
                    const SizedBox(height: 12),
                    const Text('Prerequisite Dependencies (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ...allTasks.take(5).map((t) {
                      final isDep = selectedDeps.contains(t.id);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.title, style: const TextStyle(fontSize: 12)),
                        value: isDep,
                        onChanged: (val) {
                          setDlgState(() {
                            if (val == true) {
                              selectedDeps.add(t.id);
                            } else {
                              selectedDeps.remove(t.id);
                            }
                          });
                        },
                      );
                    }),
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
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;

                    const uuid = Uuid();
                    final newId = uuid.v4();

                    // Circular dependency validation
                    if (TimelineGeneratorService.hasCircularDependency(
                      taskId: newId,
                      candidateDependencies: selectedDeps,
                      allTasks: allTasks,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot add task: circular dependency detected!'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final newTask = TimelineTask(
                      id: newId,
                      eventId: eventId,
                      title: title,
                      description: descCtrl.text.trim(),
                      dueDate: dueDate,
                      priority: priority,
                      category: category,
                      dependencies: selectedDeps,
                    );

                    await ref.read(activeEventProvider.notifier).saveTask(newTask);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Milestone'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
