import 'package:flutter/material.dart';
import '../models/plantao_models.dart';
import '../services/plantao_api.dart';
import '../theme/app_theme.dart';

class SensorAlertasScreen extends StatefulWidget {
  final PlantaoApi api;
  final VoidCallback onStatusChanged;

  const SensorAlertasScreen({
    super.key,
    required this.api,
    required this.onStatusChanged,
  });

  @override
  State<SensorAlertasScreen> createState() => _SensorAlertasScreenState();
}

class _SensorAlertasScreenState extends State<SensorAlertasScreen> {
  List<RegiaoModel> _regioes = [];
  List<AlertaModel> _alertas = [];
  int _regiaoId = 1;
  double _nivelSensor = 78;
  bool _enviando = false;
  String? _retorno;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final res = await Future.wait([
      widget.api.listarRegioes(),
      widget.api.listarAlertas(),
    ]);
    if (!mounted) return;
    final regs = res[0] as List<RegiaoModel>;
    setState(() {
      _regioes = regs;
      _alertas = res[1] as List<AlertaModel>;
      if (regs.isNotEmpty && !regs.any((r) => r.id == _regiaoId)) {
        _regiaoId = regs.first.id;
      }
    });
    widget.onStatusChanged();
  }

  Future<void> _enviarSensor() async {
    setState(() => _enviando = true);
    final msg = await widget.api.enviarLeituraSensor(_regiaoId, _nivelSensor.round());
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _retorno = msg;
    });
    await _carregar();
  }

  Future<void> _consultarInmet() async {
    setState(() => _enviando = true);
    final msg = await widget.api.consultarInmet();
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _retorno = msg;
    });
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final pct = _nivelSensor.round();
    final isMaximo = pct >= 90;
    final isAlerta = pct >= 70;
    final statusTexto = isMaximo
        ? 'NÍVEL MÁXIMO · TRANSBORDO IMINENTE'
        : isAlerta
            ? 'ALERTA · GERAR RODADA DE CHUVA'
            : 'NÍVEL NORMAL DO CÓRREGO';

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Card interativo FloodGuard
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sensor FloodGuard (Chuva)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isMaximo ? AppColors.critical : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusTexto,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isMaximo ? AppColors.critical : AppColors.inkSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Medidor animado do nível da água
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      width: double.infinity,
                      color: AppColors.canvas,
                      child: Stack(
                        children: [
                          AnimatedFractionallySizedBox(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            widthFactor: (_nivelSensor / 130).clamp(0.02, 1.0),
                            heightFactor: 1,
                            child: Container(
                              color: isMaximo
                                  ? AppColors.critical
                                  : isAlerta
                                      ? const Color(0xFF3F3F46)
                                      : const Color(0xFFA1A1AA),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Text(
                              'Cota de transbordo (gatilho em 70% e 90%)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: pct > 42 ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Slider(
                    value: _nivelSensor,
                    min: 10,
                    max: 130,
                    divisions: 24,
                    activeColor: isMaximo ? AppColors.critical : AppColors.ink,
                    onChanged: (v) => setState(() => _nivelSensor = v),
                  ),
                  if (_regioes.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      initialValue: _regiaoId,
                      decoration: const InputDecoration(labelText: 'Região do sensor'),
                      items: _regioes
                          .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.nome} — ${r.cidade}/${r.uf}')))
                          .toList(),
                      onChanged: (v) => setState(() => _regiaoId = v ?? _regiaoId),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: _enviando ? null : _enviarSensor,
                          child: Text(_enviando ? 'Enviando...' : 'Enviar leitura'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _enviando ? null : _consultarInmet,
                        child: const Text('Consultar INMET'),
                      ),
                    ],
                  ),
                  if (_retorno != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.subtle,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderStrong),
                      ),
                      child: Text(_retorno!, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Alertas registrados (${_alertas.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._alertas.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  title: Text(
                    '${a.tipo} · ${a.nivel}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: a.nivel == 'MAXIMO' ? AppColors.critical : AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    '${a.fonteAviso.isNotEmpty ? a.fonteAviso : a.origem}\nData: ${a.dataAlerta}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    a.tempMax != null ? '${a.tempMax!.toStringAsFixed(1)}°C' : a.origem,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
