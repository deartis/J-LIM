import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../alert_service.dart';

class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({super.key});

  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  final _service = AlertService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JLimTheme.bg,
      appBar: AppBar(
        backgroundColor: JLimTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: JLimTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('ALERTAS',
            style: TextStyle(
              color: JLimTheme.green,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: JLimTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoBanner(),
          const SizedBox(height: 16),
          _AlertCard(
            title: 'RAM Crítica',
            subtitle: 'Notifica quando o uso de memória está alto',
            icon: Icons.memory_rounded,
            color: JLimTheme.red,
            enabled: _service.ramAlertEnabled,
            onToggle: (v) => setState(() {
              _service.ramAlertEnabled = v;
              _service.savePrefs();
            }),
            sliderLabel: 'Threshold de RAM',
            sliderUnit: '%',
            sliderValue: _service.ramThresholdPct,
            sliderMin: 60,
            sliderMax: 95,
            onSlider: (v) => setState(() {
              _service.ramThresholdPct = v;
              _service.savePrefs();
            }),
          ),
          const SizedBox(height: 12),
          _AlertCard(
            title: 'Temperatura Alta',
            subtitle: 'Notifica quando a bateria está superaquecendo',
            icon: Icons.thermostat_rounded,
            color: JLimTheme.amber,
            enabled: _service.tempAlertEnabled,
            onToggle: (v) => setState(() {
              _service.tempAlertEnabled = v;
              _service.savePrefs();
            }),
            sliderLabel: 'Temperatura limite',
            sliderUnit: '°C',
            sliderValue: _service.tempThresholdC,
            sliderMin: 35,
            sliderMax: 55,
            onSlider: (v) => setState(() {
              _service.tempThresholdC = v;
              _service.savePrefs();
            }),
          ),
          const SizedBox(height: 12),
          _AlertCard(
            title: 'Armazenamento Crítico',
            subtitle: 'Notifica quando o espaço livre está baixo',
            icon: Icons.storage_rounded,
            color: JLimTheme.blue,
            enabled: _service.storageAlertEnabled,
            onToggle: (v) => setState(() {
              _service.storageAlertEnabled = v;
              _service.savePrefs();
            }),
            sliderLabel: 'Espaço livre mínimo',
            sliderUnit: '%',
            sliderValue: _service.storageThresholdPct,
            sliderMin: 5,
            sliderMax: 25,
            onSlider: (v) => setState(() {
              _service.storageThresholdPct = v;
              _service.savePrefs();
            }),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: JLimTheme.green.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: JLimTheme.green.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: JLimTheme.green, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alertas são verificados a cada 30 segundos. Cada tipo tem cooldown de 10 minutos para não incomodar.',
              style: TextStyle(color: JLimTheme.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title, subtitle, sliderLabel, sliderUnit;
  final IconData icon;
  final Color color;
  final bool enabled;
  final void Function(bool) onToggle;
  final double sliderValue, sliderMin, sliderMax;
  final void Function(double) onSlider;

  const _AlertCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onToggle,
    required this.sliderLabel,
    required this.sliderUnit,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onSlider,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [JLimTheme.card, Color.lerp(JLimTheme.card, color, 0.04)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: enabled ? color.withValues(alpha: 0.3) : JLimTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: JLimTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: JLimTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeThumbColor: color,
                  activeTrackColor: color.withValues(alpha: 0.3),
                  inactiveThumbColor: JLimTheme.textMuted,
                  inactiveTrackColor: JLimTheme.border,
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sliderLabel,
                      style: const TextStyle(
                          color: JLimTheme.textMuted, fontSize: 11)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${sliderValue.toInt()}$sliderUnit',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: color,
                  inactiveTrackColor: color.withValues(alpha: 0.15),
                  thumbColor: color,
                  overlayColor: color.withValues(alpha: 0.15),
                  trackHeight: 3,
                ),
                child: Slider(
                  value: sliderValue,
                  min: sliderMin,
                  max: sliderMax,
                  divisions: (sliderMax - sliderMin).toInt(),
                  onChanged: onSlider,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
