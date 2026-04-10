class BridgeHealth {
  final bool ok;
  final String? service;
  final int outboundQueueSize;

  const BridgeHealth({
    required this.ok,
    required this.service,
    required this.outboundQueueSize,
  });

  factory BridgeHealth.fromJson(Map<String, dynamic> json) {
    return BridgeHealth(
      ok: json["ok"] == true,
      service: json["service"]?.toString(),
      outboundQueueSize: int.tryParse("${json["outboundQueueSize"] ?? 0}") ?? 0,
    );
  }
}

class BotRow {
  final int? inboxId;
  final String? tokenMasked;
  final bool hasToken;

  const BotRow({this.inboxId, this.tokenMasked, required this.hasToken});

  factory BotRow.fromJson(Map<String, dynamic> json) {
    return BotRow(
      inboxId: int.tryParse("${json["inboxId"] ?? ""}"),
      tokenMasked: json["tokenMasked"]?.toString(),
      hasToken: json["hasToken"] == true,
    );
  }
}
