import 'package:flutter/material.dart';
import '../models/plantao_models.dart';
import '../services/plantao_api.dart';
import '../theme/app_theme.dart';

class IdososScreen extends StatefulWidget {
  final PlantaoApi api;
  final VoidCallback onStatusChanged;

  const IdososScreen({
    super.key,
    required this.api,
    required this.onStatusChanged,
  });

  @override
  State<IdososScreen> createState() => _IdososScreenState();
}

class _IdososScreenState extends State<IdososScreen> {
  List<IdosoModel> _idosos = [];
  List<RegiaoModel> _regioes = [];
  String _busca = '';
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final res = await Future.wait([
      widget.api.listarIdosos(),
      widget.api.listarRegioes(),
    ]);
    if (!mounted) return;
    setState(() {
      _idosos = res[0] as List<IdosoModel>;
      _regioes = res[1] as List<RegiaoModel>;
      _carregando = false;
    });
    widget.onStatusChanged();
  }

  void _abrirCadastro() {
    final nomeCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final anoCtrl = TextEditingController(text: '1948');
    final endCtrl = TextEditingController();
    int regiaoId = _regioes.isNotEmpty ? _regioes.first.id : 1;
    bool cronica = false;
    bool semVent = false;
    bool mobRed = false;
    bool areaRisco = false;
    bool lgpd = true;

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
                const Text(
                  'Cadastrar idoso (dados mínimos LGPD)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: telCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Telefone (DDD + número) *', hintText: '11988887777'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: anoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ano nasc. *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: regiaoId,
                  decoration: const InputDecoration(labelText: 'Região'),
                  items: _regioes
                      .map((r) => DropdownMenuItem(value: r.id, child: Text('${r.nome} (${r.cidade})')))
                      .toList(),
                  onChanged: (v) => setModal(() => regiaoId = v ?? regiaoId),
                ),
                const SizedBox(height: 10),
                TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'Endereço resumido')),
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.ink,
                  title: const Text('Doença crônica (peso Calor)'),
                  value: cronica,
                  onChanged: (v) => setModal(() => cronica = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.ink,
                  title: const Text('Casa sem ventilação (peso Calor)'),
                  value: semVent,
                  onChanged: (v) => setModal(() => semVent = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.ink,
                  title: const Text('Área de risco / alagamento (peso Chuva)'),
                  value: areaRisco,
                  onChanged: (v) => setModal(() => areaRisco = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.ink,
                  title: const Text('Mobilidade reduzida (peso Chuva)'),
                  value: mobRed,
                  onChanged: (v) => setModal(() => mobRed = v ?? false),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.ink,
                  title: const Text('Consentimento LGPD registrado *', style: TextStyle(fontWeight: FontWeight.w600)),
                  value: lgpd,
                  onChanged: (v) => setModal(() => lgpd = v ?? false),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (nomeCtrl.text.trim().length < 2 || !lgpd) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe nome, telefone válido e consentimento LGPD.')),
                        );
                        return;
                      }
                      final telDigits = telCtrl.text.replaceAll(RegExp(r'\D'), '');
                      try {
                        await widget.api.salvarIdoso({
                          'idRegiao': '$regiaoId',
                          'nome': nomeCtrl.text.trim(),
                          'anoNascimento': anoCtrl.text.trim(),
                          'telefone': telDigits,
                          'enderecoRef': endCtrl.text.trim(),
                          'moraSozinho': 'S',
                          'condicaoCronica': cronica ? 'S' : 'N',
                          'semVentilacao': semVent ? 'S' : 'N',
                          'mobilidadeReduzida': mobRed ? 'S' : 'N',
                          'areaRisco': areaRisco ? 'S' : 'N',
                          'consentimentoEm': DateTime.now().toIso8601String().substring(0, 10),
                          'consentidoPor': 'PROPRIO',
                        });
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Idoso salvo com sucesso.')),
                        );
                        _carregar();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceFirst('Exception: ', '')),
                            backgroundColor: AppColors.critical,
                          ),
                        );
                      }
                    },
                    child: const Text('Salvar no banco'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _idosos.where((i) {
      if (_busca.isEmpty) return true;
      final q = _busca.toLowerCase();
      return i.nome.toLowerCase().contains(q) || i.enderecoRef.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo idoso'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              color: AppColors.ink,
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou endereço...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (v) => setState(() => _busca = v.trim()),
                  ),
                  const SizedBox(height: 12),
                  ...filtrados.map((i) {
                    final fatores = <String>[
                      if (i.condicaoCronica) 'Doença crônica',
                      if (i.semVentilacao) 'Sem ventilação',
                      if (i.areaRisco) 'Área de risco',
                      if (i.mobilidadeReduzida) 'Mobilidade reduzida',
                    ];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      i.nome,
                                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    'Nasc. ${i.anoNascimento}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${i.telefonePrincipal} · ${i.enderecoRef}',
                                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _chip('Calor: ${i.riscoCalor}', danger: i.riscoCalor == 'ALTO'),
                                  _chip('Chuva: ${i.riscoChuva}', danger: i.riscoChuva == 'ALTO'),
                                  ...fatores.map((f) => _chip(f)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _chip(String text, {bool danger = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: danger ? AppColors.criticalSoft : AppColors.subtle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: danger ? AppColors.criticalBorder : AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: danger ? AppColors.critical : AppColors.inkSecondary,
        ),
      ),
    );
  }
}
