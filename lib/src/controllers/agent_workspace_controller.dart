import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/src/models/agent_models.dart';
import 'package:mobile/src/services/chatwoot_agent_api.dart';
import 'package:mobile/src/services/local_settings_service.dart';

class AgentWorkspaceController extends ChangeNotifier {
  final LocalSettingsService _settings;

  AgentWorkspaceController(this._settings);

  String _bridgeBaseUrl = "";
  String? _sessionJwt;
  int? _agentId;
  List<ChatwootAccountOption> accounts = [];
  int? _accountId;
  List<AgentInboxOption> inboxes = [];
  int? _inboxFilterId;
  AssigneeFilter _assigneeFilter = AssigneeFilter.mine;
  List<AgentConversationRow> conversations = [];
  int? _conversationId;
  List<AgentMessage> messages = [];
  String? error;
  bool loadingProfile = false;
  bool loadingList = false;
  bool loadingMessages = false;
  String? agentName;
  String? agentEmail;

  bool get hasSession =>
      _sessionJwt != null &&
      _sessionJwt!.trim().isNotEmpty &&
      _bridgeBaseUrl.trim().isNotEmpty;

  String get bridgeBaseUrl => _bridgeBaseUrl;

  int? get selectedAccountId => _accountId;
  int? get selectedConversationId => _conversationId;
  int? get inboxFilterId => _inboxFilterId;
  AssigneeFilter get assigneeFilter => _assigneeFilter;

  int get mineCount =>
      conversations.where((c) => c.isAssignedToMe).length;
  int get unassignedCount =>
      conversations.where((c) => c.isUnassigned).length;
  int get allCount => conversations.length;

  ChatwootAgentApi? get _api => hasSession
      ? ChatwootAgentApi(
          baseUrl: _bridgeBaseUrl,
          bridgeSessionJwt: _sessionJwt!,
        )
      : null;

  Future<void> restoreFromStorage(String defaultBridgeBaseUrl) async {
    await _settings.clearLegacyChatwootPatIfAny();
    _bridgeBaseUrl = trimChatwootBase(defaultBridgeBaseUrl);
    _sessionJwt = await _settings.readMobileBridgeSession();
    final savedAcc = await _settings.readString(
      LocalSettingsService.selectedAgentAccountIdKey,
    );
    _accountId = int.tryParse(savedAcc ?? "");
    final savedInbox = await _settings.readString(
      LocalSettingsService.selectedInboxFilterIdKey,
    );
    if (savedInbox == null || savedInbox.isEmpty || savedInbox == "0") {
      _inboxFilterId = null;
    } else {
      _inboxFilterId = int.tryParse(savedInbox);
    }
    notifyListeners();
    if (hasSession) {
      await refreshProfile(loadInboxesAndConversations: true);
    }
  }

  Future<void> loginWithBridge({
    required String bridgeBaseUrl,
    required String email,
    required String password,
  }) async {
    loadingProfile = true;
    error = null;
    notifyListeners();
    try {
      final b = trimChatwootBase(bridgeBaseUrl);
      final res = await http.post(
        Uri.parse("$b/mobile/v1/auth/login"),
        headers: const {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email.trim(),
          "password": password,
        }),
      );
      final decoded =
          res.body.isNotEmpty ? jsonDecode(res.body) : null;
      if (res.statusCode != 200) {
        String msg = "Ошибка входа (${res.statusCode})";
        if (decoded is Map) {
          final hint = decoded["hint"]?.toString();
          final det = decoded["details"];
          final err = decoded["error"]?.toString();
          final m = decoded["message"]?.toString();
          if (m != null && m.isNotEmpty) {
            msg = m;
          } else if (err != null && err.isNotEmpty) {
            msg = err;
          }
          if (det != null) {
            msg = "$msg: ${det is String ? det : jsonEncode(det)}";
          }
          if (hint != null && hint.isNotEmpty) {
            msg = "$msg. $hint";
          }
        }
        throw ChatwootAgentException(msg, statusCode: res.statusCode);
      }
      if (decoded is! Map) {
        throw ChatwootAgentException("Некорректный ответ моста");
      }
      final token = decoded["accessToken"]?.toString();
      if (token == null || token.isEmpty) {
        throw ChatwootAgentException("Мост не вернул accessToken");
      }
      _bridgeBaseUrl = b;
      _sessionJwt = token;
      await _settings.writeMobileBridgeSession(token);
      notifyListeners();
      await refreshProfile(loadInboxesAndConversations: true);
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signOutAgent() async {
    final jwt = _sessionJwt;
    final base = _bridgeBaseUrl;
    if (jwt != null && jwt.isNotEmpty && base.isNotEmpty) {
      try {
        await http.post(
          Uri.parse("${trimChatwootBase(base)}/mobile/v1/auth/logout"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $jwt",
          },
        );
      } catch (_) {}
    }
    await _settings.deleteMobileBridgeSession();
    _sessionJwt = null;
    accounts = [];
    _accountId = null;
    inboxes = [];
    _inboxFilterId = null;
    conversations = [];
    _conversationId = null;
    messages = [];
    agentName = null;
    agentEmail = null;
    await _settings.writeString(LocalSettingsService.selectedAgentAccountIdKey, "");
    await _settings.writeString(LocalSettingsService.selectedInboxFilterIdKey, "");
    error = null;
    notifyListeners();
  }

  Future<void> refreshProfile({required bool loadInboxesAndConversations}) async {
    final api = _api;
    if (api == null) return;
    loadingProfile = true;
    error = null;
    notifyListeners();
    try {
      final profile = await api.fetchProfile();
      agentName = profile["name"]?.toString();
      agentEmail = profile["email"]?.toString();
      final rawId = profile["id"];
      _agentId = rawId is int ? rawId : int.tryParse("$rawId");
      accounts = _parseAccounts(profile);
      if (accounts.isEmpty) {
        throw ChatwootAgentException(
          "В профиле нет кабинетов (accounts). Проверьте права агента в Chatwoot.",
        );
      }
      if (_accountId == null || !accounts.any((a) => a.id == _accountId)) {
        _accountId = accounts.first.id;
      }
      await _settings.writeString(
        LocalSettingsService.selectedAgentAccountIdKey,
        "$_accountId",
      );
      if (loadInboxesAndConversations) {
        await _reloadInboxesAndConversations();
      }
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> selectAccount(int id) async {
    if (_accountId == id) return;
    _accountId = id;
    _conversationId = null;
    messages = [];
    await _settings.writeString(
      LocalSettingsService.selectedAgentAccountIdKey,
      "$id",
    );
    notifyListeners();
    await _reloadInboxesAndConversations();
  }

  Future<void> setInboxFilter(int? inboxId) async {
    _inboxFilterId = inboxId;
    await _settings.writeString(
      LocalSettingsService.selectedInboxFilterIdKey,
      inboxId == null ? "" : "$inboxId",
    );
    _conversationId = null;
    messages = [];
    notifyListeners();
    await refreshConversations();
  }

  void setAssigneeFilter(AssigneeFilter filter) {
    if (_assigneeFilter == filter) return;
    _assigneeFilter = filter;
    notifyListeners();
  }

  List<AgentConversationRow> get filteredConversations {
    switch (_assigneeFilter) {
      case AssigneeFilter.mine:
        return conversations.where((c) => c.isAssignedToMe).toList();
      case AssigneeFilter.unassigned:
        return conversations.where((c) => c.isUnassigned).toList();
      case AssigneeFilter.all:
        return conversations;
    }
  }

  Future<void> _reloadInboxesAndConversations() async {
    final api = _api;
    final acc = _accountId;
    if (api == null || acc == null) return;
    loadingList = true;
    notifyListeners();
    try {
      inboxes = await api.fetchInboxes(acc);
      _validateInboxFilter();
      await refreshConversations();
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<void> refreshConversations() async {
    final api = _api;
    final acc = _accountId;
    if (api == null || acc == null) return;
    loadingList = true;
    error = null;
    notifyListeners();
    try {
      conversations = await api.fetchConversations(
        acc,
        inboxId: _inboxFilterId,
        knownInboxes: inboxes,
        agentId: _agentId,
      );
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(int id) async {
    _conversationId = id;
    notifyListeners();
    await loadMessages();
  }

  Future<void> loadMessages() async {
    final api = _api;
    final acc = _accountId;
    final conv = _conversationId;
    if (api == null || acc == null || conv == null) return;
    loadingMessages = true;
    error = null;
    notifyListeners();
    try {
      final list = await api.fetchMessages(acc, conv);
      list.sort((a, b) => a.id.compareTo(b.id));
      messages = list;
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendAgentMessage(String content) async {
    final api = _api;
    final acc = _accountId;
    final conv = _conversationId;
    if (api == null || acc == null || conv == null) return;
    error = null;
    notifyListeners();
    try {
      await api.sendOutgoingMessage(acc, conv, content);
      await loadMessages();
      await refreshConversations();
    } on ChatwootAgentException catch (e) {
      error = e.message;
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  void _validateInboxFilter() {
    if (_inboxFilterId == null) return;
    if (!inboxes.any((i) => i.id == _inboxFilterId)) {
      _inboxFilterId = null;
      _settings.writeString(LocalSettingsService.selectedInboxFilterIdKey, "");
    }
  }

  static List<ChatwootAccountOption> _parseAccounts(Map<String, dynamic> profile) {
    final raw = profile["accounts"];
    if (raw is! List) return [];
    final out = <ChatwootAccountOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = m["id"];
      if (id == null) continue;
      final name = m["name"]?.toString() ?? "Account $id";
      final role = m["role"]?.toString() ?? "";
      out.add(
        ChatwootAccountOption(id: int.parse("$id"), name: name, role: role),
      );
    }
    return out;
  }
}
