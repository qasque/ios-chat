import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/config/app_config.dart';
import 'package:mobile/src/controllers/agent_workspace_controller.dart';
import 'package:mobile/src/services/local_settings_service.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class OperatorLoginScreen extends StatefulWidget {
  final AppConfig config;
  final AgentWorkspaceController agent;
  final LocalSettingsService settings;
  final Future<void> Function()? onWorkspaceSessionChanged;

  const OperatorLoginScreen({
    super.key,
    required this.config,
    required this.agent,
    required this.settings,
    this.onWorkspaceSessionChanged,
  });

  @override
  State<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends State<OperatorLoginScreen> {
  late final TextEditingController _bridgeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.agent.bridgeBaseUrl.trim().isNotEmpty
        ? widget.agent.bridgeBaseUrl
        : widget.config.bridgeBaseUrl;
    _bridgeCtrl = TextEditingController(text: initial);
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _bridgeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final url = _bridgeCtrl.text.trim();
    if (url.isEmpty) {
      showKosmosSnackBar(
        context,
        message: "Укажите URL моста",
        isError: true,
      );
      return;
    }
    await widget.settings.writeString(
      LocalSettingsService.operatorBridgeBaseUrlKey,
      url,
    );
    await widget.agent.loginWithBridge(
      bridgeBaseUrl: url,
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );
    if (widget.agent.hasSession) {
      await widget.onWorkspaceSessionChanged?.call();
    }
    _passwordCtrl.clear();
    if (!mounted) return;
    showKosmosSnackBar(
      context,
      message: widget.agent.hasSession ? "Вход выполнен" : "Не удалось войти",
      isSuccess: widget.agent.hasSession,
      isError: !widget.agent.hasSession,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.agent,
      builder: (context, _) {
        final agent = widget.agent;
        return Scaffold(
          body: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Text(
                  "Kosmos",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  "Вход оператора через мост",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _bridgeCtrl,
                  decoration: const InputDecoration(
                    labelText: "URL моста",
                    prefixIcon: Icon(Icons.link_rounded, size: 20),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    labelText: "Пароль",
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                  ),
                  obscureText: true,
                  autocorrect: false,
                  onSubmitted: (_) {
                    if (!agent.loadingProfile) _submit();
                  },
                ),
                if (agent.error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.red.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      agent.error!,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                KosmosButton(
                  label: "Войти",
                  icon: Icons.login_rounded,
                  loading: agent.loadingProfile,
                  onPressed: agent.loadingProfile
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _submit();
                        },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Секреты Chatwoot не сохраняются на устройстве — только сессия моста.",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary.withValues(alpha: 0.95),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
