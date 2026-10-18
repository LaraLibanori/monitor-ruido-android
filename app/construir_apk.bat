@echo off
setlocal EnableExtensions
REM ============================================
REM  Gera o APK do app no seu computador (precisa do Flutter instalado)
REM  https://docs.flutter.dev/get-started/install/windows/mobile
REM ============================================
set "APP_DIR=%~dp0"
pushd "%APP_DIR%" >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Nao foi possivel acessar a pasta do aplicativo:
    echo        %APP_DIR%
    echo.
    echo Verifique permissoes do Windows ou mova o projeto para uma pasta
    echo acessivel ao seu usuario, por exemplo C:\Projetos\monitor-ruido-android.
    pause
    exit /b 1
)

echo Pasta do aplicativo: %CD%

where flutter >nul 2>&1
if errorlevel 1 (
    echo  [ERRO] Flutter nao encontrado. Instale pelo link no topo deste arquivo.
    popd
    pause
    exit /b 1
)

flutter --version
if errorlevel 1 (
    echo  [ERRO] O comando Flutter foi encontrado, mas nao pode ser executado.
    echo        Confira o PATH e execute: flutter doctor -v
    popd
    pause
    exit /b 1
)

REM Na primeira vez, o Flutter completa a pasta android (nao apaga nada que ja existe)
if not exist "android\app\build.gradle" if not exist "android\app\build.gradle.kts" if not exist "android\gradlew" (
    echo  Preparando o projeto Android pela primeira vez...
    call flutter create --platforms=android --org br.univesp --project-name monitor_ruido .
    if errorlevel 1 (
        echo  [ERRO] Nao foi possivel gerar os arquivos Android.
        popd
        pause
        exit /b 1
    )
)

call flutter pub get
if errorlevel 1 (
    echo  [ERRO] Falha ao instalar as dependencias Dart.
    popd
    pause
    exit /b 1
)

call flutter analyze
if errorlevel 1 (
    echo  [ERRO] A analise estatica encontrou problemas.
    popd
    pause
    exit /b 1
)

call flutter test
if errorlevel 1 (
    echo  [ERRO] Os testes falharam.
    popd
    pause
    exit /b 1
)

call flutter build apk --release
if errorlevel 1 (
    echo  [ERRO] A compilacao falhou. Veja as mensagens acima.
    popd
    pause
    exit /b 1
)

echo.
echo  Pronto! O APK esta em:
echo    build\app\outputs\flutter-apk\app-release.apk
echo  Mande esse arquivo para o celular (WhatsApp, cabo, Google Drive) e instale.
echo.
popd
pause
