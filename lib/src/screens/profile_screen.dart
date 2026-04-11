import 'package:flutter/material.dart';
import 'package:mobile/src/controllers/agent_workspace_controller.dart';
import 'package:mobile/src/models/app_user.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser? user;
  final Future<void> Function(String id, String email, String name) onSignIn;
  final AgentWorkspaceController agent;
  final String bridgeBaseUrl;
  final String defaultChatwootBaseUrl;
  final Future<void> Function()? onWorkspaceSessionChanged;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.onSignIn,
    required this.agent,
    required this.bridgeBaseUrl,
    required this.defaultChatwootBaseUrl,
    this.onWorkspaceSessionChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _idCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _idCtrl = TextEditingController(text: widget.user?.id ?? "");
    _emailCtrl = TextEditingController(text: widget.user?.email ?? "");
    _nameCtrl = TextEditingController(text: widget.user?.name ?? "");
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.agent,
      builder: (context, _) {
        final bottomPad =
            MediaQuery.paddingOf(context).bottom + 24;
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FadeInCard(
                delay: 0,
                child: _buildAgentSection(context),
              ),
              if (widget.agent.hasSession) ...[
                const SizedBox(height: 20),
                _FadeInCard(
                  delay: 100,
                  child: _buildWidgetTestExpansion(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAgentSection(BuildContext context) {
    final agent = widget.agent;
    final hasSession = agent.hasSession;

    return _Card(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.2),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.accentLight,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Оператор",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Сессия активна",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.link_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _displayBridgeUrl().isEmpty
                      ? "URL моста не задан"
                      : _displayBridgeUrl(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: "monospace",
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (hasSession) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                KosmosAvatar(
                  initials: _initials(agent.agentName),
                  radius: 20,
                  showRing: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.agentName ?? "Оператор",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (agent.agentEmail != null)
                        Text(
                          agent.agentEmail!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (agent.accounts.isNotEmpty)
            DropdownButtonFormField<int>(
              value: agent.selectedAccountId,
              decoration: const InputDecoration(
                labelText: "Кабинет",
                prefixIcon: Icon(Icons.business_rounded, size: 20),
              ),
              items: agent.accounts
                  .map(
                    (a) => DropdownMenuItem(
                      value: a.id,
                      child: Text("${a.name} · ${a.role}"),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) widget.agent.selectAccount(v);
              },
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: agent.inboxFilterId,
            decoration: const InputDecoration(
              labelText: "Фильтр инбокса",
              prefixIcon: Icon(Icons.inbox_rounded, size: 20),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text("Все инбоксы"),
              ),
              ...agent.inboxes.map(
                (i) => DropdownMenuItem<int?>(
                  value: i.id,
                  child: Text(i.name),
                ),
              ),
            ],
            onChanged: (v) => widget.agent.setInboxFilter(v),
          ),
          const SizedBox(height: 14),
          KosmosButton(
            label: "Выйти из аккаунта",
            icon: Icons.logout_rounded,
            outlined: true,
            danger: true,
            onPressed: () async {
              await widget.agent.signOutAgent();
              await widget.onWorkspaceSessionChanged?.call();
              if (context.mounted) {
                showKosmosSnackBar(
                  context,
                  message: "Сессия сброшена",
                );
              }
            },
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.lock_rounded,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                "Секреты Chatwoot не попадают на устройство",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWidgetTestExpansion(BuildContext context) {
    return _Card(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: const Text(
              "Тест виджета (опционально)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              widget.defaultChatwootBaseUrl.isNotEmpty
                  ? widget.defaultChatwootBaseUrl
                  : "Не настроен",
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [
              TextField(
                controller: _idCtrl,
                decoration: const InputDecoration(
                  labelText: "User ID",
                  hintText: "user_123",
                  prefixIcon: Icon(Icons.fingerprint_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  hintText: "name@example.com",
                  prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Имя",
                  hintText: "Иван Иванов",
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              KosmosButton(
                label: "Сохранить профиль",
                icon: Icons.save_rounded,
                onPressed: () async {
                  await widget.onSignIn(
                    _idCtrl.text,
                    _emailCtrl.text,
                    _nameCtrl.text,
                  );
                  if (context.mounted) {
                    showKosmosSnackBar(
                      context,
                      message: "Профиль для виджета сохранён",
                      isSuccess: true,
                    );
                  }
                },
              ),
              if (widget.user != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${widget.user!.name} · ${widget.user!.email}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _displayBridgeUrl() {
    final a = widget.agent.bridgeBaseUrl.trim();
    if (a.isNotEmpty) return a;
    return widget.bridgeBaseUrl.trim();
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return "O";
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.length >= 2) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

class _FadeInCard extends StatelessWidget {
  final int delay;
  final Widget child;

  const _FadeInCard({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - v)),
          child: c,
        ),
      ),
      child: child,
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
