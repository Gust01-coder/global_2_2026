# Plantão Clima — App Mobile (Flutter) para Voluntários

Versão mobile complementar (Flutter 3) voltada ao **voluntário e coordenador comunitário em campo**, conectada diretamente à API Java + H2 (`br.com.fiap.plantao.http.Servidor`) da branch `versao-gabriel`.

> **Atenção à regra da FIAP GS 2026/2:** O idoso **não usa aplicativo** (apenas atende o telefone). Além disso, Flutter é um **módulo extra de demonstração** — para a avaliação principal da disciplina (conteúdo até a Fase 7), o requisito Web oficial continua sendo a pasta `web/` em HTML, CSS, Bootstrap e JS.

## Telas do App Mobile

1. **Rodada do Dia:** fila de ligações ordenada por risco (`ALTO` → `MÉDIO` → `BAIXO`), banner de casos **CRÍTICO** no topo com discagem rápida (`192`, `193`, `199`), checklist de Calor/Chuva e escalonamento automático (`Titular → Reserva → Crítico`).
2. **Idosos:** busca, badges de risco de Calor e Chuva e cadastro rápido com dados mínimos (ano de nascimento + consentimento LGPD).
3. **Sensor FloodGuard & INMET:** simulador interativo de nível do córrego (`0%` a `130%`) conectado a `POST /api/sensor` + botão `Consultar INMET` (`POST /api/inmet`).
4. **Relatórios & Servidor:** relatórios SQL ao vivo (`R1 Cobertura ≤ 4h`, `R2 Furos na rede`, `R3 Carga dos voluntários`) + configuração do IP do servidor Java na rede Wi-Fi.

## Como rodar

1. Suba o servidor Java + H2 na pasta raiz da branch:
   ```bash
   java -cp "target/classes;lib/*" br.com.fiap.plantao.App
   ```
2. Em outro terminal, rode o app Flutter:
   ```bash
   cd mobile_flutter
   flutter pub get
   flutter run -d chrome      # ou -d windows / dispositivo Android conectado
   ```
*(Se o servidor Java estiver desligado, o app entra automaticamente em **Demo Local** com dados de exemplo.)*
