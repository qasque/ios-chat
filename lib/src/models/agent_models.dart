class ChatwootAccountOption {
  final int id;
  final String name;
  final String role;

  const ChatwootAccountOption({
    required this.id,
    required this.name,
    required this.role,
  });
}

class AgentInboxOption {
  final int id;
  final String name;
  final String? channelType;

  const AgentInboxOption({
    required this.id,
    required this.name,
    this.channelType,
  });
}

enum AssigneeFilter { mine, unassigned, all }

class AgentConversationRow {
  final int id;
  final int? inboxId;
  final String? inboxName;
  final String title;
  final String? preview;
  final String status;
  final String? lastActivityAt;
  final int unreadCount;
  final bool isAssignedToMe;
  final bool isUnassigned;

  const AgentConversationRow({
    required this.id,
    required this.inboxId,
    this.inboxName,
    required this.title,
    required this.preview,
    required this.status,
    this.lastActivityAt,
    this.unreadCount = 0,
    this.isAssignedToMe = false,
    this.isUnassigned = true,
  });
}

class AgentMessage {
  final int id;
  final String content;
  final String createdAt;
  final bool isOutgoing;

  const AgentMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isOutgoing,
  });
}
