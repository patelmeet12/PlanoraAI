enum ChatSender {
  user,
  assistant,
  system;
}

enum ProposedActionType {
  none,
  budgetCut,
  guestIncrease,
  guestDecrease,
  dateShift,
  ecoFriendlyUpgrade,
  prioritizeSprint,
  contingencyPlan,
}

class ChangeProposal {
  final ProposedActionType actionType;
  final String description;
  final double? newBudget;
  final int? newGuestCount;
  final DateTime? newDate;
  final Map<String, dynamic>? extraData;

  const ChangeProposal({
    required this.actionType,
    required this.description,
    this.newBudget,
    this.newGuestCount,
    this.newDate,
    this.extraData,
  });

  Map<String, dynamic> toJson() {
    return {
      'actionType': actionType.name,
      'description': description,
      'newBudget': newBudget,
      'newGuestCount': newGuestCount,
      'newDate': newDate?.toIso8601String(),
      'extraData': extraData,
    };
  }

  factory ChangeProposal.fromJson(Map<String, dynamic> json) {
    return ChangeProposal(
      actionType: ProposedActionType.values.firstWhere(
        (a) => a.name == (json['actionType'] as String?),
        orElse: () => ProposedActionType.none,
      ),
      description: json['description'] as String? ?? '',
      newBudget: (json['newBudget'] as num?)?.toDouble(),
      newGuestCount: (json['newGuestCount'] as num?)?.toInt(),
      newDate: json['newDate'] != null ? DateTime.tryParse(json['newDate'] as String) : null,
      extraData: json['extraData'] as Map<String, dynamic>?,
    );
  }
}

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;
  final ChangeProposal? proposal;
  final bool isApplied;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.proposal,
    this.isApplied = false,
  });

  ChatMessage copyWith({
    String? id,
    ChatSender? sender,
    String? text,
    DateTime? timestamp,
    ChangeProposal? proposal,
    bool? isApplied,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      proposal: proposal ?? this.proposal,
      isApplied: isApplied ?? this.isApplied,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'proposal': proposal?.toJson(),
      'isApplied': isApplied,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sender: ChatSender.values.firstWhere(
        (s) => s.name == (json['sender'] as String?),
        orElse: () => ChatSender.system,
      ),
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      proposal: json['proposal'] != null ? ChangeProposal.fromJson(json['proposal']) : null,
      isApplied: json['isApplied'] as bool? ?? false,
    );
  }
}
