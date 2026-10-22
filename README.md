# Monitor de Ruído IoT — aplicativo Android

Aplicativo Android para acompanhamento de sensores de ruído instalados em
casas ou ambientes monitorados. O aplicativo consome a API do servidor local,
apresenta os dados em linguagem simples e mantém uma cópia local do último
estado conhecido para situações de instabilidade de rede.

> Este repositório contém o aplicativo Flutter. O servidor, o banco de dados,
> os sensores ESP32 e o Dashboard Web são componentes separados do ecossistema.

## Visão geral

```text
ESP32 → Wi-Fi → API FastAPI no Docker → Wi-Fi → Aplicativo Android
```

O aplicativo é somente leitor: não grava áudio, não envia comandos aos
sensores e não altera as medições armazenadas no servidor.

## Funcionalidades

- conexão com o servidor por endereço IP e porta;
- salvamento do endereço do servidor no dispositivo;
- visão geral das casas monitoradas;
- classificação dos níveis: tranquilo, movimento normal, barulhento e muito alto;
- alerta de ruído durante o horário de silêncio;
- identificação de sensores sem sinal;
- histórico diário por casa;
- gráfico de intensidade por hora;
- atualização automática e atualização manual por gesto;
- cache persistente do overview e do histórico;
- tela de ajuda com explicação dos níveis e das limitações da medição.

## Requisitos

### Para executar ou compilar localmente

- Windows, macOS ou Linux;
- Flutter no canal estável;
- Android Studio com Android SDK;
- Android SDK Command-line Tools;
- Git;
- dispositivo Android físico ou emulador para execução.

No Windows, valide o ambiente com:

```bat
flutter doctor -v
```

Se o comando `flutter` não for reconhecido, instale o Flutter e adicione
`flutter\bin` ao `PATH` do usuário. No CMD, use `cd /d`; no PowerShell, use
`Set-Location`.

### Para executar o sistema completo

Além do aplicativo, é necessário ter o servidor local em execução e acessível
na mesma rede Wi-Fi do celular. O servidor deve disponibilizar as rotas:

```text
GET /api/app/overview
GET /api/app/houses/{sensor_id}/history
```

## Estrutura do repositório

```text
.
├── README.md
├── app/
│   ├── README.md
│   ├── pubspec.yaml
│   ├── construir_apk.bat
│   ├── android/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── api.dart
│   │   ├── noise_ui.dart
│   │   ├── settings.dart
│   │   └── screens/
│   └── test/
└── .github/
    └── workflows/
        ├── android.yml
        └── ios.yml
```

## Apresentação do projeto

O material profissional para apresentação à banca está em:

```text
docs/apresentacao-banca.html
docs/apresentacao-banca.md
```

Abra o arquivo HTML no Chrome ou Edge para apresentar em tela cheia. As setas
do teclado navegam entre os slides; o botão **PDF** abre a impressão do
navegador para salvar uma versão em PDF. Antes da banca, substitua os campos
de equipe e data na capa.

### Responsabilidade dos principais arquivos

| Arquivo | Responsabilidade |
|---|---|
| `app/lib/main.dart` | Inicialização do aplicativo e roteamento inicial |
| `app/lib/api.dart` | Cliente HTTP, modelos e parsing das respostas |
| `app/lib/noise_ui.dart` | Tema, cores, textos e componentes visuais reutilizáveis |
| `app/lib/settings.dart` | Preferências e cache local com `SharedPreferences` |
| `app/lib/screens/` | Telas de conexão, overview, detalhe e ajuda |
| `app/test/` | Testes unitários e de widgets |
| `app/construir_apk.bat` | Preparação, validação e geração do APK no Windows |
| `.github/workflows/android.yml` | Análise, testes, build e publicação do artefato |

## Executar em modo desenvolvimento

No **CMD**:

```bat
cd /d "C:\caminho\para\monitor-ruido-android\app"
flutter pub get
flutter analyze
flutter test
flutter run
```

No **PowerShell**:

```powershell
Set-Location -LiteralPath "C:\caminho\para\monitor-ruido-android\app"
flutter pub get
flutter analyze
flutter test
flutter run
```

O comando `flutter run` exige um celular Android conectado com depuração USB
habilitada ou um emulador iniciado.

## Gerar o APK no Windows

A forma recomendada é executar o script com duplo clique:

```text
app\construir_apk.bat
```

O script:

1. localiza automaticamente a pasta `app`;
2. verifica se o Flutter está disponível;
3. completa os arquivos Android com `flutter create`, quando necessário;
4. instala dependências;
5. executa `flutter analyze`;
6. executa `flutter test`;
7. gera o APK em modo release.

O arquivo final estará em:

```text
app\build\app\outputs\flutter-apk\app-release.apk
```

Para evitar problemas de permissão do Windows, prefira manter o projeto em uma
pasta acessível ao usuário, como:

```text
C:\Projetos\monitor-ruido-android
```

O build não deve ser executado a partir de `app\android`; os comandos devem
ser executados na pasta `app`.

## Build pelo GitHub Actions

O workflow `.github/workflows/android.yml` executa automaticamente:

- instalação do Flutter;
- geração da estrutura Android;
- `flutter pub get`;
- `flutter analyze`;
- `flutter test`;
- `flutter build apk --release`;
- upload do APK como artefato `monitor-ruido-apk`.

Para executar manualmente:

1. abra a aba **Actions** no GitHub;
2. selecione **Android app**;
3. clique em **Run workflow**;
4. aguarde a conclusão;
5. baixe o artefato `monitor-ruido-apk`.

O workflow `.github/workflows/ios.yml` executa em macOS, prepara as plataformas
Android/iOS, analisa o projeto, executa os testes e gera um build iOS sem
assinatura. Esse artefato valida a compilação, mas não substitui a assinatura
Apple nem o envio ao TestFlight.

O checklist completo de homologação, assinatura e publicação está em
`docs/RELEASE-CHECKLIST.md`.

## Configuração da conexão

1. Inicie o servidor local.
2. Descubra o endereço IP do computador na rede local.
3. Conecte o celular e o computador ao mesmo Wi-Fi.
4. Abra o aplicativo e informe o endereço do servidor.
5. Informe somente o IP, por exemplo `192.168.0.10`, ou uma URL completa.
6. O aplicativo adicionará a porta `5000` quando nenhuma porta for informada.

Exemplos aceitos:

```text
192.168.0.10
192.168.0.10:5000
http://192.168.0.10:5000
```

Redes de convidados podem impedir a comunicação entre dispositivos. Firewall
do Windows, Docker parado, porta incorreta ou servidor não iniciado também
podem impedir a conexão.

## Cache e comportamento offline

Após uma resposta válida, o aplicativo armazena localmente:

- o último overview recebido;
- o histórico consultado de cada sensor;
- o horário em que cada resposta foi salva.

Se a conexão cair, o aplicativo mantém os dados disponíveis e informa que eles
são antigos. O cache é uma contingência de leitura; não é uma sincronização
bidirecional e não substitui a fonte oficial.

## Limitações conhecidas

- A classificação de ruído depende das regras e dos dados fornecidos pelo
  servidor.
- Os níveis apresentados não são uma medição oficial em decibéis.
- O aplicativo foi projetado para uma API na rede local.
- O manifesto permite HTTP sem TLS para viabilizar o uso local; para exposição
  externa, é necessário adotar HTTPS, autenticação e revisão de segurança.
- O backend e o contrato completo da API não são mantidos neste repositório.

## Critérios de aceite

Uma versão funcional deve:

- instalar em um dispositivo Android real;
- conectar ao servidor pelo IP da rede local;
- exibir as casas e o estado dos sensores;
- indicar alertas durante o horário de silêncio;
- abrir o histórico de cada casa;
- continuar exibindo o último estado conhecido após uma falha temporária de
  rede.

## Licença e contribuição

Antes de distribuir o aplicativo, defina a licença do projeto e os responsáveis
por manutenção, publicação de versões, operação do backend e suporte aos
usuários. Pull requests devem incluir testes ou justificar por que a alteração
não exige novos testes.
