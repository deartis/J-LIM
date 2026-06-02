import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_provider.dart';

class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          color: JLimTheme.green,
          backgroundColor: JLimTheme.surface,
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _ConnectionCard(provider: provider),
              const SizedBox(height: 12),
              _SpeedCard(provider: provider),
              const SizedBox(height: 12),
              _DataTotalsCard(provider: provider),
              const SizedBox(height: 12),
              if (provider.networkUsageByApp.isNotEmpty)
                _AppUsageCard(provider: provider),
            ],
          ),
        );
      },
    );
  }
}

// ── CONEXÃO ──────────────────────────────────────────────────────────────────

class _ConnectionCard extends StatelessWidget {
  final DeviceProvider provider;
  const _ConnectionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final type = provider.networkConnectionType;
    final isWifi = type.toLowerCase().contains('wi-fi');
    final isMobile = type.toLowerCase().contains('móveis') || type.toLowerCase().contains('dados');
    final color = type.isEmpty || type == 'Sem conexão' ? JLimTheme.red : JLimTheme.blue;
    final icon = isWifi
        ? Icons.wifi_rounded
        : isMobile
            ? Icons.signal_cellular_alt_rounded
            : Icons.network_check_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [JLimTheme.card, Color.lerp(JLimTheme.card, color, 0.05)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.isEmpty ? 'Sem conexão' : type,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.networkIpAddress.isEmpty
                      ? 'IP não detectado'
                      : 'IP: ${provider.networkIpAddress}',
                  style: const TextStyle(color: JLimTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              type.isEmpty ? 'OFFLINE' : 'ONLINE',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── VELOCIDADE ────────────────────────────────────────────────────────────────

class _SpeedCard extends StatelessWidget {
  final DeviceProvider provider;
  const _SpeedCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JLimTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3, height: 16,
                decoration: BoxDecoration(
                  color: JLimTheme.blue,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [BoxShadow(color: JLimTheme.blue.withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 8),
              const Text('VELOCIDADE', style: TextStyle(
                color: JLimTheme.blue, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SpeedIndicator(
                label: '↓ DOWNLOAD',
                speed: provider.networkRxSpeed,
                color: JLimTheme.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _SpeedIndicator(
                label: '↑ UPLOAD',
                speed: provider.networkTxSpeed,
                color: JLimTheme.blue,
              )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                _buildLine(provider.networkRxHistory, JLimTheme.green),
                _buildLine(provider.networkTxHistory, JLimTheme.blue),
              ],
            )),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<double> data, Color color) {
    return LineChartBarData(
      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _SpeedIndicator extends StatelessWidget {
  final String label;
  final int speed;
  final Color color;
  const _SpeedIndicator({required this.label, required this.speed, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: JLimTheme.textMuted, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(
            formatSpeed(speed),
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

// ── TOTAIS ────────────────────────────────────────────────────────────────────

class _DataTotalsCard extends StatelessWidget {
  final DeviceProvider provider;
  const _DataTotalsCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JLimTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16,
              decoration: BoxDecoration(color: JLimTheme.textSecondary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('DADOS DESDE O BOOT', style: TextStyle(
              color: JLimTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
            )),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _TotalItem(
              icon: Icons.download_rounded,
              label: 'Recebido',
              value: formatBytes(provider.networkTotalRx),
              color: JLimTheme.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _TotalItem(
              icon: Icons.upload_rounded,
              label: 'Enviado',
              value: formatBytes(provider.networkTotalTx),
              color: JLimTheme.blue,
            )),
          ]),
        ],
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _TotalItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: JLimTheme.textMuted, fontSize: 10)),
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}

// ── USO POR APP ───────────────────────────────────────────────────────────────

class _AppUsageCard extends StatelessWidget {
  final DeviceProvider provider;
  const _AppUsageCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final apps = provider.networkUsageByApp.take(10).toList();
    final maxBytes = (apps.first['totalBytes'] as num?)?.toInt() ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JLimTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16,
              decoration: BoxDecoration(color: JLimTheme.amber, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('USO POR APP (desde o boot)', style: TextStyle(
              color: JLimTheme.amber, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
            )),
          ]),
          const SizedBox(height: 12),
          ...apps.map((app) {
            final total = (app['totalBytes'] as num?)?.toInt() ?? 0;
            final rx = (app['rxBytes'] as num?)?.toInt() ?? 0;
            final tx = (app['txBytes'] as num?)?.toInt() ?? 0;
            final frac = maxBytes > 0 ? total / maxBytes : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app['appName'] as String? ?? '',
                          style: const TextStyle(color: JLimTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formatBytes(total),
                        style: const TextStyle(color: JLimTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: frac.toDouble(),
                      backgroundColor: JLimTheme.border,
                      valueColor: const AlwaysStoppedAnimation(JLimTheme.blue),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text('↓ ${formatBytes(rx)}', style: const TextStyle(color: JLimTheme.green, fontSize: 9)),
                      const SizedBox(width: 8),
                      Text('↑ ${formatBytes(tx)}', style: const TextStyle(color: JLimTheme.blue, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
