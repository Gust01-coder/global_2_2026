class RegiaoModel {
  final int id;
  final String nome;
  final String cidade;
  final String uf;

  RegiaoModel({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.uf,
  });

  factory RegiaoModel.fromJson(Map<String, dynamic> j) => RegiaoModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nome: (j['nome'] ?? '').toString(),
        cidade: (j['cidade'] ?? '').toString(),
        uf: (j['uf'] ?? '').toString(),
      );
}

class IdosoModel {
  final int id;
  final int idRegiao;
  final String nome;
  final int anoNascimento;
  final int idade;
  final String telefone;
  final String telefoneFixo;
  final String enderecoRef;
  final String contatoFamiliar;
  final bool condicaoCronica;
  final bool semVentilacao;
  final bool mobilidadeReduzida;
  final bool areaRisco;
  final String riscoCalor;
  final String riscoChuva;

  IdosoModel({
    required this.id,
    required this.idRegiao,
    required this.nome,
    required this.anoNascimento,
    required this.idade,
    required this.telefone,
    required this.telefoneFixo,
    required this.enderecoRef,
    required this.contatoFamiliar,
    required this.condicaoCronica,
    required this.semVentilacao,
    required this.mobilidadeReduzida,
    required this.areaRisco,
    required this.riscoCalor,
    required this.riscoChuva,
  });

  factory IdosoModel.fromJson(Map<String, dynamic> j) {
    final ano = (j['anoNascimento'] as num?)?.toInt() ?? 1945;
    return IdosoModel(
      id: (j['id'] as num?)?.toInt() ?? 0,
      idRegiao: (j['idRegiao'] as num?)?.toInt() ?? 1,
      nome: (j['nome'] ?? '').toString(),
      anoNascimento: ano,
      idade: (j['idade'] as num?)?.toInt() ?? (DateTime.now().year - ano),
      telefone: (j['telefone'] ?? '').toString(),
      telefoneFixo: (j['telefoneFixo'] ?? '').toString(),
      enderecoRef: (j['enderecoRef'] ?? '').toString(),
      contatoFamiliar: (j['contatoFamiliar'] ?? '').toString(),
      condicaoCronica: j['condicaoCronica'] == true,
      semVentilacao: j['semVentilacao'] == true,
      mobilidadeReduzida: j['mobilidadeReduzida'] == true,
      areaRisco: j['areaRisco'] == true,
      riscoCalor: (j['riscoCalor'] ?? 'MEDIO').toString(),
      riscoChuva: (j['riscoChuva'] ?? 'MEDIO').toString(),
    );
  }

  String get telefonePrincipal => telefone.isNotEmpty ? telefone : telefoneFixo;
}

class AlertaModel {
  final int id;
  final int idRegiao;
  final String tipo; // CALOR | CHUVA
  final String dataAlerta;
  final String nivel; // OBSERVACAO | ATENCAO | ALERTA | MAXIMO
  final double? tempMax;
  final String origem;
  final String fonteAviso;

  AlertaModel({
    required this.id,
    required this.idRegiao,
    required this.tipo,
    required this.dataAlerta,
    required this.nivel,
    required this.tempMax,
    required this.origem,
    required this.fonteAviso,
  });

  factory AlertaModel.fromJson(Map<String, dynamic> j) => AlertaModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        idRegiao: (j['idRegiao'] as num?)?.toInt() ?? 1,
        tipo: (j['tipo'] ?? 'CALOR').toString(),
        dataAlerta: (j['dataAlerta'] ?? '').toString(),
        nivel: (j['nivel'] ?? 'ALERTA').toString(),
        tempMax: (j['tempMax'] as num?)?.toDouble(),
        origem: (j['origem'] ?? 'MANUAL').toString(),
        fonteAviso: (j['fonteAviso'] ?? '').toString(),
      );
}

class ChecagemModel {
  final int id;
  final int idAlerta;
  final int idIdoso;
  final int tentativa;
  final String resultado; // PENDENTE | OK | ATENCAO | URGENTE | NAO_ATENDEU
  final String? observacao;
  final String nomeVoluntario;
  final String risco; // ALTO | MEDIO | BAIXO
  final IdosoModel idoso;

  ChecagemModel({
    required this.id,
    required this.idAlerta,
    required this.idIdoso,
    required this.tentativa,
    required this.resultado,
    required this.observacao,
    required this.nomeVoluntario,
    required this.risco,
    required this.idoso,
  });

  factory ChecagemModel.fromJson(Map<String, dynamic> j) => ChecagemModel(
        id: (j['id'] as num?)?.toInt() ?? 0,
        idAlerta: (j['idAlerta'] as num?)?.toInt() ?? 0,
        idIdoso: (j['idIdoso'] as num?)?.toInt() ?? 0,
        tentativa: (j['tentativa'] as num?)?.toInt() ?? 1,
        resultado: (j['resultado'] ?? 'PENDENTE').toString(),
        observacao: j['observacao']?.toString(),
        nomeVoluntario: (j['nomeVoluntario'] ?? 'Voluntário').toString(),
        risco: (j['risco'] ?? 'MEDIO').toString(),
        idoso: IdosoModel.fromJson(
          (j['idoso'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        ),
      );
}

class CriticoModel {
  final int idIdoso;
  final int idChecagem;
  final String nome;
  final String telefone;
  final String telefoneFixo;
  final String enderecoRef;
  final String contatoFamiliar;

  CriticoModel({
    required this.idIdoso,
    required this.idChecagem,
    required this.nome,
    required this.telefone,
    required this.telefoneFixo,
    required this.enderecoRef,
    required this.contatoFamiliar,
  });

  factory CriticoModel.fromJson(Map<String, dynamic> j) => CriticoModel(
        idIdoso: (j['id_idoso'] as num?)?.toInt() ?? 0,
        idChecagem: (j['id_checagem'] as num?)?.toInt() ?? 0,
        nome: (j['nome'] ?? '').toString(),
        telefone: (j['telefone'] ?? '').toString(),
        telefoneFixo: (j['telefone_fixo'] ?? '').toString(),
        enderecoRef: (j['endereco_ref'] ?? '').toString(),
        contatoFamiliar: (j['contato_familiar'] ?? '').toString(),
      );

  String get telefonePrincipal => telefone.isNotEmpty ? telefone : telefoneFixo;
}

class PainelModel {
  final AlertaModel? alerta;
  final Map<String, int> contadores;
  final List<CriticoModel> criticos;
  final List<ChecagemModel> rodada;

  PainelModel({
    required this.alerta,
    required this.contadores,
    required this.criticos,
    required this.rodada,
  });

  factory PainelModel.fromJson(Map<String, dynamic> j) {
    final contRaw = (j['contadores'] as Map<String, dynamic>?) ?? {};
    final cont = contRaw.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
    return PainelModel(
      alerta: j['alerta'] != null
          ? AlertaModel.fromJson(j['alerta'] as Map<String, dynamic>)
          : null,
      contadores: cont,
      criticos: ((j['criticos'] as List?) ?? [])
          .map((e) => CriticoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rodada: ((j['rodada'] as List?) ?? [])
          .map((e) => ChecagemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
