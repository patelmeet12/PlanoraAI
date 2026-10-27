import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/timeline/domain/models/timeline_task.dart';
import 'package:planora_ai/features/timeline/domain/services/timeline_generator_service.dart';

void main() {
  group('TimelineGeneratorService Tests', () {
    test('Generates urgent compressed sprint when event is 5 days away', () {
      final now = DateTime(2026, 6, 1);
      final eventDate = DateTime(2026, 6, 6); // 5 days away

      final tasks = TimelineGeneratorService.generateAdaptiveTimeline(
        eventId: 'test_event',
        category: EventCategory.wedding,
        eventDate: eventDate,
        currentDate: now,
      );

      expect(tasks.isNotEmpty, true);
      // All due dates should be between now and eventDate
      for (final t in tasks) {
        expect(t.dueDate.isBefore(now), false);
        expect(t.dueDate.isAfter(eventDate), false);
        // In urgent sprint, tasks should be tagged urgent or high
        expect(
          t.priority == TaskPriority.urgent || t.priority == TaskPriority.high,
          true,
        );
      }
    });

    test('Generates comprehensive timeline when event is 6+ months away', () {
      final now = DateTime(2026, 1, 1);
      final eventDate = DateTime(2026, 8, 1); // 7 months away

      final tasks = TimelineGeneratorService.generateAdaptiveTimeline(
        eventId: 'test_event',
        category: EventCategory.wedding,
        eventDate: eventDate,
        currentDate: now,
      );

      expect(tasks.length >= 6, true);
    });

    test('Detects overdue tasks accurately relative to current date', () {
      final now = DateTime(2026, 6, 10);
      final pastTask = TimelineTask(
        id: 't_past',
        eventId: 'e1',
        title: 'Book Photographer',
        description: 'Overdue task',
        dueDate: DateTime(2026, 6, 5),
        isCompleted: false,
      );

      final futureTask = TimelineTask(
        id: 't_future',
        eventId: 'e1',
        title: 'Final Rehearsal',
        description: 'Upcoming task',
        dueDate: DateTime(2026, 6, 20),
        isCompleted: false,
      );

      final completedPastTask = pastTask.copyWith(isCompleted: true);

      expect(pastTask.isOverdue(now), true);
      expect(futureTask.isOverdue(now), false);
      expect(completedPastTask.isOverdue(now), false);
    });

    test('Accurately identifies blocked tasks when prerequisite is incomplete', () {
      final task1 = TimelineTask(
        id: 'task_venue',
        eventId: 'e1',
        title: 'Lock Venue',
        description: 'Prerequisite',
        dueDate: DateTime(2026, 7, 1),
        isCompleted: false,
      );

      final task2 = TimelineTask(
        id: 'task_catering',
        eventId: 'e1',
        title: 'Confirm Catering Menu',
        description: 'Requires venue',
        dueDate: DateTime(2026, 7, 10),
        dependencies: ['task_venue'],
        isCompleted: false,
      );

      final allTasks = [task1, task2];

      expect(task2.isBlocked(allTasks), true);

      // Once task1 is completed
      final completedTask1 = task1.copyWith(isCompleted: true);
      final updatedTasks = [completedTask1, task2];

      expect(task2.isBlocked(updatedTasks), false);
    });

    test('Detects circular dependencies in task graphs', () {
      final taskA = TimelineTask(
        id: 'A',
        eventId: 'e1',
        title: 'Task A',
        description: '',
        dueDate: DateTime.now(),
        dependencies: ['B'],
      );

      final taskB = TimelineTask(
        id: 'B',
        eventId: 'e1',
        title: 'Task B',
        description: '',
        dueDate: DateTime.now(),
        dependencies: ['C'],
      );

      final taskC = TimelineTask(
        id: 'C',
        eventId: 'e1',
        title: 'Task C',
        description: '',
        dueDate: DateTime.now(),
        dependencies: [],
      );

      final allTasks = [taskA, taskB, taskC];

      // If we attempt to make C depend on A, that creates cycle A -> B -> C -> A
      final hasCycle = TimelineGeneratorService.hasCircularDependency(
        taskId: 'C',
        candidateDependencies: ['A'],
        allTasks: allTasks,
      );

      expect(hasCycle, true);

      // Self dependency is also a cycle
      expect(
        TimelineGeneratorService.hasCircularDependency(
          taskId: 'X',
          candidateDependencies: ['X'],
          allTasks: allTasks,
        ),
        true,
      );

      // Non-cyclic candidate should return false
      expect(
        TimelineGeneratorService.hasCircularDependency(
          taskId: 'C',
          candidateDependencies: [],
          allTasks: allTasks,
        ),
        false,
      );
    });
  });
}
