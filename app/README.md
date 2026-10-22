# Monitor de Ruído — aplicativo Flutter

Este diretório contém o aplicativo Android do Monitor de Ruído IoT. O app
consome dados de um servidor local, interpreta os níveis de ruído em linguagem
simples e apresenta o estado das casas monitoradas.

## Fluxo do sistema

```text
ESP32 → servidor FastAPI/Docker → API HTTP → aplicativo Flutter
```

O aplicativo não grava áudio, não envia comandos aos sensores e não altera os
dados no servidor.

## Requisitos

- Flutter estável instalado e disponível no `PATH`;
- Android Studio e Android SDK;
- Android SDK Command-line Tools;
- dispositivo Android ou emulador;
- servidor local acessível pela rede.

Verifique a instalação:

```bat
flutter doctor -v
```

## Instalação e validação

Execute na pasta `app`:

```bat
flutter pub get
flutter analyze
flutter test
```

Para iniciar o aplicativo:

```bat
flutter run
```

No Windows, o script abaixo executa a preparação e todas as validações antes
de gerar o APK:

```bat
construir_apk.bat
```

O APK é gerado em:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## Compilação pelo GitHub Actions

O workflow raiz `.github/workflows/android.yml` executa análise, testes e build
do APK. O artefato gerado chama-se `monitor-ruido-apk`.

O workflow `.github/workflows/ios.yml` executa em macOS e valida a compilação
iOS sem assinatura. A publicação em TestFlight ainda exige uma conta Apple
Developer, Bundle ID e certificados configurados no Xcode.

## Uso do aplicativo

1. Inicie o servidor local.
2. Conecte computador e celular à mesma rede Wi-Fi.
3. Abra o app e informe o IP do computador.
4. O app testa a conexão antes de salvar o endereço.
5. Se a rede cair depois de uma leitura válida, o app apresenta o cache local e
   informa a idade dos dados.

Endereços aceitos:

```text
192.168.0.10
192.168.0.10:5000
http://192.168.0.10:5000
```

## Contrato consumido

```http
GET /api/app/overview
GET /api/app/houses/{sensor_id}/history
```

O aplicativo espera que o overview contenha o estado do horário de silêncio e
uma lista de casas. Cada casa pode informar estado online, última leitura,
nível de ruído, RMS e estatísticas do dia. O histórico contém buckets por hora
e um resumo diário.

## Estrutura

```text
lib/
├── main.dart                 inicialização e tela inicial
├── api.dart                  cliente HTTP e modelos da API
├── noise_ui.dart             tema, níveis e componentes visuais
├── settings.dart             endereço salvo e cache local
└── screens/
    ├── connect_screen.dart   conexão com o servidor
    ├── home_screen.dart      visão geral das casas
    ├── house_screen.dart     histórico de uma casa
    └── help_screen.dart      explicações para o usuário

test/
└── widget_test.dart           testes de widgets e parsing
```

## Diagnóstico rápido

### `flutter` não é reconhecido

Instale o Flutter e adicione o diretório `flutter\bin` ao `PATH`. Depois feche
e abra o terminal novamente:

```bat
flutter --version
flutter doctor -v
```

### `Set-Location` não é reconhecido

Esse comando pertence ao PowerShell. No CMD use:

```bat
cd /d "C:\caminho\para\monitor-ruido-android\app"
```

No PowerShell use:

```powershell
Set-Location -LiteralPath "C:\caminho\para\monitor-ruido-android\app"
```

### Acesso negado no Windows

Não execute o build dentro de `app\android`. Use a pasta `app` e, se
necessário, mova o projeto para um diretório com permissão, por exemplo:

```text
C:\Projetos\monitor-ruido-android
```

### O app não conecta ao servidor

Confira:

- servidor Docker em execução;
- IP e porta corretos;
- celular e computador no mesmo Wi-Fi;
- firewall permitindo a porta da API;
- rede sem isolamento entre clientes;
- endpoint `/api/app/overview` respondendo no navegador ou no `curl`.

### O app mostra dados antigos

Isso indica que a última atualização falhou, mas o cache local está disponível.
Verifique a rede e atualize a tela. Os dados exibidos permanecem somente para
consulta até que uma nova resposta seja recebida.

## Android e iOS

O código Dart é compartilhado entre as duas plataformas. Android pode ser
compilado localmente em Windows, macOS ou Linux com o SDK configurado. iOS
precisa de macOS e Xcode:

```bash
flutter create --platforms=android,ios --org br.univesp --project-name monitor_ruido .
flutter pub get
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

O comando `--no-codesign` serve para validar a compilação. Para instalar em
iPhone real ou publicar no TestFlight, é obrigatório configurar assinatura,
provisionamento e equipe Apple no Xcode. Consulte `docs/RELEASE-CHECKLIST.md`.

## Limitações

- o aplicativo depende do contrato fornecido pelo backend;
- a medição não é uma medição legal ou certificada em decibéis;
- HTTP sem TLS é permitido apenas para o cenário de rede local;
- autenticação, HTTPS e endurecimento do servidor são necessários para uso
  fora da rede confiável.
