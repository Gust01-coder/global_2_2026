import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/plantao_models.dart';

/// Cliente HTTP compatível com o Servidor Java + H2 (br.com.fiap.plantao.http.Servidor).
/// Se o servidor Java não estiver acessível, ativa modo demonstração local automaticamente
/// para que o app funcione em qualquer celular, emulador ou navegador.
class PlantaoApi {
  String baseUrl;
  bool online = false;

  // Estado local usado apenas quando o backend Java está offline
  late List<RegiaoModel> _demoRegioes;
  late List<IdosoModel> _demoIdosos;
  late List<AlertaModel> _demoAlertas;
  late List<ChecagemModel> _demoRodada;
  int _seqId = 100;

  PlantaoApi({String? initialUrl})
      : baseUrl = initialUrl ?? _defaultUrl() {
    _initDemo();
  }

  static String _defaultUrl() {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  void _initDemo() {
    _demoRegioes = [
      RegiaoModel(id: 1, nome: 'Vila Esperança', cidade: 'São Paulo', uf: 'SP'),
      RegiaoModel(id: 2, nome: 'Jardim Ribeirinho', cidade: 'São Paulo', uf: 'SP'),
      RegiaoModel(id: 3, nome: 'Centro Histórico', cidade: 'São Paulo', uf: 'SP'),
    ];
    _demoIdosos = [
      IdosoModel(
        id: 1,
        idRegiao: 1,
        nome: 'Dona Maria Aparecida S.',
        anoNascimento: 1941,
        idade: 85,
        telefone: '11981234401',
        telefoneFixo: '',
        enderecoRef: 'Rua das Acácias, 84 - Fundos',
        contatoFamiliar: 'Sobrinha Ana (11) 97111-2233',
        condicaoCronica: true,
        semVentilacao: true,
        mobilidadeReduzida: true,
        areaRisco: false,
        riscoCalor: 'ALTO',
        riscoChuva: 'ALTO',
      ),
      IdosoModel(
        id: 2,
        idRegiao: 2,
        nome: 'Seu José Carlos M.',
        anoNascimento: 1945,
        idade: 81,
        telefone: '11981234402',
        telefoneFixo: '',
        enderecoRef: 'Av. Beira Rio, 112 - Térreo',
        contatoFamiliar: 'Filho Marcos (11) 97222-3344',
        condicaoCronica: true,
        semVentilacao: false,
        mobilidadeReduzida: true,
        areaRisco: true,
        riscoCalor: 'ALTO',
        riscoChuva: 'ALTO',
      ),
      IdosoModel(
        id: 3,
        idRegiao: 1,
        nome: 'Dona Helena Ferreira',
        anoNascimento: 1948,
        idade: 78,
        telefone: '11981234403',
        telefoneFixo: '',
        enderecoRef: 'Rua Conselheiro, 55 - Apto 42',
        contatoFamiliar: 'Vizinha Carla (11) 97200-1001',
        condicaoCronica: true,
        semVentilacao: true,
        mobilidadeReduzida: false,
        areaRisco: false,
        riscoCalor: 'ALTO',
        riscoChuva: 'BAIXO',
      ),
      IdosoModel(
        id: 4,
        idRegiao: 3,
        nome: 'Seu Pedro Henrique R.',
        anoNascimento: 1956,
        idade: 70,
        telefone: '11981234406',
        telefoneFixo: '',
        enderecoRef: 'Rua Magnólia, 78 - Casa 2',
        contatoFamiliar: '',
        condicaoCronica: false,
        semVentilacao: false,
        mobilidadeReduzida: false,
        areaRisco: false,
        riscoCalor: 'BAIXO',
        riscoChuva: 'BAIXO',
      ),
    ];
    _demoAlertas = [
      AlertaModel(
        id: 1,
        idRegiao: 1,
        tipo: 'CALOR',
        dataAlerta: DateTime.now().toIso8601String().substring(0, 10),
        nivel: 'MAXIMO',
        tempMax: 38.5,
        origem: 'INMET',
        fonteAviso: 'INMET · Onda de calor El Niño (5°C acima da média)',
      ),
      AlertaModel(
        id: 2,
        idRegiao: 2,
        tipo: 'CHUVA',
        dataAlerta: DateTime.now().toIso8601String().substring(0, 10),
        nivel: 'ALERTA',
        tempMax: 24.0,
        origem: 'FLOODGUARD',
        fonteAviso: 'Sensor FloodGuard: córrego a 78% da cota de transbordo',
      ),
    ];
    _demoRodada = [
      ChecagemModel(
        id: 1,
        idAlerta: 1,
        idIdoso: 1,
        tentativa: 1,
        resultado: 'NAO_ATENDEU',
        observacao: 'Caixa postal no celular',
        nomeVoluntario: 'Carla Souza',
        risco: 'ALTO',
        idoso: _demoIdosos[0],
      ),
      ChecagemModel(
        id: 2,
        idAlerta: 1,
        idIdoso: 1,
        tentativa: 2,
        resultado: 'NAO_ATENDEU',
        observacao: 'Reserva também sem resposta',
        nomeVoluntario: 'Marcos Vinicius',
        risco: 'ALTO',
        idoso: _demoIdosos[0],
      ),
      ChecagemModel(
        id: 3,
        idAlerta: 1,
        idIdoso: 3,
        tentativa: 1,
        resultado: 'PENDENTE',
        observacao: null,
        nomeVoluntario: 'Roberto Almeida',
        risco: 'ALTO',
        idoso: _demoIdosos[2],
      ),
      ChecagemModel(
        id: 4,
        idAlerta: 1,
        idIdoso: 2,
        tentativa: 1,
        resultado: 'ATENCAO',
        observacao: 'Casa abafada; orientada hidratação e retorno em 1h',
        nomeVoluntario: 'Fernanda Lima',
        risco: 'ALTO',
        idoso: _demoIdosos[1],
      ),
      ChecagemModel(
        id: 5,
        idAlerta: 1,
        idIdoso: 4,
        tentativa: 1,
        resultado: 'OK',
        observacao: 'Está bem e hidratado',
        nomeVoluntario: 'Paulo César',
        risco: 'BAIXO',
        idoso: _demoIdosos[3],
      ),
    ];
  }

  Future<dynamic> _get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http.get(uri).timeout(const Duration(seconds: 3));
    final body = utf8.decode(resp.bodyBytes);
    final parsed = jsonDecode(body);
    if (resp.statusCode >= 400) {
      final msg = parsed is Map ? parsed['erro']?.toString() : null;
      throw Exception(msg ?? 'Erro HTTP ${resp.statusCode}');
    }
    online = true;
    return parsed;
  }

  Future<dynamic> _postForm(String path, Map<String, String> fields) async {
    final uri = Uri.parse('$baseUrl$path');
    final resp = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8'},
          body: fields,
        )
        .timeout(const Duration(seconds: 4));
    final body = utf8.decode(resp.bodyBytes);
    final parsed = jsonDecode(body);
    if (resp.statusCode >= 400) {
      final msg = parsed is Map ? parsed['erro']?.toString() : null;
      throw Exception(msg ?? 'Erro HTTP ${resp.statusCode}');
    }
    online = true;
    return parsed;
  }

  Future<bool> testarConexao() async {
    try {
      await _get('/api/regioes');
      online = true;
      return true;
    } catch (_) {
      online = false;
      return false;
    }
  }

  Future<List<RegiaoModel>> listarRegioes() async {
    try {
      final list = await _get('/api/regioes') as List;
      return list.map((e) => RegiaoModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      online = false;
      return _demoRegioes;
    }
  }

  Future<List<AlertaModel>> listarAlertas() async {
    try {
      final list = await _get('/api/alertas') as List;
      return list.map((e) => AlertaModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      online = false;
      return _demoAlertas;
    }
  }

  Future<PainelModel> carregarPainel({int? idAlerta}) async {
    try {
      final q = idAlerta != null ? '?alerta=$idAlerta' : '';
      final map = await _get('/api/painel$q') as Map<String, dynamic>;
      return PainelModel.fromJson(map);
    } catch (_) {
      online = false;
      return _montarPainelDemo(idAlerta);
    }
  }

  PainelModel _montarPainelDemo(int? idAlerta) {
    final alerta = idAlerta != null
        ? _demoAlertas.firstWhere((a) => a.id == idAlerta, orElse: () => _demoAlertas.first)
        : _demoAlertas.first;
    final rodada = _demoRodada.where((c) => c.idAlerta == alerta.id).toList();
    final cont = <String, int>{
      'PENDENTE': 0,
      'OK': 0,
      'ATENCAO': 0,
      'URGENTE': 0,
      'NAO_ATENDEU': 0,
      'CRITICO': 0,
    };
    for (final c in rodada) {
      cont[c.resultado] = (cont[c.resultado] ?? 0) + 1;
    }

    // Crítico: teve NAO_ATENDEU e não tem OK/ATENCAO/URGENTE/PENDENTE
    final criticos = <CriticoModel>[];
    final idsComNaoAtendeu = rodada.where((c) => c.resultado == 'NAO_ATENDEU').map((c) => c.idIdoso).toSet();
    for (final idIdoso in idsComNaoAtendeu) {
      final doIdoso = rodada.where((c) => c.idIdoso == idIdoso).toList();
      final resolvidoOuPendente = doIdoso.any(
        (c) => ['OK', 'ATENCAO', 'URGENTE', 'PENDENTE'].contains(c.resultado),
      );
      if (!resolvidoOuPendente) {
        final ultimo = doIdoso.last;
        criticos.add(CriticoModel(
          idIdoso: ultimo.idIdoso,
          idChecagem: ultimo.id,
          nome: ultimo.idoso.nome,
          telefone: ultimo.idoso.telefone,
          telefoneFixo: ultimo.idoso.telefoneFixo,
          enderecoRef: ultimo.idoso.enderecoRef,
          contatoFamiliar: ultimo.idoso.contatoFamiliar,
        ));
      }
    }
    cont['CRITICO'] = criticos.length;

    return PainelModel(alerta: alerta, contadores: cont, criticos: criticos, rodada: rodada);
  }

  Future<String> registrarChecagem({
    required int idChecagem,
    required String resultado,
    String canal = 'LIGACAO',
    String observacao = '',
  }) async {
    try {
      final map = await _postForm('/api/checagens', {
        'id': '$idChecagem',
        'resultado': resultado,
        'canal': canal,
        'observacao': observacao,
      }) as Map<String, dynamic>;
      return (map['mensagem'] ?? 'Registrado.').toString();
    } catch (e) {
      if (online) rethrow;
      // Fallback local com a mesma regra Titular -> Reserva -> Crítico
      final idx = _demoRodada.indexWhere((c) => c.id == idChecagem);
      if (idx < 0) return 'Checagem não encontrada.';
      final atual = _demoRodada[idx];
      _demoRodada[idx] = ChecagemModel(
        id: atual.id,
        idAlerta: atual.idAlerta,
        idIdoso: atual.idIdoso,
        tentativa: atual.tentativa,
        resultado: resultado,
        observacao: observacao.isEmpty ? atual.observacao : observacao,
        nomeVoluntario: atual.nomeVoluntario,
        risco: atual.risco,
        idoso: atual.idoso,
      );
      if (resultado == 'NAO_ATENDEU' && atual.tentativa == 1) {
        _demoRodada.add(ChecagemModel(
          id: ++_seqId,
          idAlerta: atual.idAlerta,
          idIdoso: atual.idIdoso,
          tentativa: 2,
          resultado: 'PENDENTE',
          observacao: 'Escalonado automaticamente para o reserva',
          nomeVoluntario: 'Marcos Vinicius (Reserva)',
          risco: atual.risco,
          idoso: atual.idoso,
        ));
        return 'Ninguém atendeu. A ligação para ${atual.idoso.nome} foi passada para o voluntário reserva.';
      }
      if (resultado == 'NAO_ATENDEU' && atual.tentativa >= 2) {
        return 'CRÍTICO: ninguém conseguiu falar com ${atual.idoso.nome}. Peça para alguém ir até a casa agora; se ninguém abrir, ligue 193, 192 ou 199.';
      }
      if (resultado == 'URGENTE') {
        return 'Ligue agora 192 (SAMU), 193 (Bombeiros) ou 199 (Defesa Civil).';
      }
      return 'Resultado registrado com sucesso.';
    }
  }

  Future<List<IdosoModel>> listarIdosos() async {
    try {
      final list = await _get('/api/idosos') as List;
      return list.map((e) => IdosoModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      online = false;
      return _demoIdosos;
    }
  }

  Future<void> salvarIdoso(Map<String, String> dados) async {
    try {
      await _postForm('/api/idosos', dados);
    } catch (e) {
      if (online) rethrow;
      final ano = int.tryParse(dados['anoNascimento'] ?? '1948') ?? 1948;
      _demoIdosos.add(IdosoModel(
        id: ++_seqId,
        idRegiao: int.tryParse(dados['idRegiao'] ?? '1') ?? 1,
        nome: dados['nome'] ?? '',
        anoNascimento: ano,
        idade: DateTime.now().year - ano,
        telefone: dados['telefone'] ?? '',
        telefoneFixo: '',
        enderecoRef: dados['enderecoRef'] ?? '',
        contatoFamiliar: dados['contatoFamiliar'] ?? '',
        condicaoCronica: dados['condicaoCronica'] == 'S',
        semVentilacao: dados['semVentilacao'] == 'S',
        mobilidadeReduzida: dados['mobilidadeReduzida'] == 'S',
        areaRisco: dados['areaRisco'] == 'S',
        riscoCalor: dados['condicaoCronica'] == 'S' || dados['semVentilacao'] == 'S' ? 'ALTO' : 'MEDIO',
        riscoChuva: dados['areaRisco'] == 'S' ? 'ALTO' : 'BAIXO',
      ));
    }
  }

  Future<String> enviarLeituraSensor(int idRegiao, int percentual) async {
    try {
      final map = await _postForm('/api/sensor', {
        'idRegiao': '$idRegiao',
        'percentual': '$percentual',
      }) as Map<String, dynamic>;
      return (map['mensagem'] ?? 'Leitura registrada.').toString();
    } catch (_) {
      online = false;
      if (percentual < 70) {
        return 'Nível normal: $percentual% da cota de transbordo. Nenhum alerta.';
      }
      final nivel = percentual >= 90 ? 'MAXIMO' : 'ALERTA';
      final novo = AlertaModel(
        id: ++_seqId,
        idRegiao: idRegiao,
        tipo: 'CHUVA',
        dataAlerta: DateTime.now().toIso8601String().substring(0, 10),
        nivel: nivel,
        tempMax: null,
        origem: 'FLOODGUARD',
        fonteAviso: 'Sensor FloodGuard: córrego a $percentual% da cota de transbordo',
      );
      _demoAlertas.insert(0, novo);
      for (final idoso in _demoIdosos.where((i) => i.idRegiao == idRegiao)) {
        _demoRodada.add(ChecagemModel(
          id: ++_seqId,
          idAlerta: novo.id,
          idIdoso: idoso.id,
          tentativa: 1,
          resultado: 'PENDENTE',
          observacao: null,
          nomeVoluntario: 'Fernanda Lima',
          risco: idoso.riscoChuva,
          idoso: idoso,
        ));
      }
      return 'Alerta de chuva ($nivel) ativo via FloodGuard ($percentual%). Rodada gerada automaticamente.';
    }
  }

  Future<String> consultarInmet() async {
    try {
      final map = await _postForm('/api/inmet', {}) as Map<String, dynamic>;
      return (map['mensagem'] ?? 'Consulta ao INMET concluída.').toString();
    } catch (_) {
      online = false;
      return 'Modo demonstração local: conecte ao servidor Java para consultar a API ao vivo do INMET.';
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> carregarRelatorios() async {
    try {
      final cob = (await _get('/api/relatorios/cobertura') as List).cast<Map<String, dynamic>>();
      final furos = (await _get('/api/relatorios/furos') as List).cast<Map<String, dynamic>>();
      final vols = (await _get('/api/relatorios/voluntarios') as List).cast<Map<String, dynamic>>();
      return {'cobertura': cob, 'furos': furos, 'voluntarios': vols};
    } catch (_) {
      online = false;
      return {
        'cobertura': [
          {
            'regiao': 'Vila Esperança',
            'cidade': 'São Paulo',
            'tipo': 'CALOR',
            'nivel': 'MAXIMO',
            'idosos_ativos': 4,
            'contatados_ate_4h': 2,
            'criticos': 1,
            'pct_ate_4h': 50.0,
          },
        ],
        'furos': [
          {'regiao': 'Jardim Ribeirinho', 'idoso': 'Dona Tereza Lima', 'cuidadores_ativos': 1},
          {'regiao': 'Centro Histórico', 'idoso': 'Seu Oswaldo Mendes', 'cuidadores_ativos': 0},
        ],
        'voluntarios': [
          {'voluntario': 'Carla Souza', 'tipo': 'Vizinha', 'ligacoes_feitas': 3, 'nao_atendeu': 1, 'pct_nao_atendeu': 33.3},
          {'voluntario': 'Fernanda Lima', 'tipo': 'Agente de Saúde', 'ligacoes_feitas': 4, 'nao_atendeu': 0, 'pct_nao_atendeu': 0.0},
        ],
      };
    }
  }
}
