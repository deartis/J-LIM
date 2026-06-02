import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: JLimTheme.green),
          );
        }
        return RefreshIndicator(
          color: JLimTheme.green,
          backgroundColor: JLimTheme.surface,
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              _Header(provider: provider),
              const SizedBox(height: 16),
              _MetricRow(provider: provider),
              const SizedBox(height: 14),
              _CpuCard(provider: provider),
              const SizedBox(height: 12),
              _StorageCard(provider: provider),
              const SizedBox(height: 12),
              _BatteryCard(provider: provider),
            ],
          ),
        );
      },
    );
  }
}

// ── PULSING DOT ────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: JLimTheme.green.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: JLimTheme.green.withValues(alpha: _anim.value * 0.6),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DeviceProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.lastUpdate != null)
              Text(
                'Atualizado ${_timeAgo(provider.lastUpdate!)}',
                style: const TextStyle(
                  color: JLimTheme.textMuted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: JLimTheme.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: JLimTheme.green.withValues(alpha: 0.25)),
          ),
          child: const Row(
            children: [
              _PulsingDot(),
              SizedBox(width: 7),
              Text(
                'AO VIVO',
                style: TextStyle(
                  color: JLimTheme.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt).inSeconds;
    if (diff < 5) return 'agora';
    if (diff < 60) return 'há ${diff}s';
    return 'há ${diff ~/ 60}min';
  }
}

// ── METRIC ROW ────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  final DeviceProvider provider;
  const _MetricRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CircularMetric(
            label: 'RAM',
            percent: provider.ramPercent,
            value: '${(provider.ramPercent * 100).toInt()}%',
            sub: formatBytes(provider.ramUsed),
            color: statusColor(provider.ramPercent),
            icon: Icons.memory_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircularMetric(
            label: 'CPU',
            percent: provider.cpuUsage / 100,
            value: '${provider.cpuUsage.toInt()}%',
            sub: '${provider.cpuCores} núcleos',
            color: statusColor(provider.cpuUsage / 100),
            icon: Icons.developer_board_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircularMetric(
            label: 'BAT',
            percent: provider.batteryPercent / 100,
            value: '${provider.batteryPercent}%',
            sub: provider.batteryStatus,
            color: statusColor(1 - provider.batteryPercent / 100),
            icon: Icons.battery_charging_full_rounded,
          ),
        ),
      ],
    );
  }
}

class _CircularMetric extends StatelessWidget {
  final String label;
  final double percent;
  final String value;
  final String sub;
  final Color color;
  final IconData icon;

  const _CircularMetric({
    required this.label,
    required this.percent,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JLimTheme.card,
            Color.lerp(JLimTheme.card, color, 0.06)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 30,
            lineWidth: 4.5,
            percent: percent.clamp(0.0, 1.0),
            backgroundColor: JLimTheme.border,
            progressColor: color,
            circularStrokeCap: CircularStrokeCap.round,
            center: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: JLimTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: const TextStyle(
              color: JLimTheme.textMuted,
              fontSize: 9,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── CPU CARD ──────────────────────────────────────────────────────────────────

class _CpuCard extends StatelessWidget {
  final DeviceProvider provider;
  const _CpuCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(provider.cpuUsage / 100);
    return _DCard(
      title: 'CPU',
      subtitle:
          '${provider.cpuUsage.toStringAsFixed(1)}%  ·  ${provider.cpuCores} núcleos',
      color: color,
      child: Column(
        children: [
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: JLimTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: provider.cpuHistory
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (provider.cpuPerCore.isNotEmpty) ...
            [
              const SizedBox(height: 10),
              _CoreBars(cores: provider.cpuPerCore),
            ],
        ],
      ),
    );
  }
}

class _CoreBars extends StatelessWidget {
  final List<double> cores;
  const _CoreBars({required this.cores});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: cores.asMap().entries.map((e) {
        final pct = e.value / 100;
        final color = statusColor(pct);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text('C${e.key}', style: const TextStyle(color: JLimTheme.textMuted, fontSize: 7, letterSpacing: 0.5)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: JLimTheme.border,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text('${e.value.toInt()}%', style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── STORAGE CARD ──────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final DeviceProvider provider;
  const _StorageCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(provider.storagePercent);
    final pct = (provider.storagePercent * 100).toInt();
    return _DCard(
      title: 'ARMAZENAMENTO',
      subtitle:
          '${formatBytes(provider.storageUsed)} / ${formatBytes(provider.storageTotal)}',
      color: color,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: provider.storagePercent,
                  backgroundColor: JLimTheme.border,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StorageLegend('Usado', formatBytes(provider.storageUsed), color),
              _StorageLegend('Livre', formatBytes(provider.storageFree),
                  JLimTheme.textSecondary),
              Text(
                '$pct%',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StorageLegend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageLegend(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: JLimTheme.textMuted, fontSize: 10)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── BATTERY CARD ──────────────────────────────────────────────────────────────

class _BatteryCard extends StatelessWidget {
  final DeviceProvider provider;
  const _BatteryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(1 - provider.batteryPercent / 100);
    final timeStr = formatMinutes(provider.batteryMinutesRemaining);
    final isCharging = provider.batteryStatus.contains('Carregando');
    return _DCard(
      title: 'BATERIA',
      subtitle: '${provider.batteryStatus}  ·  ${provider.batteryPlugged}',
      color: color,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    _BatteryRow('Saúde', provider.batteryHealth),
                    _BatteryRow(
                      'Temperatura',
                      '${provider.batteryTempC.toStringAsFixed(1)} °C',
                      valueColor: provider.batteryTempC > 40 ? JLimTheme.red : null,
                    ),
                    _BatteryRow('Voltagem', '${provider.batteryVoltageMv} mV'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              CircularPercentIndicator(
                radius: 36,
                lineWidth: 5,
                percent: (provider.batteryPercent / 100).clamp(0.0, 1.0),
                backgroundColor: JLimTheme.border,
                progressColor: color,
                circularStrokeCap: CircularStrokeCap.round,
                center: Text(
                  '${provider.batteryPercent}%',
                  style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          if (provider.batteryMinutesRemaining > 0) ...
            [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCharging ? Icons.bolt_rounded : Icons.access_time_rounded,
                        color: color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isCharging
                          ? 'Carregamento completo em $timeStr'
                          : 'Estimativa de $timeStr restantes',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _BatteryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _BatteryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: JLimTheme.textMuted, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? JLimTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── WIDGET BASE CARD ──────────────────────────────────────────────────────────

class _DCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _DCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            JLimTheme.card,
            Color.lerp(JLimTheme.card, color, 0.04)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: JLimTheme.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
