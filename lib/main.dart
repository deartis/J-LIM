import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/device_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/storage/presentation/storage_screen.dart';
import 'features/apps/presentation/apps_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => DeviceProvider(),
      child: const JLimApp(),
    ),
  );
}

class JLimApp extends StatelessWidget {
  const JLimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'J-LIM',
      theme: JLimTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _tab = 0;

  final _screens = const [
    DashboardScreen(),
    StorageScreen(),
    AppsScreen(),
  ];

  final _labels = ['Dashboard', 'Armazenamento', 'Apps'];
  final _icons = [
    Icons.monitor_heart_outlined,
    Icons.storage_outlined,
    Icons.apps_outlined,
  ];
  final _activeIcons = [
    Icons.monitor_heart_rounded,
    Icons.storage_rounded,
    Icons.apps_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: JLimTheme.bg,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            const Text(
              'J-LIM',
              style: TextStyle(
                color: JLimTheme.green,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 14,
              color: JLimTheme.border,
            ),
            const SizedBox(width: 10),
            Text(
              _labels[_tab].toUpperCase(),
              style: const TextStyle(
                color: JLimTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<DeviceProvider>(
            builder: (ctx, p, _) => IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  size: 20, color: JLimTheme.textSecondary),
              onPressed: p.refresh,
              tooltip: 'Atualizar',
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: JLimTheme.border.withValues(alpha: 0.5)),
        ),
      ),
      body: IndexedStack(
        index: _tab,
        children: _screens,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: JLimTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: JLimTheme.green.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              backgroundColor: JLimTheme.surface,
              height: 68,
              selectedIndex: _tab,
              animationDuration: const Duration(milliseconds: 300),
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: List.generate(
                3,
                (i) => NavigationDestination(
                  icon: Icon(_icons[i]),
                  selectedIcon: Icon(_activeIcons[i]),
                  label: _labels[i],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
