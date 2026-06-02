import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF00E87A),
      title: 'Bem-vindo ao J-LIM',
      subtitle: 'Monitoramento honesto',
      body:
          'Ao contrário dos apps comuns que exibem animações falsas de "otimização", o J-LIM só mostra o que realmente acontece no seu celular — usando as APIs oficiais do Android.',
    ),
    _OnboardingPage(
      icon: Icons.memory_rounded,
      color: Color(0xFF00E87A),
      title: 'RAM — Memória Real',
      subtitle: 'O que o número significa',
      body:
          'O uso de RAM mostra quanto da sua memória está em uso pelos apps. No Android, o SO usa memória livre como cache — isso é normal e saudável. O J-LIM diferencia RAM de apps da RAM de sistema.',
    ),
    _OnboardingPage(
      icon: Icons.developer_board_rounded,
      color: Color(0xFF3B8BFF),
      title: 'CPU — Processador',
      subtitle: 'Leitura de /proc/stat',
      body:
          'O uso de CPU é calculado lendo diretamente o arquivo /proc/stat do sistema, fazendo duas amostras com 200ms de intervalo. Isso dá a leitura mais precisa possível sem root.',
    ),
    _OnboardingPage(
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFFFFB800),
      title: 'Bateria — Dados Reais',
      subtitle: 'BatteryManager API',
      body:
          'Saúde, temperatura, voltagem e status de carga vêm diretamente da API BatteryManager do Android. Nenhuma estimativa é inventada — se não há dado disponível, mostramos "--".',
    ),
    _OnboardingPage(
      icon: Icons.verified_rounded,
      color: Color(0xFF00E87A),
      title: 'Pronto para usar!',
      subtitle: 'Sem anúncios. Sem enganação.',
      body:
          'O J-LIM é open source e não tem anúncios. Toque em Começar para explorar todas as telas: Dashboard, Armazenamento, Apps, Rede, Histórico e Informações do Dispositivo.',
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('jlim_onboarding_done', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JLimTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Pular
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Pular', style: TextStyle(color: JLimTheme.textMuted)),
              ),
            ),
            // Páginas
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _pages[i],
              ),
            ),
            // Indicadores
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? JLimTheme.green : JLimTheme.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Botão
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: _next,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: JLimTheme.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: JLimTheme.green.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    _page < _pages.length - 1 ? 'Próximo' : 'Começar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0A0C0B),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, body;
  const _OnboardingPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(icon, color: color, size: 46),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: JLimTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: JLimTheme.textSecondary, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }
}
