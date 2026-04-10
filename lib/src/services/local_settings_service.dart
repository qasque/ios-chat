import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  static const _secure = FlutterSecureStorage();

  static const bridgeSecretKey = "mobile.bridgeSecret";
  static const bridgeBotKeyKey = "mobile.bridgeBotKey";
  static const bridgeInboxIdKey = "mobile.bridgeInboxId";
  static const chatwootBaseUrlKey = "mobile.chatwootBaseUrl";
  static const chatwootInboxIdentifierKey = "mobile.chatwootInboxIdentifier";
  /// Устаревший PAT — удаляем при старте, операторы больше не хранят секреты.
  static const legacyChatwootAgentTokenKey = "mobile.chatwootAgentToken";
  static const mobileBridgeSessionKey = "mobile.bridgeSessionJwt";
  static const selectedAgentAccountIdKey = "mobile.selectedAgentAccountId";
  static const selectedInboxFilterIdKey = "mobile.selectedInboxFilterId";

  Future<String?> readBridgeSecret() => _secure.read(key: bridgeSecretKey);
  Future<void> writeBridgeSecret(String value) =>
      _secure.write(key: bridgeSecretKey, value: value);

  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> clearLegacyChatwootPatIfAny() async {
    await _secure.delete(key: legacyChatwootAgentTokenKey);
  }

  Future<String?> readMobileBridgeSession() =>
      _secure.read(key: mobileBridgeSessionKey);

  Future<void> writeMobileBridgeSession(String value) =>
      _secure.write(key: mobileBridgeSessionKey, value: value.trim());

  Future<void> deleteMobileBridgeSession() =>
      _secure.delete(key: mobileBridgeSessionKey);
}
