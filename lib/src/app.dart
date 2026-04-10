import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/src/config/app_config.dart';
import 'package:mobile/src/controllers/agent_workspace_controller.dart';
import 'package:mobile/src/controllers/chat_controller.dart';
import 'package:mobile/src/models/app_user.dart';
import 'package:mobile/src/screens/chat_screen.dart';
import 'package:mobile/src/screens/dialogs_screen.dart';
import 'package:mobile/src/screens/profile_screen.dart';
import 'package:mobile/src/services/auth_service.dart';
import 'package:mobile/src/services/chat_service.dart';
import 'package:mobile/src/services/deep_link_service.dart';
import 'package:mobile/src/services/local_settings_service.dart';
import 'package:mobile/src/services/push_service.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/chatwoot_drawer.dart';

class SupportApp extends StatefulWidget {
  final AppConfig config;
  const SupportApp({super.key, required this.config});

  @override
  State<SupportApp> createState() => _SupportAppState();
}

class _SupportAppState extends State<SupportApp> with TickerProviderStateMixin {
  final _settings = LocalSettingsService();
  late final AuthService _auth = AuthService(_settings);
  late final AgentWorkspaceController _agent =
      AgentWorkspaceController(_settings);
  late final ChatController _chatController = ChatController(ChatService());
  final _push = PushService();
  final _links = DeepLinkService();

  StreamSubscription<Uri>? _linkSub;
  AppUser? _user;
  int _tabIndex = 0;
  String _inboxIdentifier = "";
  String _chatwootBaseUrl = "";
  bool _isOnline = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);
    _fadeCtrl.value = 1.0;
    _bootstrap();
    _linkSub = _links.subscribe((uri) {
      if (uri.path.contains("chat")) _switchTab(1);
    });
  }

  void _switchTab(int index) {
    if (index == _tabIndex) return;
    HapticFeedback.selectionClick();
    _fadeCtrl.reverse().then((_) {
      setState(() => _tabIndex = index);
      _fadeCtrl.forward();
    });
  }

  Future<void> _bootstrap() async {
    await _agent.restoreFromStorage(widget.config.bridgeBaseUrl);
    final user = await _auth.currentUser();
    await _push.initialize();
    final savedInbox = await _settings.readString(
      LocalSettingsService.chatwootInboxIdentifierKey,
    );
    final savedBase = await _settings.readString(
      LocalSettingsService.chatwootBaseUrlKey,
    );
    setState(() {
      _user = user;
      _inboxIdentifier = (savedInbox ?? widget.config.inboxIdentifier).trim();
      _chatwootBaseUrl = (savedBase ?? widget.config.chatwootBaseUrl).trim();
    });
    if (!_agent.hasSession) await _connectIfReady();
  }

  Future<void> _connectIfReady() async {
    if (_agent.hasSession) return;
    if (_user == null ||
        _inboxIdentifier.isEmpty ||
        _chatwootBaseUrl.isEmpty) {
      return;
    }
    await _chatController.connect(
      baseUrl: _chatwootBaseUrl,
      inboxIdentifier: _inboxIdentifier,
      user: _user!,
    );
  }

  Future<void> _saveProfile(String id, String email, String name) async {
    await _auth.signIn(id: id, email: email, name: name);
    setState(() => _user = AppUser(id: id, email: email, name: name));
    if (!_agent.hasSession) await _connectIfReady();
  }

  String get _profileChatwootBase {
    if (_chatwootBaseUrl.isNotEmpty) return _chatwootBaseUrl;
    return widget.config.chatwootBaseUrl;
  }

  Future<void> _syncChatMode() async {
    if (_agent.hasSession) {
      await _chatController.disconnect();
    } else {
      await _connectIfReady();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _linkSub?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RepaintBoundary(
        child: DialogsScreen(
          controller: _chatController,
          agent: _agent,
          onOpenChat: () => _switchTab(1),
        ),
      ),
      RepaintBoundary(
        child: ChatScreen(controller: _chatController, agent: _agent),
      ),
      RepaintBoundary(
        child: ProfileScreen(
          user: _user,
          onSignIn: _saveProfile,
          agent: _agent,
          bridgeBaseUrl: widget.config.bridgeBaseUrl,
          defaultChatwootBaseUrl: _profileChatwootBase,
          onWorkspaceSessionChanged: _syncChatMode,
        ),
      ),
    ];

    return MaterialApp(
      title: "Kosmos Support",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
            systemNavigationBarColor: Color(0xD1161B22),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        drawer: ChatwootDrawer(
          selectedTabIndex: _tabIndex,
          agentName: _agent.agentName,
          agentEmail: _agent.agentEmail,
          inboxes: _agent.inboxes,
          onSelectTab: _switchTab,
          onSelectInbox: (inboxId) {
            _agent.setInboxFilter(inboxId);
            _switchTab(0);
          },
        ),
        appBar: AppBar(
          title: const Text("Kosmos"),
          actions: [
            if (_agent.hasSession)
              _StatusToggle(
                isOnline: _isOnline,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _isOnline = v);
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: IndexedStack(index: _tabIndex, children: screens),
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _StatusToggle({required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.green.withValues(alpha: 0.15)
              : AppColors.orange.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOnline
                ? AppColors.green.withValues(alpha: 0.3)
                : AppColors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.green : AppColors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                isOnline ? "Онлайн" : "Отошёл",
                key: ValueKey(isOnline),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.green : AppColors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
