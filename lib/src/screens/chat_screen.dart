import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/controllers/agent_workspace_controller.dart';
import 'package:mobile/src/controllers/chat_controller.dart';
import 'package:mobile/src/models/agent_models.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class ChatScreen extends StatefulWidget {
  final ChatController controller;
  final AgentWorkspaceController agent;

  const ChatScreen({
    super.key,
    required this.controller,
    required this.agent,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final _input = TextEditingController();
  bool _isPrivateNote = false;
  bool _showContactPanel = false;
  late final AnimationController _panelCtrl;
  late final Animation<double> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _panelCtrl.dispose();
    _input.dispose();
    super.dispose();
  }

  void _toggleContactPanel() {
    HapticFeedback.lightImpact();
    setState(() => _showContactPanel = !_showContactPanel);
    if (_showContactPanel) {
      _panelCtrl.forward();
    } else {
      _panelCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, widget.agent]),
      builder: (context, _) {
        final agent = widget.agent;
        if (agent.hasSession) {
          if (agent.selectedConversationId == null) {
            return const _EmptyChat(
              icon: Icons.forum_outlined,
              title: "Выберите диалог",
              subtitle: "Нажмите на диалог в списке, чтобы начать",
            );
          }
          return _agentChat(context);
        }
        return _visitorChat(context);
      },
    );
  }

  AgentConversationRow? get _currentConversation {
    final id = widget.agent.selectedConversationId;
    if (id == null) return null;
    for (final c in widget.agent.conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  Widget _agentChat(BuildContext context) {
    final agent = widget.agent;
    final conv = _currentConversation;

    return Column(
      children: [
        _ChatHeader(
          conversation: conv,
          onToggleContactPanel: _toggleContactPanel,
          showContactPanel: _showContactPanel,
          onResolve: () async {
            HapticFeedback.mediumImpact();
          },
        ),
        if (agent.error != null && agent.messages.isEmpty)
          _ErrorBanner(
            message: agent.error!,
            onRetry: () => agent.loadMessages(),
          ),
        if (agent.loadingMessages && agent.messages.isEmpty)
          const KosmosProgressBar(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: agent.messages.isEmpty
                    ? _EmptyChat(
                        icon: agent.loadingMessages
                            ? Icons.hourglass_top_rounded
                            : Icons.chat_outlined,
                        title: agent.loadingMessages
                            ? "Загрузка..."
                            : "Нет сообщений",
                        subtitle: "Сообщения появятся здесь",
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        reverse: true,
                        itemCount: agent.messages.length,
                        itemBuilder: (context, index) {
                          final message = agent
                              .messages[agent.messages.length - 1 - index];
                          return _AnimatedBubble(
                            index: index,
                            child: _MessageBubble(
                              content: message.content,
                              time: message.createdAt,
                              isOutgoing: message.isOutgoing,
                            ),
                          );
                        },
                      ),
              ),
              SizeTransition(
                axis: Axis.horizontal,
                sizeFactor: _panelSlide,
                axisAlignment: -1,
                child: _ContactPanel(conversation: conv),
              ),
            ],
          ),
        ),
        _AgentInputBar(
          controller: _input,
          isPrivateNote: _isPrivateNote,
          enabled: !agent.loadingMessages,
          onToggleNote: () {
            HapticFeedback.selectionClick();
            setState(() => _isPrivateNote = !_isPrivateNote);
          },
          onSend: () async {
            HapticFeedback.lightImpact();
            final value = _input.text;
            _input.clear();
            await agent.sendAgentMessage(value);
            if (mounted) setState(() {});
          },
          onQuickReply: () => _showQuickReplies(context),
        ),
      ],
    );
  }

  void _showQuickReplies(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        final replies = [
          "Здравствуйте! Чем могу помочь?",
          "Одну минуту, уточню информацию.",
          "Спасибо за обращение! Ваш вопрос решён.",
          "Перевожу вас на специалиста.",
          "Пришлите, пожалуйста, скриншот.",
          "Ваш запрос передан в техническую поддержку.",
        ];
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      size: 20, color: AppColors.accentLight),
                  const SizedBox(width: 8),
                  Text(
                    "Быстрые ответы",
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...replies.asMap().entries.map((e) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 200 + e.key * 50),
                  curve: Curves.easeOut,
                  builder: (_, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - val)),
                      child: child,
                    ),
                  ),
                  child: _QuickReplyItem(
                    text: e.value,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _input.text = e.value;
                      Navigator.of(ctx).pop();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _visitorChat(BuildContext context) {
    final state = widget.controller.state;
    return Column(
      children: [
        if (state.error != null)
          _ErrorBanner(
            message: "Ошибка: ${state.error!}",
            onRetry: widget.controller.reload,
          ),
        Expanded(
          child: state.messages.isEmpty
              ? const _EmptyChat(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "Начните разговор",
                  subtitle:
                      "Напишите сообщение, чтобы связаться с поддержкой",
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  reverse: true,
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        state.messages[state.messages.length - 1 - index];
                    return _AnimatedBubble(
                      index: index,
                      child: _MessageBubble(
                        content: message.content ?? "",
                        time: message.createdAt,
                        isOutgoing: message.isMine,
                      ),
                    );
                  },
                ),
        ),
        if (state.typing)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 4),
            child: Row(
              children: [
                _TypingDots(),
                const SizedBox(width: 8),
                const Text(
                  "Оператор печатает",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        _VisitorInputBar(
          controller: _input,
          onSend: () async {
            HapticFeedback.lightImpact();
            final value = _input.text;
            _input.clear();
            await widget.controller.sendMessage(value);
          },
        ),
      ],
    );
  }
}

class _AnimatedBubble extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedBubble({required this.index, required this.child});

  @override
  State<_AnimatedBubble> createState() => _AnimatedBubbleState();
}

class _AnimatedBubbleState extends State<_AnimatedBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.95, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    final delay = (widget.index * 30).clamp(0, 300);
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
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final AgentConversationRow? conversation;
  final VoidCallback onToggleContactPanel;
  final bool showContactPanel;
  final VoidCallback onResolve;

  const _ChatHeader({
    required this.conversation,
    required this.onToggleContactPanel,
    required this.showContactPanel,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    if (conversation == null) return const SizedBox.shrink();
    final conv = conversation!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conv.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (conv.inboxName != null)
                  Text(
                    conv.inboxName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          _HeaderAction(
            icon: Icons.check_circle_outline_rounded,
            tooltip: "Решить",
            color: AppColors.green,
            onTap: onResolve,
          ),
          _HeaderAction(
            icon: Icons.person_add_outlined,
            tooltip: "Назначить",
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _HeaderAction(
            icon: Icons.swap_horiz_rounded,
            tooltip: "Передать",
            onTap: () => HapticFeedback.lightImpact(),
          ),
          _HeaderAction(
            icon: showContactPanel
                ? Icons.info_rounded
                : Icons.info_outline_rounded,
            tooltip: "Контакт",
            color: showContactPanel ? AppColors.accentLight : null,
            onTap: onToggleContactPanel,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: color ?? AppColors.textSecondary,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
    );
  }
}

class _ContactPanel extends StatelessWidget {
  final AgentConversationRow? conversation;
  const _ContactPanel({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(14),
        children: [
          KosmosAvatar(
            initials: _initials(conversation?.title),
            radius: 28,
            showRing: true,
          ),
          const SizedBox(height: 10),
          Text(
            conversation?.title ?? "—",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.inbox_rounded,
            label: "Инбокс",
            value: conversation?.inboxName ?? "—",
          ),
          _InfoRow(
            icon: Icons.tag_rounded,
            label: "ID",
            value: "#${conversation?.id ?? "—"}",
          ),
          _InfoRow(
            icon: Icons.circle,
            label: "Статус",
            value: conversation?.status ?? "—",
            iconColor: _statusColor(conversation?.status),
            iconSize: 10,
          ),
          if (conversation?.lastActivityAt != null)
            _InfoRow(
              icon: Icons.access_time_rounded,
              label: "Активность",
              value: _formatTime(conversation!.lastActivityAt!),
            ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return "?";
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "open":
        return AppColors.green;
      case "pending":
        return AppColors.orange;
      default:
        return AppColors.textTertiary;
    }
  }

  String _formatTime(String raw) {
    final epoch = int.tryParse(raw);
    DateTime? dt;
    if (epoch != null) {
      dt = DateTime.fromMillisecondsSinceEpoch(
        epoch > 9999999999 ? epoch : epoch * 1000,
      );
    } else {
      dt = DateTime.tryParse(raw);
    }
    if (dt == null) return raw;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "сейчас";
    if (diff.inMinutes < 60) return "${diff.inMinutes}м назад";
    if (diff.inHours < 24) return "${diff.inHours}ч назад";
    return "${diff.inDays}д назад";
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final double? iconSize;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: iconSize ?? 14,
              color: iconColor ?? AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textTertiary)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isPrivateNote;
  final bool enabled;
  final VoidCallback onToggleNote;
  final VoidCallback onSend;
  final VoidCallback onQuickReply;

  const _AgentInputBar({
    required this.controller,
    required this.isPrivateNote,
    required this.enabled,
    required this.onToggleNote,
    required this.onSend,
    required this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPrivateNote
                  ? const Color(0xFF2D2200)
                  : AppColors.surface,
              border: Border(
                top: BorderSide(
                  color: isPrivateNote
                      ? AppColors.orange.withValues(alpha: 0.4)
                      : AppColors.border,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                _InputAction(
                  icon: isPrivateNote
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  tooltip: isPrivateNote
                      ? "Приватная заметка"
                      : "Ответ клиенту",
                  color: isPrivateNote ? AppColors.orange : null,
                  onTap: onToggleNote,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: isPrivateNote
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Заметка",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const Spacer(),
                _InputAction(
                  icon: Icons.bolt_rounded,
                  tooltip: "Быстрые ответы",
                  onTap: onQuickReply,
                ),
                _InputAction(
                  icon: Icons.attach_file_rounded,
                  tooltip: "Файл",
                  onTap: () => HapticFeedback.lightImpact(),
                ),
                _InputAction(
                  icon: Icons.emoji_emotions_outlined,
                  tooltip: "Эмодзи",
                  onTap: () => HapticFeedback.lightImpact(),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            color: isPrivateNote
                ? const Color(0xFF2D2200)
                : AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.inputBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isPrivateNote
                            ? AppColors.orange.withValues(alpha: 0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isPrivateNote
                            ? "Приватная заметка для команды..."
                            : "Ответ клиенту...",
                        hintStyle: TextStyle(
                          color: isPrivateNote
                              ? AppColors.orange.withValues(alpha: 0.6)
                              : AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isPrivateNote ? AppColors.orange : AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: enabled ? onSend : null,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isPrivateNote
                                ? Icons.note_add_rounded
                                : Icons.send_rounded,
                            key: ValueKey(isPrivateNote),
                            color: enabled
                                ? Colors.white
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _InputAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      color: color ?? AppColors.textTertiary,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }
}

class _VisitorInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _VisitorInputBar({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => HapticFeedback.lightImpact(),
              icon: const Icon(Icons.attach_file_rounded,
                  color: AppColors.textTertiary, size: 22),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Сообщение...",
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onSend,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReplyItem extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _QuickReplyItem({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.reply_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
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

class _MessageBubble extends StatelessWidget {
  final String content;
  final String time;
  final bool isOutgoing;

  const _MessageBubble({
    required this.content,
    required this.time,
    required this.isOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isOutgoing ? 48 : 0,
          right: isOutgoing ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutgoing
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOutgoing ? 16 : 4),
            bottomRight: Radius.circular(isOutgoing ? 4 : 16),
          ),
          border: Border.all(
            color: isOutgoing
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyChat({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_EmptyChat> createState() => _EmptyChatState();
}

class _EmptyChatState extends State<_EmptyChat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
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
        opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
          ),
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
                    size: 36, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 16),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2D1215),
        border: Border(
            bottom: BorderSide(color: AppColors.red, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.red)),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
            ),
            child: const Text("Обновить"),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * (1 - (2 * t - 1).abs());
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: scale),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
