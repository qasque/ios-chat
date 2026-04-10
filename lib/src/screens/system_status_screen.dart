import 'package:flutter/material.dart';
import 'package:mobile/src/models/bridge_models.dart';
import 'package:mobile/src/services/bridge_api_service.dart';
import 'package:mobile/src/theme.dart';
import 'package:mobile/src/widgets/kosmos_widgets.dart';

class SystemStatusScreen extends StatefulWidget {
  final BridgeApiService bridgeApi;
  final String? pushToken;

  const SystemStatusScreen({
    super.key,
    required this.bridgeApi,
    required this.pushToken,
  });

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  BridgeHealth? health;
  String? error;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await widget.bridgeApi.fetchHealth();
      setState(() => health = value);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
      onRefresh: _refresh,
      child: ListView(
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
                        color: _healthColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.monitor_heart_rounded,
                        color: _healthColor(),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Статус системы",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _statusLabel(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _healthColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (loading) const KosmosSpinner(size: 20),
                  ],
                ),
                const SizedBox(height: 18),
                _StatusRow(
                  icon: Icons.dns_outlined,
                  label: "Bridge",
                  value: health == null ? "?" : (health!.ok ? "OK" : "Error"),
                  valueColor: health?.ok == true ? AppColors.green : AppColors.red,
                ),
                _StatusRow(
                  icon: Icons.miscellaneous_services_outlined,
                  label: "Service",
                  value: health?.service ?? "-",
                ),
                _StatusRow(
                  icon: Icons.outbox_outlined,
                  label: "Outbound queue",
                  value: "${health?.outboundQueueSize ?? 0}",
                ),
                _StatusRow(
                  icon: Icons.notifications_outlined,
                  label: "Push token",
                  value: widget.pushToken == null ? "Нет" : "Получен",
                  valueColor: widget.pushToken != null
                      ? AppColors.green
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        color: AppColors.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _healthColor() {
    if (health == null) return AppColors.textTertiary;
    return health!.ok ? AppColors.green : AppColors.red;
  }

  String _statusLabel() {
    if (loading && health == null) return "Проверка...";
    if (health == null) return "Неизвестно";
    return health!.ok ? "Все системы работают" : "Обнаружена проблема";
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: (valueColor ?? AppColors.textSecondary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
