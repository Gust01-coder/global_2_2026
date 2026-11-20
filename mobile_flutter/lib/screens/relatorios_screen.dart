import 'package:flutter/material.dart';
import '../services/plantao_api.dart';
import '../theme/app_theme.dart';

class RelatoriosScreen extends StatefulWidget {
  final PlantaoApi api;
  final VoidCallback onStatusChanged;

  const RelatoriosScreen({
    super.key,
    required this.api,
    required this.onStatusChanged,
  });

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  late TextEditingController _urlCtrl;
  Map<String, List<Map<String, dynamic>>> _dados = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: widget.api.baseUrl);
    _carregar();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final rel = await widget.api.carregarRelatorios();
    if (!mounted) return;
    setState(() {
      _dados = rel;
      _carregando = false;
    });
    widget.onStatusChanged();
  }

  Future<void> _salvarUrl() async {
    widget.api.baseUrl = _urlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');
    final ok = await widget.api.testarConexao();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Conectado ao servidor Java + H2 em ${widget.api.baseUrl}'
              : 'Servidor não respondeu. Mantido em modo demonstração local.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final cobertura = _dados['cobertura'] ?? [];
    final furos = _dados['furos'] ?? [];
    final voluntarios = _dados['voluntarios'] ?? [];

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Configuração de conexão com o servidor Java do Gabriel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conexão com o servidor Java + H2',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'No celular na mesma rede Wi-Fi, informe o IP exibido no terminal do Java (ex.: http://192.168.0.15:8080).',
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL da API Java',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _salvarUrl,
                        child: const Text('Conectar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_carregando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            _tituloSecao('R1 · Cobertura em até 4h (agregado UBS, sem nomes)'),
            if (cobertura.isEmpty)
              _vazio('Nenhum alerta com rodada hoje.')
            else
              ...cobertura.map((r) {
                final pct = (r['pct_ate_4h'] as num?)?.toDouble() ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${r['regiao']} · ${r['tipo']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (pct / 100).clamp(0, 1),
                            backgroundColor: AppColors.canvas,
                            color: AppColors.ink,
                            minHeight: 6,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ativos: ${r['idosos_ativos']} · Contatados ≤4h: ${r['contatados_ate_4h']} · Críticos: ${r['criticos']}',
                            style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            const SizedBox(height: 14),
            _tituloSecao('R2 · Furos na rede (menos de 2 cuidadores)'),
            if (furos.isEmpty)
              _vazio('Todos os idosos têm Titular e Reserva.')
            else
              Card(
                child: Column(
                  children: furos
                      .map((f) => ListTile(
                            dense: true,
                            title: Text('${f['idoso']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${f['regiao']}'),
                            trailing: Text(
                              '${f['cuidadores_ativos']} cuidador(es)',
                              style: const TextStyle(
                                color: AppColors.critical,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 14),
            _tituloSecao('R3 · Taxa de "não atendeu" por voluntário'),
            if (voluntarios.isEmpty)
              _vazio('Sem ligações registradas ainda.')
            else
              Card(
                child: Column(
                  children: voluntarios
                      .map((v) => ListTile(
                            dense: true,
                            title: Text('${v['voluntario']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${v['tipo']} · ${v['ligacoes_feitas']} ligação(ões) · ${v['nao_atendeu']} sem resposta',
                            ),
                            trailing: Text(
                              '${v['pct_nao_atendeu'] ?? 0}%',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _tituloSecao(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      );

  Widget _vazio(String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
        ),
      );
}
