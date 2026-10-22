# Monitor de Ruído IoT

## Roteiro de apresentação

### Slide 1 — Capa

**Monitor de Ruído IoT**  
Aplicativo Android para acompanhamento inteligente de ambientes monitorados

Projeto Integrador — UNIVESP  
Equipe: _preencher nomes_  
Data: _preencher data_

**Mensagem-chave:** transformar dados técnicos de sensores em informação clara
para tomada de decisão.

### Slide 2 — Problema

- O ruído em ambientes compartilhados é difícil de acompanhar continuamente.
- Leituras brutas de sensores não são intuitivas para usuários comuns.
- Alertas precisam considerar contexto, especialmente o horário de silêncio.
- Falhas temporárias de rede não devem apagar a última informação conhecida.

**Pergunta norteadora:** como monitorar o ambiente em tempo quase real sem
exigir conhecimento técnico do usuário?

### Slide 3 — Objetivo do projeto

Desenvolver um aplicativo Android que:

- consuma os dados disponibilizados pelo servidor local;
- apresente o nível de ruído em linguagem simples;
- identifique casas barulhentas e sensores sem sinal;
- exiba histórico diário e evolução por hora;
- continue útil durante instabilidades temporárias de rede.

### Slide 4 — Visão geral da solução

```text
Sensores ESP32
      │ Wi-Fi
      ▼
Servidor local em Docker
FastAPI + regras + dados
      │ HTTP/JSON
      ▼
Aplicativo Android Flutter
interpretação + visualização + cache
```

O aplicativo é somente leitor: não grava áudio, não envia comandos aos sensores
e não altera as medições no servidor.

### Slide 5 — Como o sistema funciona

1. O sensor realiza medições do ambiente.
2. O servidor recebe e processa os dados.
3. A API disponibiliza um overview das casas.
4. O aplicativo consulta o overview a cada 5 segundos.
5. O usuário visualiza o estado atual, alertas e sensores offline.
6. Ao abrir uma casa, o aplicativo consulta o histórico diário.
7. Respostas válidas são armazenadas localmente para contingência.

### Slide 6 — Arquitetura do aplicativo

| Camada | Responsabilidade |
|---|---|
| `main.dart` | Inicialização e decisão da tela inicial |
| `api.dart` | Cliente HTTP, modelos e parsing do JSON |
| `settings.dart` | Endereço salvo e cache persistente |
| `noise_ui.dart` | Tema, níveis, cores e componentes reutilizáveis |
| `screens/` | Conexão, overview, detalhe e ajuda |
| `test/` | Testes de widgets e parsing |

**Princípio:** separar comunicação, domínio visual, persistência e interface
para reduzir acoplamento e facilitar manutenção.

### Slide 7 — Experiência do usuário

**Fluxo principal**

1. Informar o IP do computador.
2. Testar a conexão antes de salvar.
3. Visualizar o resumo do prédio.
4. Selecionar uma casa.
5. Consultar o gráfico e o resumo do dia.

**Linguagem simples**

- `baixo` → **Tranquilo**
- `medio` → **Movimento normal**
- `alto` → **Barulhento**
- `muito_alto` → **Muito alto**

### Slide 8 — Horário de silêncio e alertas

- O servidor informa se o período de silêncio está ativo.
- O aplicativo mostra a próxima mudança de período.
- Ruído alto durante o silêncio gera alerta visual.
- Ruído baixo ou médio não gera alerta.
- Sensores offline são apresentados separadamente para não confundir
  ausência de dados com ambiente silencioso.

**Decisão de produto:** priorizar entendimento imediato em vez de expor
detalhes técnicos de RMS ou do protocolo do sensor.

### Slide 9 — Histórico e visualização

O detalhe de cada casa apresenta:

- estado atual;
- tempo desde a última leitura;
- gráfico com 24 intervalos horários;
- média de intensidade por hora;
- pior nível registrado no período;
- duração aproximada do ruído;
- quantidade de medições recebidas.

As faixas azuladas destacam os horários de silêncio e ajudam a relacionar
intensidade e contexto.

### Slide 10 — Resiliência e confiabilidade

**Problema:** a rede local pode falhar, mesmo que o aplicativo esteja correto.

**Solução implementada:**

- timeout de 6 segundos;
- mensagens de erro orientadas ao usuário;
- manutenção do último estado em memória;
- cache persistente do overview;
- cache persistente do histórico por sensor;
- indicação da idade dos dados exibidos.

**Resultado:** uma falha temporária não transforma a tela em um estado vazio.

### Slide 11 — Qualidade e automação

O projeto possui:

- parsing defensivo para respostas incompletas;
- testes de normalização de URL;
- testes de parsing do overview;
- teste para tipos inválidos e campos opcionais;
- `flutter analyze`;
- `flutter test`;
- workflow de GitHub Actions;
- geração automatizada do APK release.

**Pipeline:** instalar dependências → analisar → testar → compilar → publicar
artefato.

### Slide 12 — Segurança e limitações

**Limitações atuais**

- o backend e o contrato completo da API são componentes externos;
- a solução foi projetada para rede local;
- HTTP sem TLS é permitido no cenário local;
- os níveis não são medição oficial ou certificada em decibéis;
- autenticação e autorização ainda são necessárias para exposição externa.

**Boa prática:** antes de publicar fora da rede confiável, adotar HTTPS,
autenticação, controle de acesso, validação do servidor e revisão de segurança.

### Slide 13 — Resultados alcançados

- Aplicativo Android estruturado em Flutter.
- Integração definida com a API do servidor.
- Visão geral das casas e detalhe por sensor.
- Alertas contextualizados pelo horário de silêncio.
- Histórico visual por hora.
- Funcionamento tolerante a falhas temporárias.
- Processo documentado de análise, testes e geração do APK.

### Slide 14 — Próximos passos

1. Integrar e versionar formalmente o contrato da API.
2. Executar testes em dispositivo Android real com quatro sensores.
3. Adicionar testes de integração com servidor simulado.
4. Melhorar acessibilidade e internacionalização.
5. Adotar HTTPS e autenticação para ambientes externos.
6. Publicar versões assinadas e estabelecer monitoramento operacional.

### Slide 15 — Encerramento

**Conclusão**

O projeto transforma medições de ruído em uma experiência simples, visual e
acionável, preservando a utilidade do aplicativo mesmo quando a rede apresenta
instabilidade.

**Obrigado.**

Perguntas?

