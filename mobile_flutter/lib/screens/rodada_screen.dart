import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plantao_models.dart';
import '../services/plantao_api.dart';
import '../theme/app_theme.dart';

class RodadaScreen extends StatefulWidget {
  final PlantaoApi api;
  final VoidCallback onStatusChanged;

  const RodadaScreen({
    super.key,
    required this.api,
    required this.onStatusChanged,
  });

  @override
  State<RodadaScreen> createState() => _RodadaScreenState();
}

class _RodadaScreenState extends State<RodadaScreen> {
  List<AlertaModel> _alertas = [];
  PainelModel? _painel;
  int? _alertaId;
  bool _carregando = true;
  String _filtro = 'TODOS';

  static const _checklistCalor = [
    'Orientado a beber água fresca aos goles',
    'Casa abafada ou sem ventilação adequada',
    'Ventilador ligado / janelas abertas na sombra',
    'Relatou tontura, fraqueza ou dor de cabeça',
    'Medicações de uso contínuo em dia',
  ];

  static const _checklistChuva = [
    'Rua ou acesso com risco de alagamento',
    'Água entrando na casa ou goteira grave',
    'Documentos e remédios separados em local seco',
    'Ponto seguro combinado com vizinho/familiar',
    'Energia elétrica e telefone funcionando',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({int? alertaId}) async {
    setState(() => _carregando = true);
    final alertas = await widget.api.listarAlertas();
    final escolhido = alertaId ?? _alertaId ?? (alertas.isNotEmpty ? alertas.first.id : null);
    final painel = await widget.api.carregarPainel(idAlerta: escolhido);
    if (!mounted) return;
    setState(() {
      _alertas = alertas;
      _alertaId = painel.alerta?.id ?? escolhido;
      _painel = painel;
      _carregando = false;
    });
    widget.onStatusChanged();
  }

  Future<void> _registrar(
    ChecagemModel ch,
    String resultado, {
    String observacao = '',
  }) async {
    try {
      final msg = await widget.api.registrarChecagem(
        idChecagem: ch.id,
        resultado: resultado,
        observacao: observacao,
      );
      if (!mounted) return;
      final critico = msg.toUpperCase().contains('CRÍTICO') || resultado == 'URGENTE';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: critico ? AppColors.critical : AppColors.ink,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      await _carregar(alertaId: _alertaId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.critical,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _abrirChecklist(ChecagemModel ch, String tipoAlerta) {
    final itens = tipoAlerta == 'CHUVA' ? _checklistChuva : _checklistCalor;
    final marcados = <String>{};
    final obsCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checklist · ${tipoAlerta == 'CHUVA' ? 'Chuva Forte' : 'Calor Extremo'}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  ch.idoso.nome,
                  style: const TextStyle(color: AppColors.inkSecondary, fontSize: 13),
                ),
                const Divider(height: 20),
                ...itens.map(
                  (item) => CheckboxListTile(
                    value: marcados.contains(item),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.ink,
                    title: Text(item, style: const TextStyle(fontSize: 13.5)),
                    onChanged: (v) => setModal(() {
                      if (v == true) {
                        marcados.add(item);
                      } else {
                        marcados.remove(item);
                      }
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Observação da ligação',
                    hintText: 'Ex.: Retornar em 1 hora para acompanhar',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final resumo = [
                        ...marcados,
                        if (obsCtrl.text.trim().isNotEmpty) obsCtrl.text.trim(),
                      ].join('; ');
                      _registrar(ch, 'ATENCAO', observacao: resumo);
                    },
                    child: const Text('Registrar "Precisa de atenção"'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirEmergencia(ChecagemModel ch, String tipoAlerta) {
    final obsCtrl = TextEditingController();
    final isChuva = tipoAlerta == 'CHUVA';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EMERGÊNCIA · ACIONE AJUDA IMEDIATA',
              style: TextStyle(
                color: AppColors.critical,
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${ch.idoso.nome} · ${ch.idoso.enderecoRef}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              isChuva
                  ? 'Prioridade em chuva/alagamento: ligue 193 (Bombeiros) ou 199 (Defesa Civil). Se houver mal-estar, ligue 192 (SAMU).'
                  : 'Prioridade em calor extremo: ligue 192 (SAMU). Enquanto aguarda: local fresco, água aos goles, roupa leve.',
              style: const TextStyle(color: AppColors.inkSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _emergChip('SAMU 192', '192'),
                _emergChip('Bombeiros 193', '193'),
                _emergChip('Defesa Civil 199', '199'),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Ocorrido para a coordenação',
                hintText: 'Ex.: Relatou falta de ar, 192 acionado',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
                onPressed: () {
                  Navigator.pop(ctx);
                  _registrar(
                    ch,
                    'URGENTE',
                    observacao: obsCtrl.text.trim().isEmpty
                        ? 'Pedido de ajuda urgente registrado no app.'
                        : obsCtrl.text.trim(),
                  );
                },
                child: const Text('Confirmar registro de ajuda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergChip(String label, String numero) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.critical,
        side: const BorderSide(color: AppColors.criticalBorder),
      ),
      icon: const Icon(Icons.call, size: 16),
      label: Text(label),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: numero));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Número $numero copiado para o discador.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final painel = _painel;
    final alerta = painel?.alerta;
    final cont = painel?.contadores ?? {};
    final rodada = (painel?.rodada ?? []).where((c) {
      if (_filtro == 'TODOS') return true;
      return c.resultado == _filtro;
    }).toList();

    return RefreshIndicator(
      color: AppColors.ink,
      onRefresh: () => _carregar(alertaId: _alertaId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Seletor de alerta
          if (_alertas.isNotEmpty) ...[
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _alertas.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, idx) {
                  final a = _alertas[idx];
                  final sel = a.id == _alertaId;
                  return ChoiceChip(
                    selected: sel,
                    selectedColor: AppColors.ink,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.borderStrong),
                    label: Text(
                      '${a.tipo} · ${a.nivel} (${a.origem})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.ink,
                      ),
                    ),
                    onSelected: (_) => _carregar(alertaId: a.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Régua limpa de contadores
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _metricCell('CRÍTICOS', cont['CRITICO'] ?? 0, isDanger: (cont['CRITICO'] ?? 0) > 0),
                _metricDivider(),
                _metricCell('PENDENTES', cont['PENDENTE'] ?? 0),
                _metricDivider(),
                _metricCell('ATENÇÃO', cont['ATENCAO'] ?? 0),
                _metricDivider(),
                _metricCell('ESTÃO BEM', cont['OK'] ?? 0),
              ],
            ),
          ),

          // Casos críticos no topo
          if (painel != null && painel.criticos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.criticalBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.criticalSoft,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                    ),
                    child: const Text(
                      'CRÍTICO · SEM RESPOSTA (ENVIAR VISITA · 192 / 193 / 199)',
                      style: TextStyle(
                        color: AppColors.critical,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  ...painel.criticos.map(
                    (cr) => Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cr.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(cr.enderecoRef, style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
                          if (cr.contatoFamiliar.isNotEmpty)
                            Text('Familiar: ${cr.contatoFamiliar}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _emergChip('Ligar ${cr.telefonePrincipal}', cr.telefonePrincipal),
                              _emergChip('192', '192'),
                              _emergChip('193', '193'),
                              _emergChip('199', '199'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Filtros da rodada
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fila de ligações (${rodada.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              DropdownButton<String>(
                value: _filtro,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 12.5, color: AppColors.ink, fontWeight: FontWeight.w600),
                items: const [
                  DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                  DropdownMenuItem(value: 'PENDENTE', child: Text('Pendentes')),
                  DropdownMenuItem(value: 'ATENCAO', child: Text('Atenção')),
                  DropdownMenuItem(value: 'OK', child: Text('Estão bem')),
                  DropdownMenuItem(value: 'NAO_ATENDEU', child: Text('Não atendeu')),
                ],
                onChanged: (v) => setState(() => _filtro = v ?? 'TODOS'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (rodada.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('Nenhuma ligação neste filtro.', style: TextStyle(color: AppColors.inkMuted)),
                ),
              ),
            )
          else
            ...rodada.map((ch) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildChecagemCard(ch, alerta?.tipo ?? 'CALOR'),
                )),
        ],
      ),
    );
  }

  Widget _metricCell(String label, int value, {bool isDanger = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDanger ? AppColors.critical : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricDivider() => Container(width: 1, height: 32, color: AppColors.border);

  Widget _buildChecagemCard(ChecagemModel ch, String tipoAlerta) {
    final isUrgente = ch.resultado == 'URGENTE';
    final isPendente = ch.resultado == 'PENDENTE';
    final isReserva = ch.tentativa >= 2;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isUrgente ? AppColors.critical : AppColors.border,
          width: isUrgente ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _tag(
                  'RISCO ${ch.risco}',
                  danger: ch.risco == 'ALTO',
                ),
                const SizedBox(width: 6),
                _tag(
                  isReserva ? 'RESERVA (2ª)' : 'TITULAR (1ª)',
                ),
                const Spacer(),
                _tag(
                  _labelResultado(ch.resultado),
                  danger: isUrgente || ch.resultado == 'NAO_ATENDEU',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ch.idoso.nome,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Nasc. ${ch.idoso.anoNascimento} (${ch.idoso.idade} anos) · ${ch.idoso.enderecoRef}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Voluntário: ${ch.nomeVoluntario} · Tel. idoso: ${ch.idoso.telefonePrincipal}',
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
            if (ch.observacao != null && ch.observacao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(ch.observacao!, style: const TextStyle(fontSize: 12.5)),
              ),
            ],
            const SizedBox(height: 12),
            // 4 ações rápidas com botões grandes (acessível no celular)
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isPendente ? AppColors.ink : const Color(0xFF3F3F46),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: () => _registrar(ch, 'OK', observacao: 'Está bem.'),
                    child: const Text('Está bem', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    onPressed: () => _abrirChecklist(ch, tipoAlerta),
                    child: const Text('Atenção', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.critical,
                      side: const BorderSide(color: AppColors.criticalBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: () => _abrirEmergencia(ch, tipoAlerta),
                    child: const Text('Precisa ajuda (192)', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)),
                    onPressed: () => _registrar(ch, 'NAO_ATENDEU', observacao: 'Sem resposta na ligação.'),
                    child: const Text('Não atendeu', style: TextStyle(fontSize: 12.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: danger ? AppColors.criticalSoft : AppColors.subtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: danger ? AppColors.criticalBorder : AppColors.borderStrong),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: danger ? AppColors.critical : AppColors.ink,
        ),
      ),
    );
  }

  String _labelResultado(String r) {
    switch (r) {
      case 'OK':
        return 'ESTÁ BEM';
      case 'ATENCAO':
        return 'ATENÇÃO';
      case 'URGENTE':
        return 'AJUDA (192)';
      case 'NAO_ATENDEU':
        return 'NÃO ATENDEU';
      default:
        return 'PENDENTE';
    }
  }
}
