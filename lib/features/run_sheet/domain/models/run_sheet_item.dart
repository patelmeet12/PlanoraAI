class RunSheetItem {
  final String id;
  final String eventId;
  final String startTime; // "08:00"
  final String endTime;   // "09:30"
  final String title;
  final String description;
  final String category; // Setup, Vendor, Program, Dining, Teardown
  final String? location;
  final String? leadPerson;
  final List<String> prerequisites;
  final bool isCompleted;

  const RunSheetItem({
    required this.id,
    required this.eventId,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.description,
    required this.category,
    this.location,
    this.leadPerson,
    this.prerequisites = const [],
    this.isCompleted = false,
  });

  RunSheetItem copyWith({
    String? id,
    String? eventId,
    String? startTime,
    String? endTime,
    String? title,
    String? description,
    String? category,
    String? location,
    String? leadPerson,
    List<String>? prerequisites,
    bool? isCompleted,
  }) {
    return RunSheetItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      leadPerson: leadPerson ?? this.leadPerson,
      prerequisites: prerequisites ?? this.prerequisites,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'startTime': startTime,
      'endTime': endTime,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'leadPerson': leadPerson,
      'prerequisites': prerequisites,
      'isCompleted': isCompleted,
    };
  }

  factory RunSheetItem.fromJson(Map<String, dynamic> json) {
    return RunSheetItem(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '09:00',
      endTime: json['endTime'] as String? ?? '10:00',
      title: json['title'] as String? ?? 'Activity',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Program',
      location: json['location'] as String?,
      leadPerson: json['leadPerson'] as String?,
      prerequisites: (json['prerequisites'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
