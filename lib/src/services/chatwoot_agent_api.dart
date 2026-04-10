import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/src/models/agent_models.dart';

String trimChatwootBase(String value) {
  final t = value.trim();
  if (t.endsWith("/")) {
    return t.substring(0, t.length - 1);
  }
  return t;
}

class ChatwootAgentApi {
  final String baseUrl;
  final String? accessToken;
  final String? bridgeSessionJwt;

  ChatwootAgentApi({
    required this.baseUrl,
    this.accessToken,
    this.bridgeSessionJwt,
  }) {
    final hasPat = accessToken != null && accessToken!.trim().isNotEmpty;
    final hasBridge =
        bridgeSessionJwt != null && bridgeSessionJwt!.trim().isNotEmpty;
    assert(
      hasPat != hasBridge,
      "Нужен либо accessToken (прямой Chatwoot), либо bridgeSessionJwt (мост)",
    );
  }

  bool get _viaBridge =>
      bridgeSessionJwt != null && bridgeSessionJwt!.trim().isNotEmpty;

  Map<String, String> get _headers {
    if (_viaBridge) {
      return {
        "Authorization": "Bearer ${bridgeSessionJwt!.trim()}",
        "Content-Type": "application/json",
      };
    }
    return {
      "api_access_token": accessToken!.trim(),
      "Content-Type": "application/json",
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final b = trimChatwootBase(baseUrl);
    final p = path.startsWith("/") ? path : "/$path";
    if (_viaBridge) {
      return Uri.parse("$b/mobile/v1/cw$p").replace(queryParameters: query);
    }
    return Uri.parse("$b$p").replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final res = await http.get(_uri("/api/v1/profile"), headers: _headers);
    _throwIfBad(res, "profile");
    final decoded = jsonDecode(res.body);
    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      final payload = m["payload"];
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      return m;
    }
    throw ChatwootAgentException("profile: unexpected JSON");
  }

  Future<List<AgentInboxOption>> fetchInboxes(int accountId) async {
    final res = await http.get(
      _uri("/api/v1/accounts/$accountId/inboxes"),
      headers: _headers,
    );
    _throwIfBad(res, "inboxes");
    final decoded = jsonDecode(res.body);
    final raw = _extractList(decoded);
    final out = <AgentInboxOption>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = m["id"];
      if (id == null) continue;
      final name = m["name"]?.toString() ?? "Inbox $id";
      out.add(AgentInboxOption(id: int.parse("$id"), name: name));
    }
    return out;
  }

  Future<List<AgentConversationRow>> fetchConversations(
    int accountId, {
    int? inboxId,
    String assigneeType = "all",
    int page = 1,
    int? agentId,
    List<AgentInboxOption> knownInboxes = const [],
  }) async {
    final q = <String, String>{
      "status": "all",
      "assignee_type": assigneeType,
      "page": "$page",
    };
    if (inboxId != null) {
      q["inbox_id"] = "$inboxId";
    }
    final res = await http.get(
      _uri("/api/v1/accounts/$accountId/conversations", q),
      headers: _headers,
    );
    _throwIfBad(res, "conversations");
    final decoded = jsonDecode(res.body);
    final raw = _extractList(decoded);
    final inboxMap = <int, String>{};
    for (final inbox in knownInboxes) {
      inboxMap[inbox.id] = inbox.name;
    }
    return raw
        .map((item) => _parseConversation(item, inboxMap, agentId))
        .whereType<AgentConversationRow>()
        .toList();
  }

  Future<List<AgentMessage>> fetchMessages(
    int accountId,
    int conversationId,
  ) async {
    final res = await http.get(
      _uri("/api/v1/accounts/$accountId/conversations/$conversationId/messages"),
      headers: _headers,
    );
    _throwIfBad(res, "messages");
    final decoded = jsonDecode(res.body);
    final raw = _extractList(decoded);
    return raw.map(_parseMessage).whereType<AgentMessage>().toList();
  }

  Future<void> sendOutgoingMessage(
    int accountId,
    int conversationId,
    String content,
  ) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final res = await http.post(
      _uri(
        "/api/v1/accounts/$accountId/conversations/$conversationId/messages",
      ),
      headers: _headers,
      body: jsonEncode({
        "content": trimmed,
        "message_type": "outgoing",
        "private": false,
      }),
    );
    _throwIfBad(res, "send message");
  }

  static AgentConversationRow? _parseConversation(
    dynamic item,
    Map<int, String> inboxMap,
    int? currentAgentId,
  ) {
    if (item is! Map) return null;
    final m = Map<String, dynamic>.from(item);
    final id = m["id"];
    if (id == null) return null;
    final meta = m["meta"];
    Map<String, dynamic>? metaMap;
    if (meta is Map) {
      metaMap = Map<String, dynamic>.from(meta);
    }
    final sender = metaMap?["sender"];
    String title = "Диалог $id";
    if (sender is Map) {
      final sm = Map<String, dynamic>.from(sender);
      final n = sm["name"]?.toString();
      final em = sm["email"]?.toString();
      if (n != null && n.isNotEmpty) {
        title = n;
      } else if (em != null && em.isNotEmpty) {
        title = em;
      }
    }
    String? preview;
    final last = m["last_non_activity_message"] ?? m["last_message"];
    if (last is Map) {
      final lm = Map<String, dynamic>.from(last);
      preview = lm["content"]?.toString();
    }
    final inboxRaw = m["inbox_id"];
    final inboxId = inboxRaw == null ? null : int.tryParse("$inboxRaw");
    final inboxName = inboxId != null ? inboxMap[inboxId] : null;

    final lastActivity = m["last_activity_at"]?.toString();

    final unread = m["unread_count"];
    final unreadCount = unread is int ? unread : int.tryParse("$unread") ?? 0;

    final assignee = m["meta"]?["assignee"];
    bool isAssignedToMe = false;
    bool isUnassigned = true;
    if (assignee is Map) {
      isUnassigned = false;
      final assigneeId = assignee["id"];
      if (currentAgentId != null && assigneeId != null) {
        isAssignedToMe = int.tryParse("$assigneeId") == currentAgentId;
      }
    }

    return AgentConversationRow(
      id: int.parse("$id"),
      inboxId: inboxId,
      inboxName: inboxName,
      title: title,
      preview: preview,
      status: m["status"]?.toString() ?? "",
      lastActivityAt: lastActivity,
      unreadCount: unreadCount,
      isAssignedToMe: isAssignedToMe,
      isUnassigned: isUnassigned,
    );
  }

  static AgentMessage? _parseMessage(dynamic item) {
    if (item is! Map) return null;
    final m = Map<String, dynamic>.from(item);
    final id = m["id"];
    if (id == null) return null;
    final type = m["message_type"];
    final outgoing =
        type == "outgoing" ||
        type == 1 ||
        type == "1" ||
        "$type" == "1";
    final content = m["content"]?.toString() ?? "";
    final created = m["created_at"]?.toString() ?? "";
    return AgentMessage(
      id: int.parse("$id"),
      content: content,
      createdAt: created,
      isOutgoing: outgoing,
    );
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final payload = decoded["payload"];
      if (payload is List) return payload;
      final data = decoded["data"];
      if (data is List) return data;
    }
    return [];
  }

  static void _throwIfBad(http.Response res, String op) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    var detail = res.body;
    if (detail.length > 400) {
      detail = "${detail.substring(0, 400)}…";
    }
    throw ChatwootAgentException(
      "$op: HTTP ${res.statusCode} $detail",
      statusCode: res.statusCode,
    );
  }
}

class ChatwootAgentException implements Exception {
  final String message;
  final int? statusCode;

  ChatwootAgentException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
