import 'package:flutter/material.dart';
import 'package:mobile/src/models/bridge_models.dart';
import 'package:mobile/src/services/bridge_api_service.dart';
import 'package:mobile/src/services/local_settings_service.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class BridgeSettingsScreen extends StatefulWidget {
  final BridgeApiService bridgeApi;
  final LocalSettingsService settings;
  final String initialBotKey;

  const BridgeSettingsScreen({
    super.key,
    required this.bridgeApi,
    required this.settings,
    required this.initialBotKey,
  });

  @override
  State<BridgeSettingsScreen> createState() => _BridgeSettingsScreenState();
}

class _BridgeSettingsScreenState extends State<BridgeSettingsScreen> {
  final _secretCtrl = TextEditingController();
  final _botCtrl = TextEditingController();
  final _inboxCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  String? feedback;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _botCtrl.text = widget.initialBotKey;
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final secret = await widget.settings.readBridgeSecret();
    final botKey = await widget.settings.readString(
      LocalSettingsService.bridgeBotKeyKey,
    );
    final inboxId = await widget.settings.readString(
      LocalSettingsService.bridgeInboxIdKey,
    );
    setState(() {
      _secretCtrl.text = secret ?? "";
      if (botKey != null) _botCtrl.text = botKey;
      if (inboxId != null) _inboxCtrl.text = inboxId;
    });
  }

  Future<void> _loadRemote() async {
    await _guard(() async {
      final row = await widget.bridgeApi.loadBot(
        bridgeSecret: _secretCtrl.text.trim(),
        botKey: _botCtrl.text.trim(),
      );
      if (row?.inboxId != null) {
        _inboxCtrl.text = "${row!.inboxId}";
      }
      _msg(row == null ? "Bot not found" : _describeRow(row));
    });
  }

  Future<void> _saveRemote() async {
    await _guard(() async {
      final inbox = int.parse(_inboxCtrl.text.trim());
      await widget.bridgeApi.saveBot(
        bridgeSecret: _secretCtrl.text.trim(),
        botKey: _botCtrl.text.trim(),
        inboxId: inbox,
        token: _tokenCtrl.text.trim(),
      );
      await widget.settings.writeBridgeSecret(_secretCtrl.text.trim());
      await widget.settings.writeString(
        LocalSettingsService.bridgeBotKeyKey,
        _botCtrl.text.trim(),
      );
      await widget.settings.writeString(
        LocalSettingsService.bridgeInboxIdKey,
        "$inbox",
      );
      _tokenCtrl.clear();
      _msg("Сохранено");
    });
  }

  Future<void> _verify() async {
    await _guard(() async {
      final value = await widget.bridgeApi.verifyTelegram(
        bridgeSecret: _secretCtrl.text.trim(),
        botKey: _botCtrl.text.trim(),
        token: _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
      );
      _msg("Telegram OK: $value");
    });
  }

  Future<void> _testIncoming() async {
    await _guard(() async {
      final conversationId = await widget.bridgeApi.testIncoming(
        bridgeSecret: _secretCtrl.text.trim(),
        botKey: _botCtrl.text.trim(),
      );
      _msg("Test sent. conversationId=${conversationId ?? "-"}");
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      loading = true;
      feedback = null;
    });
    try {
      await action();
    } catch (e) {
      _msg(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void _msg(String text) {
    setState(() => feedback = text);
  }

  String _describeRow(BotRow row) {
    return "inboxId=${row.inboxId ?? "-"}, hasToken=${row.hasToken}, mask=${row.tokenMasked ?? "-"}";
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bridge Config",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Telegram бот и инбокс",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _secretCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "BRIDGE_SECRET",
                  prefixIcon: Icon(Icons.key_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _botCtrl,
                decoration: const InputDecoration(
                  labelText: "botKey",
                  prefixIcon: Icon(Icons.smart_toy_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _inboxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Inbox ID",
                  prefixIcon: Icon(Icons.inbox_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tokenCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Telegram token",
                  prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: KosmosButton(
                      label: "Load",
                      icon: Icons.download_rounded,
                      outlined: true,
                      onPressed: loading ? null : _loadRemote,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KosmosButton(
                      label: "Save",
                      icon: Icons.save_rounded,
                      onPressed: loading ? null : _saveRemote,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: KosmosButton(
                      label: "Verify",
                      icon: Icons.verified_outlined,
                      outlined: true,
                      onPressed: loading ? null : _verify,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KosmosButton(
                      label: "Test",
                      icon: Icons.science_outlined,
                      outlined: true,
                      onPressed: loading ? null : _testIncoming,
                    ),
                  ),
                ],
              ),
              if (loading) ...[
                const SizedBox(height: 12),
                const KosmosProgressBar(),
              ],
              if (feedback != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Text(
                    feedback!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFamily: "monospace",
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
