import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/src/models/bridge_models.dart';

class BridgeApiService {
  final String baseUrl;

  const BridgeApiService({required this.baseUrl});

  Future<BridgeHealth> fetchHealth() async {
    final response = await http.get(Uri.parse("$baseUrl/health"));
    final data = _json(response);
    if (response.statusCode >= 400) {
      throw Exception(data["error"] ?? "Bridge health failed");
    }
    return BridgeHealth.fromJson(data);
  }

  Future<BotRow?> loadBot({
    required String bridgeSecret,
    required String botKey,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/bots"),
      headers: _headers(bridgeSecret, withJson: false),
    );
    final data = _json(response);
    if (response.statusCode >= 400) {
      throw Exception(data["error"] ?? "Load bots failed");
    }
    final bots = (data["bots"] as Map?) ?? {};
    final row = bots[botKey];
    if (row is Map<String, dynamic>) return BotRow.fromJson(row);
    if (row is Map) return BotRow.fromJson(row.cast<String, dynamic>());
    return null;
  }

  Future<void> saveBot({
    required String bridgeSecret,
    required String botKey,
    required int inboxId,
    required String token,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/bots"),
      headers: _headers(bridgeSecret),
      body: jsonEncode({
        botKey: {"inboxId": inboxId, "token": token},
      }),
    );
    final data = _json(response);
    if (response.statusCode >= 400) {
      throw Exception(data["error"] ?? "Save bot failed");
    }
  }

  Future<String> verifyTelegram({
    required String bridgeSecret,
    required String botKey,
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/verify-telegram"),
      headers: _headers(bridgeSecret),
      body: jsonEncode(
        token == null || token.trim().isEmpty
            ? {"botKey": botKey}
            : {"token": token.trim()},
      ),
    );
    final data = _json(response);
    if (response.statusCode >= 400) {
      throw Exception(data["error"] ?? "Verify failed");
    }
    final result = (data["result"] as Map?)?.cast<String, dynamic>() ?? {};
    return "@${result["username"] ?? "unknown"} (${result["id"] ?? "-"})";
  }

  Future<int?> testIncoming({
    required String bridgeSecret,
    required String botKey,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/test-incoming"),
      headers: _headers(bridgeSecret),
      body: jsonEncode({"botKey": botKey, "text": "Тест из mobile app"}),
    );
    final data = _json(response);
    if (response.statusCode >= 400) {
      throw Exception(data["error"] ?? "Test incoming failed");
    }
    return int.tryParse("${data["conversationId"] ?? ""}");
  }

  Map<String, String> _headers(String secret, {bool withJson = true}) {
    final headers = <String, String>{"X-Bridge-Secret": secret.trim()};
    if (withJson) headers["Content-Type"] = "application/json";
    return headers;
  }

  Map<String, dynamic> _json(http.Response response) {
    final trimmed = response.body.trim();
    if (trimmed.isEmpty) return {};
    final value = jsonDecode(trimmed);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return {"data": value};
  }
}
