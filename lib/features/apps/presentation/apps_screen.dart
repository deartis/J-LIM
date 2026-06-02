import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/device_channel.dart';
import '../../../core/utils/device_provider.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _sort = 'nome'; // nome | tamanho

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    final apps = await DeviceChannel.getAppStorageList();
    setState(() {
      _apps = apps;
      _loading = false;
      _apply();
    });
  }

  void _apply() {
    var list = _apps.where((a) {
      final name = (a['appName'] as String).toLowerCase();
      return name.contains(_search.toLowerCase());
    }).toList();

    if (_sort == 'tamanho') {
      list.sort((a, b) {
        final bTotal = (b['totalSize'] as num?)?.toInt() ?? (b['apkSize'] as num?)?.toInt() ?? 0;
        final aTotal = (a['totalSize'] as num?)?.toInt() ?? (a['apkSize'] as num?)?.toInt() ?? 0;
        return bTotal.compareTo(aTotal);
      });
    } else {
      list.sort((a, b) => (a['appName'] as String).compareTo(b['appName'] as String));
    }
    _filtered = list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca + ordenação
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: JLimTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar app...',
                    hintStyle: const TextStyle(color: JLimTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: JLimTheme.textMuted, size: 18),
                    filled: true,
                    fillColor: JLimTheme.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: JLimTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: JLimTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: JLimTheme.green),
                    ),
                  ),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _apply();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              _SortButton(
                label: 'Nome',
                active: _sort == 'nome',
                onTap: () => setState(() {
                  _sort = 'nome';
                  _apply();
                }),
              ),
              const SizedBox(width: 6),
              _SortButton(
                label: 'Tamanho',
                active: _sort == 'tamanho',
                onTap: () => setState(() {
                  _sort = 'tamanho';
                  _apply();
                }),
              ),
            ],
          ),
        ),
        // Contador
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text(
                '${_filtered.length} apps instalados',
                style: const TextStyle(color: JLimTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: JLimTheme.green))
              : RefreshIndicator(
                  color: JLimTheme.green,
                  backgroundColor: JLimTheme.surface,
                  onRefresh: _loadApps,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _AppTile(
                      app: _filtered[i],
                      onSettings: () =>
                          DeviceChannel.openAppSettings(_filtered[i]['packageName']),
                      onUninstall: () => _confirmUninstall(ctx, _filtered[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _confirmUninstall(BuildContext context, Map<String, dynamic> app) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: JLimTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: JLimTheme.border),
        ),
        title: const Text(
          'Desinstalar app?',
          style: TextStyle(color: JLimTheme.textPrimary),
        ),
        content: Text(
          'Deseja desinstalar "${app['appName']}"?',
          style: const TextStyle(color: JLimTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: JLimTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              DeviceChannel.uninstallApp(app['packageName']);
            },
            child: const Text('Desinstalar', style: TextStyle(color: JLimTheme.red)),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final Map<String, dynamic> app;
  final VoidCallback onSettings;
  final VoidCallback onUninstall;

  const _AppTile({
    required this.app,
    required this.onSettings,
    required this.onUninstall,
  });

  @override
  Widget build(BuildContext context) {
    final apkSize = (app['apkSize'] as num?)?.toInt() ?? 0;
    final dataSize = (app['dataSize'] as num?)?.toInt() ?? 0;
    final cacheSize = (app['cacheSize'] as num?)?.toInt() ?? 0;
    final totalSize = (app['totalSize'] as num?)?.toInt() ?? apkSize;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: JLimTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: JLimTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: JLimTheme.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              (app['appName'] as String).isNotEmpty
                  ? (app['appName'] as String)[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: JLimTheme.green,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          app['appName'] ?? '',
          style: const TextStyle(
            color: JLimTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              totalSize > 0 ? formatBytes(totalSize) : app['packageName'] ?? '',
              style: const TextStyle(color: JLimTheme.textMuted, fontSize: 11),
            ),
            if (dataSize > 0 || cacheSize > 0)
              Text(
                'APK: ${formatBytes(apkSize)}  Dados: ${formatBytes(dataSize)}  Cache: ${formatBytes(cacheSize)}',
                style: const TextStyle(color: JLimTheme.textMuted, fontSize: 9),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 18),
              color: JLimTheme.textSecondary,
              onPressed: onSettings,
              tooltip: 'Configurações',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              color: JLimTheme.red.withValues(alpha: 0.7),
              onPressed: onUninstall,
              tooltip: 'Desinstalar',
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SortButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? JLimTheme.green.withValues(alpha: 0.15)
              : JLimTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? JLimTheme.green : JLimTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? JLimTheme.green : JLimTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
