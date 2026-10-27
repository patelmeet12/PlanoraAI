enum TaskPriority {
  urgent,
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  static TaskPriority fromString(String val) {
    return TaskPriority.values.firstWhere(
      (p) => p.name.toLowerCase() == val.toLowerCase(),
      orElse: () => TaskPriority.medium,
    );
  }
}

class TimelineTask {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime? completedAt;
  final String category;
  final List<String> dependencies; // Task IDs that must be completed first
  final String? owner;
  final String? notes;

  const TimelineTask({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    this.completedAt,
    this.category = 'General',
    this.dependencies = const [],
    this.owner,
    this.notes,
  });

  bool isOverdue(DateTime now) {
    if (isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }

  bool isBlocked(List<TimelineTask> allTasks) {
    if (dependencies.isEmpty) return false;
    for (final depId in dependencies) {
      final depTask = allTasks.cast<TimelineTask?>().firstWhere(
            (t) => t?.id == depId,
            orElse: () => null,
          );
      if (depTask != null && !depTask.isCompleted) {
        return true;
      }
    }
    return false;
  }

  TimelineTask copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? completedAt,
    String? category,
    List<String>? dependencies,
    String? owner,
    String? notes,
  }) {
    return TimelineTask(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      category: category ?? this.category,
      dependencies: dependencies ?? this.dependencies,
      owner: owner ?? this.owner,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'category': category,
      'dependencies': dependencies,
      'owner': owner,
      'notes': notes,
    };
  }

  factory TimelineTask.fromJson(Map<String, dynamic> json) {
    return TimelineTask(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Task',
      description: json['description'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      priority: TaskPriority.fromString(json['priority'] as String? ?? 'medium'),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      category: json['category'] as String? ?? 'General',
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      owner: json['owner'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
