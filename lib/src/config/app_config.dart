enum AppFlavor { dev, prod }

class AppConfig {
  final AppFlavor flavor;
  final String chatwootBaseUrl;
  final String inboxIdentifier;
  final String bridgeBaseUrl;
  final String bridgeBotKey;

  const AppConfig({
    required this.flavor,
    required this.chatwootBaseUrl,
    required this.inboxIdentifier,
    required this.bridgeBaseUrl,
    required this.bridgeBotKey,
  });

  bool get isProd => flavor == AppFlavor.prod;

  factory AppConfig.fromEnvironment() {
    const flavorRaw = String.fromEnvironment("FLAVOR", defaultValue: "dev");
    const chatwoot = String.fromEnvironment(
      "CHATWOOT_BASE_URL",
      defaultValue: "http://127.0.0.1:3000",
    );
    const inbox = String.fromEnvironment(
      "CHATWOOT_INBOX_IDENTIFIER",
      defaultValue: "",
    );
    const bridge = String.fromEnvironment(
      "BRIDGE_BASE_URL",
      defaultValue: "http://127.0.0.1:4000",
    );
    const botKey = String.fromEnvironment(
      "BRIDGE_BOT_KEY",
      defaultValue: "test_bot",
    );

    return AppConfig(
      flavor: flavorRaw == "prod" ? AppFlavor.prod : AppFlavor.dev,
      chatwootBaseUrl: _trimSlash(chatwoot),
      inboxIdentifier: inbox.trim(),
      bridgeBaseUrl: _trimSlash(bridge),
      bridgeBotKey: botKey.trim(),
    );
  }

  AppConfig copyWith({
    AppFlavor? flavor,
    String? chatwootBaseUrl,
    String? inboxIdentifier,
    String? bridgeBaseUrl,
    String? bridgeBotKey,
  }) {
    return AppConfig(
      flavor: flavor ?? this.flavor,
      chatwootBaseUrl: chatwootBaseUrl ?? this.chatwootBaseUrl,
      inboxIdentifier: inboxIdentifier ?? this.inboxIdentifier,
      bridgeBaseUrl: bridgeBaseUrl ?? this.bridgeBaseUrl,
      bridgeBotKey: bridgeBotKey ?? this.bridgeBotKey,
    );
  }

  static String _trimSlash(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith("/")) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
