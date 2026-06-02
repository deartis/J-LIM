import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_provider.dart';
import '../../../core/utils/device_channel.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (ctx, provider, _) {
        final pct = provider.storagePercent;
        final color = statusColor(pct);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Gráfico de pizza
            _StoragePieCard(provider: provider, color: color),
            const SizedBox(height: 16),
            // Detalhes
            _InfoGrid(provider: provider, color: color),
            const SizedBox(height: 16),
            // Botão de limpeza via Sistema
            _CleanButton(),
          ],
        );
      },
    );
  }
}

class _StoragePieCard extends StatelessWidget {
  final DeviceProvider provider;
  final Color color;
  const _StoragePieCard({required this.provider, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JLimTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 3, height: 16,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('ARMAZENAMENTO INTERNO',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 55,
                sections: [
                  PieChartSectionData(
                    value: provider.storageUsed.toDouble(),
                    color: color,
                    title: '${(provider.storagePercent * 100).toInt()}%',
                    titleStyle: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: provider.storageFree.toDouble(),
                    color: JLimTheme.border,
                    title: '',
                    radius: 44,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend('Usado', formatBytes(provider.storageUsed), color),
              const SizedBox(width: 24),
              _Legend('Livre', formatBytes(provider.storageFree), JLimTheme.textSecondary),
              const SizedBox(width: 24),
              _Legend('Total', formatBytes(provider.storageTotal), JLimTheme.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Legend(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: JLimTheme.textMuted, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final DeviceProvider provider;
  final Color color;
  const _InfoGrid({required this.provider, required this.color});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', formatBytes(provider.storageTotal), Icons.storage_rounded),
      ('Usado', formatBytes(provider.storageUsed), Icons.inventory_2_rounded),
      ('Livre', formatBytes(provider.storageFree), Icons.check_circle_outline_rounded),
      ('Ocupação', '${(provider.storagePercent * 100).toInt()}%', Icons.donut_large_rounded),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: JLimTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: JLimTheme.border),
          ),
          child: Row(
            children: [
              Icon(item.$3, color: color, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.$1,
                      style: const TextStyle(color: JLimTheme.textMuted, fontSize: 10)),
                  Text(item.$2,
                      style: TextStyle(
                          color: color, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _CleanButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => DeviceChannel.openStorageSettings(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: JLimTheme.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: JLimTheme.green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: JLimTheme.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cleaning_services_rounded,
                  color: JLimTheme.green, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerenciar armazenamento',
                    style: TextStyle(
                      color: JLimTheme.green,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Abre as configurações do Android para liberar espaço',
                    style: TextStyle(color: JLimTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: JLimTheme.green, size: 14),
          ],
        ),
      ),
    );
  }
}
