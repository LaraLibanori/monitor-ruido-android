# Checklist de release

Este checklist separa o que pode ser automatizado no repositório do que exige
contas, certificados ou dispositivos físicos.

## Estado atual

- [x] Código Flutter compartilhado entre Android e iOS.
- [x] Cliente HTTP e modelos da API.
- [x] Cache local do overview e do histórico.
- [x] Testes básicos de widgets e parsing.
- [x] Workflow Android com análise, testes e APK.
- [x] Workflow iOS em macOS com análise, testes e build sem assinatura.
- [ ] Validar Android em aparelho real conectado ao servidor local.
- [ ] Validar iOS em iPhone real conectado ao servidor local.
- [ ] Configurar assinatura Android de produção.
- [ ] Configurar assinatura Apple e provisioning profile.
- [ ] Publicar no Google Play Internal Testing.
- [ ] Publicar no TestFlight.

## Android

### Homologação

```bat
cd /d "C:\caminho\para\monitor-ruido-android\app"
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Validar no aparelho:

- conexão com o servidor Docker;
- visão das quatro casas;
- horário de silêncio;
- sensor offline;
- histórico;
- queda e retorno da rede;
- rotação e tamanhos de tela;
- teclado e acessibilidade.

### Produção

1. Definir o `applicationId` definitivo.
2. Criar keystore fora do repositório.
3. Guardar senhas em secrets do CI.
4. Configurar `key.properties` somente no ambiente de build.
5. Gerar Android App Bundle:

```bat
flutter build appbundle --release
```

6. Enviar para um teste interno no Google Play Console.
7. Validar instalação, atualização e remoção do aplicativo.

Nunca versionar `.jks`, senhas, tokens ou `key.properties`.

## iOS

O build iOS exige macOS e Xcode.

### Homologação sem assinatura

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build ios --release --no-codesign
```

### TestFlight

1. Criar ou confirmar o Bundle ID, por exemplo `br.univesp.monitorruido`.
2. Associar o Bundle ID à conta Apple Developer.
3. Configurar equipe e assinatura no Xcode.
4. Adicionar a descrição de uso da rede local em `Info.plist`.
5. Confirmar que o servidor usa HTTPS ou que a exceção HTTP local está
   conscientemente documentada.
6. Criar um Archive no Xcode.
7. Enviar o Archive ao App Store Connect.
8. Distribuir pelo TestFlight.

## Segurança antes de distribuição externa

- [ ] API protegida por autenticação.
- [ ] HTTPS configurado.
- [ ] Não permitir acesso aberto à porta do servidor.
- [ ] Política de privacidade publicada.
- [ ] Logs sem IPs, tokens ou dados pessoais desnecessários.
- [ ] Chaves e certificados armazenados apenas em secrets.

## Critério de conclusão

O aplicativo só deve ser considerado pronto para produção quando passar pelos
testes em Android e iOS reais, tiver build assinado, política de privacidade,
rollback definido e publicação controlada em canal de testes.

O workflow iOS aplica automaticamente a chave `NSLocalNetworkUsageDescription`
após gerar o projeto. Em desenvolvimento local, execute
`bash scripts/configure_ios.sh` depois de `flutter create`.
