import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/models/agent_models.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class ChatwootDrawer extends StatelessWidget {
  final int selectedTabIndex;
  final String? agentName;
  final String? agentEmail;
  final List<AgentInboxOption> inboxes;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<int>? onSelectInbox;
  final VoidCallback? onOpenBridge;
  final VoidCallback? onOpenSystemStatus;

  const ChatwootDrawer({
    super.key,
    this.selectedTabIndex = 0,
    this.agentName,
    this.agentEmail,
    this.inboxes = const [],
    required this.onSelectTab,
    this.onSelectInbox,
    this.onOpenBridge,
    this.onOpenSystemStatus,
  });

  void _go(BuildContext context, int index) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    onSelectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(agentName);
    return Drawer(
      child: Column(
        children: [
          _DrawerHeader(
            initials: initials,
            agentName: agentName,
            agentEmail: agentEmail,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerLabel(label: "Мои Входящие"),
                _DrawerTile(
                  icon: Icons.forum_rounded,
                  title: "Диалоги",
                  selected: selectedTabIndex == 0,
                  onTap: () => _go(context, 0),
                ),
                _SubSection(
                  children: [
                    _SubItem(label: "Диалоги", onTap: () => _go(context, 0)),
                    _SubItem(label: "Упоминания", onTap: () => _go(context, 0)),
                    _SubItem(label: "Неотвеченные", onTap: () => _go(context, 0)),
                    _SubItem(label: "Быстрые ответы", onTap: () => _go(context, 0)),
                    _SubItem(label: "Задачи", onTap: () => _go(context, 0)),
                  ],
                ),
                const SizedBox(height: 4),
                _DrawerTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: "Чат",
                  selected: selectedTabIndex == 1,
                  onTap: () => _go(context, 1),
                ),
                const SizedBox(height: 4),
                _DrawerTile(
                  icon: Icons.hub_outlined,
                  title: "Источники",
                  onTap: () => _go(context, 0),
                ),
                if (inboxes.isNotEmpty)
                  _SubSection(
                    children: inboxes.map((inbox) {
                      return _SubItem(
                        label: inbox.name,
                        icon: _inboxIcon(inbox.name),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                          onSelectInbox?.call(inbox.id);
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 4),
                _DrawerTile(
                  icon: Icons.link_rounded,
                  title: "Мост",
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onOpenBridge?.call();
                  },
                ),
                _DrawerTile(
                  icon: Icons.monitor_heart_outlined,
                  title: "Статус моста",
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                    onOpenSystemStatus?.call();
                  },
                ),
                _DrawerTile(
                  icon: Icons.people_outline_rounded,
                  title: "Контакты",
                  onTap: () => _go(context, 0),
                ),
                _DrawerTile(
                  icon: Icons.bar_chart_rounded,
                  title: "Отчёты",
                  onTap: () => _go(context, 0),
                ),
                _DrawerTile(
                  icon: Icons.campaign_outlined,
                  title: "Кампании",
                  onTap: () => _go(context, 0),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: 4,
                bottom: MediaQuery.of(context).padding.bottom + 8,
              ),
              child: _DrawerTile(
                icon: Icons.settings_outlined,
                title: "Настройки",
                selected: selectedTabIndex == 2,
                onTap: () => _go(context, 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _inboxIcon(String name) {
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

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return "K";
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _DrawerHeader extends StatelessWidget {
  final String initials;
  final String? agentName;
  final String? agentEmail;

  const _DrawerHeader({
    required this.initials,
    this.agentName,
    this.agentEmail,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(-16 * (1 - v), 0),
          child: c,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 20,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            KosmosAvatar(initials: initials, radius: 20, showRing: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agentName ?? "Kosmos Support",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (agentEmail != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      agentEmail!,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLabel extends StatelessWidget {
  final String label;
  const _DrawerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SubSection extends StatelessWidget {
  final List<Widget> children;
  const _SubSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.border, width: 2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _SubItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _SubItem({required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected
                        ? AppColors.accentLight
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
