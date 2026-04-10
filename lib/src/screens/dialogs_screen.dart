import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/controllers/agent_workspace_controller.dart';
import 'package:mobile/src/controllers/chat_controller.dart';
import 'package:mobile/src/models/agent_models.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class DialogsScreen extends StatelessWidget {
  final ChatController controller;
  final AgentWorkspaceController agent;
  final VoidCallback onOpenChat;

  const DialogsScreen({
    super.key,
    required this.controller,
    required this.agent,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, agent]),
      builder: (context, _) {
        if (agent.hasSession && agent.selectedAccountId != null) {
          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            edgeOffset: 0,
            displacement: 40,
            onRefresh: () async {
              HapticFeedback.mediumImpact();
              await agent.refreshConversations();
            },
            child: _agentDialogsBody(context),
          );
        }
        return _visitorPlaceholder(context);
      },
    );
  }

  Widget _agentDialogsBody(BuildContext context) {
    final filtered = agent.filteredConversations;
    return Column(
      children: [
        _Header(agent: agent),
        _AssigneeTabs(agent: agent),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: filtered.isEmpty && !agent.loadingList
                ? _EmptyState(
                    key: const ValueKey("empty"),
                    icon: Icons.forum_outlined,
                    title: "Нет диалогов",
                    subtitle: _emptySubtitle(),
                  )
                : _ConversationList(
                    key: ValueKey("list-${agent.assigneeFilter}"),
                    conversations: filtered,
                    agent: agent,
                    onOpenChat: onOpenChat,
                  ),
          ),
        ),
      ],
    );
  }

  String _emptySubtitle() {
    switch (agent.assigneeFilter) {
      case AssigneeFilter.mine:
        return "Нет назначенных вам диалогов";
      case AssigneeFilter.unassigned:
        return "Нет неназначенных диалогов";
      case AssigneeFilter.all:
        return "Диалоги появятся, когда клиенты напишут";
    }
  }

  Widget _visitorPlaceholder(BuildContext context) {
    final state = controller.state;
    final lastMessage = state.messages.isEmpty ? null : state.messages.last;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.accentLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Поддержка",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: state.connected
                                ? AppColors.green
                                : AppColors.textTertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.connected ? "Онлайн" : "Подключение...",
                          style: TextStyle(
                            color: state.connected
                                ? AppColors.green
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onOpenChat();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text("Открыть"),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: _ConversationTile(
            row: AgentConversationRow(
              id: 0,
              inboxId: null,
              inboxName: "Встроенный виджет",
              title: "LK VM test",
              preview: lastMessage?.content?.trim().isNotEmpty == true
                  ? lastMessage!.content!
                  : "Новых сообщений пока нет",
              status: state.connected ? "open" : "",
              unreadCount: state.messages.length,
            ),
            selected: false,
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenChat();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Войдите как оператор, чтобы видеть все диалоги",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ConversationList extends StatefulWidget {
  final List<AgentConversationRow> conversations;
  final AgentWorkspaceController agent;
  final VoidCallback onOpenChat;

  const _ConversationList({
    super.key,
    required this.conversations,
    required this.agent,
    required this.onOpenChat,
  });

  @override
  State<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<_ConversationList> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<AgentConversationRow> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.conversations);
  }

  @override
  void didUpdateWidget(_ConversationList old) {
    super.didUpdateWidget(old);
    _items = List.of(widget.conversations);
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.agent.loadingList;
    return ListView.builder(
      key: _listKey,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _items.length + (loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return const _ListLoader();
        }
        final row = _items[index];
        final selected = widget.agent.selectedConversationId == row.id;
        return _SlideInItem(
          index: index,
          child: _ConversationTile(
            row: row,
            selected: selected,
            onTap: () async {
              HapticFeedback.selectionClick();
              await widget.agent.selectConversation(row.id);
              widget.onOpenChat();
            },
          ),
        );
      },
    );
  }
}

class _SlideInItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _SlideInItem({required this.index, required this.child});

  @override
  State<_SlideInItem> createState() => _SlideInItemState();
}

class _SlideInItemState extends State<_SlideInItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index * 40).clamp(0, 400);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

class _ListLoader extends StatelessWidget {
  const _ListLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: KosmosSpinner(size: 22)),
    );
  }
}

class _Header extends StatelessWidget {
  final AgentWorkspaceController agent;
  const _Header({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text("Диалоги", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "Открыт",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: agent.loadingList
                ? const KosmosSpinner(key: ValueKey("spinner"), size: 18)
                : const SizedBox(key: ValueKey("none"), width: 18, height: 18),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              agent.refreshConversations();
            },
            icon: const Icon(Icons.refresh_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _AssigneeTabs extends StatelessWidget {
  final AgentWorkspaceController agent;
  const _AssigneeTabs({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Tab(
            label: "Мои",
            count: agent.mineCount,
            selected: agent.assigneeFilter == AssigneeFilter.mine,
            onTap: () {
              HapticFeedback.selectionClick();
              agent.setAssigneeFilter(AssigneeFilter.mine);
            },
          ),
          const SizedBox(width: 4),
          _Tab(
            label: "Неназначен",
            count: agent.unassignedCount,
            selected: agent.assigneeFilter == AssigneeFilter.unassigned,
            onTap: () {
              HapticFeedback.selectionClick();
              agent.setAssigneeFilter(AssigneeFilter.unassigned);
            },
          ),
          const SizedBox(width: 4),
          _Tab(
            label: "Все",
            count: agent.allCount,
            selected: agent.assigneeFilter == AssigneeFilter.all,
            onTap: () {
              HapticFeedback.selectionClick();
              agent.setAssigneeFilter(AssigneeFilter.all);
            },
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.accentLight : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontFamily: "sans-serif",
                ),
                child: Text(label),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.accentLight
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final AgentConversationRow row;
  final bool selected;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(row.title);
    final timeLabel = _formatTime(row.lastActivityAt);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: selected
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: "avatar-${row.id}",
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: _avatarColor(row.id),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.inboxName != null && row.inboxName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            children: [
                              Icon(
                                _inboxIcon(row.inboxName),
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  row.inboxName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Text(
                        row.title,
                        style: TextStyle(
                          fontWeight:
                              row.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        row.preview?.trim().isNotEmpty == true
                            ? row.preview!
                            : "Нет сообщений",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatusDot(status: row.status),
                        if (row.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          KosmosBadge(text: "${row.unreadCount}"),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _inboxIcon(String? name) {
    if (name == null) return Icons.inbox_rounded;
    final lower = name.toLowerCase();
    if (lower.contains("telegram")) return Icons.send_rounded;
    if (lower.contains("whatsapp")) return Icons.chat_rounded;
    if (lower.contains("email") || lower.contains("mail")) {
      return Icons.email_outlined;
    }
    if (lower.contains("web") || lower.contains("widget") || lower.contains("lk")) {
      return Icons.language_rounded;
    }
    return Icons.inbox_rounded;
  }

  String _extractInitials(String title) {
    final parts = title.trim().split(RegExp(r"\s+"));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].length >= 2
          ? parts[0].substring(0, 2).toUpperCase()
          : parts[0][0].toUpperCase();
    }
    return "#";
  }

  Color _avatarColor(int id) {
    const palette = [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF43F5E),
      Color(0xFFF97316),
      Color(0xFF14B8A6),
      Color(0xFF06B6D4),
      Color(0xFF3B82F6),
    ];
    return palette[id % palette.length];
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    final epoch = int.tryParse(raw);
    DateTime? dt;
    if (epoch != null) {
      dt = DateTime.fromMillisecondsSinceEpoch(
        epoch > 9999999999 ? epoch : epoch * 1000,
      );
    } else {
      dt = DateTime.tryParse(raw);
    }
    if (dt == null) return "";
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return "сейчас";
    if (diff.inMinutes < 60) return "${diff.inMinutes}м";
    if (diff.inHours < 24) return "${diff.inHours}ч";
    if (diff.inDays < 30) return "${diff.inDays}д";
    return "${diff.inDays ~/ 30}мес";
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status.toLowerCase()) {
      case "open":
        color = AppColors.green;
      case "pending":
        color = AppColors.orange;
      case "snoozed":
        color = AppColors.accentLight;
      default:
        color = AppColors.textTertiary;
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = Tween(begin: 0.9, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(widget.icon,
                      size: 32, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
