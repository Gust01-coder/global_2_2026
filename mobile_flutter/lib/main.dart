import 'package:flutter/material.dart';
import 'screens/idosos_screen.dart';
import 'screens/relatorios_screen.dart';
import 'screens/rodada_screen.dart';
import 'screens/sensor_alertas_screen.dart';
import 'services/plantao_api.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PlantaoClimaApp());
}

class PlantaoClimaApp extends StatelessWidget {
  const PlantaoClimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plantão Clima · App do Voluntário',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const PlantaoHomeShell(),
    );
  }
}

class PlantaoHomeShell extends StatefulWidget {
  const PlantaoHomeShell({super.key});

  @override
  State<PlantaoHomeShell> createState() => _PlantaoHomeShellState();
}

class _PlantaoHomeShellState extends State<PlantaoHomeShell> {
  final PlantaoApi _api = PlantaoApi();
  int _aba = 0;

  void _atualizarStatus() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final telas = [
      RodadaScreen(api: _api, onStatusChanged: _atualizarStatus),
      IdososScreen(api: _api, onStatusChanged: _atualizarStatus),
      SensorAlertasScreen(api: _api, onStatusChanged: _atualizarStatus),
      RelatoriosScreen(api: _api, onStatusChanged: _atualizarStatus),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Plantão Clima'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.subtle,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _api.online ? AppColors.okDot : AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _api.online ? 'H2 Online' : 'Demo Local',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: KeyedSubtree(
          key: ValueKey(_aba),
          child: telas[_aba],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: _aba,
          onDestinationSelected: (i) => setState(() => _aba = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.phone_in_talk_outlined),
              selectedIcon: Icon(Icons.phone_in_talk),
              label: 'Rodada',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Idosos',
            ),
            NavigationDestination(
              icon: Icon(Icons.water_outlined),
              selectedIcon: Icon(Icons.water),
              label: 'Sensor',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Relatórios',
            ),
          ],
        ),
      ),
    );
  }
}
