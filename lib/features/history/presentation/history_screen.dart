import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _metric = 'cpu'; // 'cpu' | 'ram'
  final GlobalKey _chartKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final history = _metric == 'cpu'
            ? provider.cpuSessionHistory
            : provider.ramSessionHistory;

        final values = history.map((p) => p.value).toList();
        final avg = values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;
        final minV = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
        final maxV = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
        final color = _metric == 'cpu' ? JLimTheme.blue : JLimTheme.green;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Seletor de métrica
            _MetricSelector(
              selected: _metric,
              onSelect: (m) => setState(() => _metric = m),
            ),
            const SizedBox(height: 14),
            // Estatísticas da sessão
            _StatsRow(avg: avg, min: minV, max: maxV, color: color),
            const SizedBox(height: 14),
            // Gráfico
            RepaintBoundary(
              key: _chartKey,
              child: _HistoryChart(
                history: history,
                color: color,
                label: _metric == 'cpu' ? 'CPU' : 'RAM',
              ),
            ),
            const SizedBox(height: 14),
            // Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: JLimTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: JLimTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: JLimTheme.textMuted, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Histórico acumula um ponto a cada 10 segundos desde a abertura do app. Máximo de 2 horas (720 pontos).',
                      style: const TextStyle(color: JLimTheme.textMuted, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Botão de compartilhar
            _ShareButton(
              isLoading: _sharing,
              onShare: () => _shareSnapshot(provider),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareSnapshot(DeviceProvider provider) async {
    setState(() => _sharing = true);
    try {
      final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/jlim_snapshot.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'J-LIM — Monitoramento ${_metric.toUpperCase()} | RAM: ${provider.ramPercent.toStringAsFixed(0)}% | CPU: ${provider.cpuUsage.toStringAsFixed(0)}%',
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar: $e');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}

// ── SELETOR DE MÉTRICA ────────────────────────────────────────────────────────

class _MetricSelector extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  const _MetricSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricChip(label: 'CPU', value: 'cpu', selected: selected, color: JLimTheme.blue, onSelect: onSelect),
        const SizedBox(width: 10),
        _MetricChip(label: 'RAM', value: 'ram', selected: selected, color: JLimTheme.green, onSelect: onSelect),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label, value, selected;
  final Color color;
  final void Function(String) onSelect;
  const _MetricChip({required this.label, required this.value, required this.selected, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isActive = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : JLimTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color : JLimTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : JLimTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── ESTATÍSTICAS ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final double avg, min, max;
  final Color color;
  const _StatsRow({required this.avg, required this.min, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatItem(label: 'MÉDIA', value: '${avg.toStringAsFixed(1)}%', color: color)),
        const SizedBox(width: 10),
        Expanded(child: _StatItem(label: 'MÍNIMO', value: '${min.toStringAsFixed(1)}%', color: JLimTheme.green)),
        const SizedBox(width: 10),
        Expanded(child: _StatItem(label: 'MÁXIMO', value: '${max.toStringAsFixed(1)}%', color: JLimTheme.red)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [JLimTheme.card, Color.lerp(JLimTheme.card, color, 0.07)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: JLimTheme.textMuted, fontSize: 9, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ── GRÁFICO ───────────────────────────────────────────────────────────────────

class _HistoryChart extends StatelessWidget {
  final List<MetricPoint> history;
  final Color color;
  final String label;
  const _HistoryChart({required this.history, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [JLimTheme.card, Color.lerp(JLimTheme.card, color, 0.04)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 3, height: 16,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)])),
            const SizedBox(width: 8),
            Text('HISTÓRICO — $label', style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
            )),
            const Spacer(),
            Text(
              history.isEmpty ? 'Aguardando dados...' : '${history.length} pontos',
              style: const TextStyle(color: JLimTheme.textMuted, fontSize: 10),
            ),
          ]),
          const SizedBox(height: 16),
          if (history.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart_rounded, color: JLimTheme.border, size: 40),
                    SizedBox(height: 8),
                    Text('Dados acumulando...', style: TextStyle(color: JLimTheme.textMuted, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Aguarde alguns segundos', style: TextStyle(color: JLimTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: JLimTheme.border.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                        style: const TextStyle(color: JLimTheme.textMuted, fontSize: 8)),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: history.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
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
                        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ],
              )),
            ),
        ],
      ),
    );
  }
}

// ── BOTÃO DE COMPARTILHAR ─────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onShare;
  const _ShareButton({required this.isLoading, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onShare,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JLimTheme.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JLimTheme.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: JLimTheme.green),
              )
            else
              const Icon(Icons.share_rounded, color: JLimTheme.green, size: 18),
            const SizedBox(width: 10),
            Text(
              isLoading ? 'Gerando imagem...' : 'Compartilhar gráfico como imagem',
              style: const TextStyle(color: JLimTheme.green, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
