import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_provider.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final info = provider.deviceInfo;
        if (info.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: JLimTheme.green));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _DeviceHeader(info: info),
            const SizedBox(height: 16),
            _InfoSection(
              title: 'HARDWARE',
              color: JLimTheme.green,
              icon: Icons.memory_rounded,
              items: [
                ('Fabricante', '${info['manufacturer']}'),
                ('Modelo', '${info['model']}'),
                ('Hardware', '${info['hardware']}'),
                ('Board', '${info['board']}'),
                ('CPU ABI', '${info['cpuAbi']}'),
                ('CPUs', '${info['cpuCores']} núcleos'),
                ('ABIs suportadas', '${info['cpuAbiList']}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: 'SISTEMA',
              color: JLimTheme.blue,
              icon: Icons.android_rounded,
              items: [
                ('Android', '${info['androidVersion']} (API ${info['sdkInt']})'),
                ('Build', '${info['buildNumber']}'),
                ('Kernel', '${info['kernelVersion']}'),
                ('Baseband', '${info['baseband']}'),
                ('Patch de Segurança', '${info['securityPatch']}'),
                ('Fingerprint', '${info['fingerprint']}'),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: 'TELA',
              color: JLimTheme.amber,
              icon: Icons.smartphone_rounded,
              items: [
                ('Resolução', '${info['screenWidth']} × ${info['screenHeight']} px'),
                ('DPI', '${info['screenDpi']} dpi'),
                ('Densidade', '${info['screenDensity']}x'),
                ('Taxa de atualização', '${info['refreshRate']} Hz'),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── HEADER ────────────────────────────────────────────────────────────────────

class _DeviceHeader extends StatelessWidget {
  final Map<String, dynamic> info;
  const _DeviceHeader({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [JLimTheme.card, Color.lerp(JLimTheme.card, JLimTheme.green, 0.06)!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JLimTheme.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: JLimTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: JLimTheme.green.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.smartphone_rounded, color: JLimTheme.green, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info['manufacturer']} ${info['model']}',
                  style: const TextStyle(
                    color: JLimTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Android ${info['androidVersion']}  ·  ${info['cpuCores']} cores',
                  style: const TextStyle(color: JLimTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '${info['screenWidth']}×${info['screenHeight']}  ·  ${info['screenDpi']} dpi',
                  style: const TextStyle(color: JLimTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── SEÇÃO DE INFO ─────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final List<(String, String)> items;

  const _InfoSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5,
                )),
              ],
            ),
          ),
          const Divider(color: JLimTheme.border, height: 1),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            final item = entry.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.$1,
                          style: const TextStyle(color: JLimTheme.textMuted, fontSize: 12),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                            color: JLimTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(color: JLimTheme.border, height: 1, indent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}
