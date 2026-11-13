// =============================================
// main.dart - Ponto de partida do app
// =============================================
// Corrente do sistema:
//   ESP32 (sensor) -> Wi-Fi -> Docker no computador (FastAPI)
//   -> Wi-Fi -> este aplicativo (lê a API; com login, mostra só as
//      casas do morador e permite ao administrador gerenciar moradores)
// =============================================

import 'package:flutter/material.dart';

import 'api.dart';
import 'noise_ui.dart';
import 'screens/connect_screen.dart';
import 'screens/home_screen.dart';
import 'session.dart';
import 'settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedServer = await Settings.loadServer();
  final savedToken = savedServer == null ? null : await SessionStore.loadToken();
  runApp(MonitorApp(savedServer: savedServer, savedToken: savedToken));
}

class MonitorApp extends StatelessWidget {
  const MonitorApp({super.key, this.savedServer, this.savedToken});

  /// Endereço salvo da última vez (null na primeira abertura).
  final String? savedServer;

  /// Token da conta que ficou logada (null = sem login).
  final String? savedToken;

  @override
  Widget build(BuildContext context) {
    final server = savedServer;
    return MaterialApp(
      title: 'Monitor de Ruído',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: server == null
          ? const ConnectScreen()
          : HomeScreen(api: ApiClient(server, token: savedToken)),
    );
  }
}
