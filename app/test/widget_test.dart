import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_ruido/api.dart';
import 'package:monitor_ruido/main.dart';
import 'package:monitor_ruido/screens/account_screen.dart';
import 'package:monitor_ruido/screens/admin_screen.dart';

void main() {
  testWidgets('primeira abertura mostra a tela de conexão', (tester) async {
    await tester.pumpWidget(const MonitorApp());
    expect(find.text('Conectar ao servidor'), findsOneWidget);
  });

  test('endereço digitado vira URL completa com porta 5000', () {
    expect(ApiClient.normalize('192.168.0.10'), 'http://192.168.0.10:5000');
    expect(ApiClient.normalize(' 192.168.0.10:8000/ '), 'http://192.168.0.10:8000');
    expect(ApiClient.normalize('http://10.0.0.5:5000'), 'http://10.0.0.5:5000');
  });

  test('lê a resposta real do servidor (/api/app/overview)', () {
    final overview = Overview.fromJson({
      'silence': {
        'is_silence_period': true,
        'next_change': {'at': '09:00', 'day_offset': 1, 'silence_starts': false},
        'rules': {'weekday': '22:00–09:00', 'weekend': '15:00–09:00'},
      },
      'houses': [
        {
          'sensor_id': 'sensor_ap1', 'name': 'Casa 1', 'location': 'AP1', 'online': true,
          'seconds_since_last': 0,
          'last_reading': {'rms': 20000.5, 'noise_level': 'alto', 'is_silence_period': true},
          'today': {'readings': 1, 'loud_in_silence': 1},
        },
        {
          'sensor_id': 'sensor_ap2', 'name': 'Casa 2', 'location': 'AP2', 'online': false,
          'seconds_since_last': null, 'last_reading': null,
          'today': {'readings': 0, 'loud_in_silence': 0},
        },
      ],
    });
    expect(overview.silence.active, isTrue);
    expect(overview.silence.next?.at, '09:00');
    expect(overview.houses.first.level, 'alto');
    expect(overview.houses.last.secondsSinceLast, isNull);
  });

  test('tolera campos opcionais e tipos inválidos sem quebrar o parsing', () {
    final overview = Overview.fromJson({
      'silence': {'rules': null},
      'houses': [
        {
          'sensor_id': 123,
          'online': 'não',
          'last_reading': {'rms': '12.5', 'noise_level': 99},
          'today': {'readings': '4'},
        },
        'registro inválido',
      ],
    });

    expect(overview.houses, hasLength(1));
    expect(overview.houses.single.sensorId, '');
    expect(overview.houses.single.rms, 12.5);
    expect(overview.houses.single.todayReadings, 4);
  });

  test('lê usuário e sessão devolvidos pelo login', () {
    final session = Session.fromJson({
      'token': 'abc123',
      'user': {
        'id': 7,
        'name': 'Ana',
        'email': 'ana@example.com',
        'phone': null,
        'role': 'morador',
        'active': true,
        'status': 'ativo',
        'sensor_ids': ['sensor_ap1', 'sensor_ap3'],
        'notifications': {'email': false, 'push': true},
        'devices': 1,
      },
    });
    expect(session.token, 'abc123');
    expect(session.user.isAdmin, isFalse);
    expect(session.user.sensorIds, ['sensor_ap1', 'sensor_ap3']);
    expect(session.user.emailEnabled, isFalse);
    expect(session.user.pushEnabled, isTrue);
  });

  test('convite simulado não é tratado como enviado', () {
    final simulated = InviteResult.fromJson({
      'invite_url': 'http://192.168.0.10:5000/convite?token=XYZ',
      'delivery': {'channel': 'email', 'status': 'simulated', 'detail': 'SMTP não configurado'},
    });
    expect(simulated.delivered, isFalse);
    final sent = InviteResult.fromJson({
      'invite_url': 'http://192.168.0.10:5000/convite?token=XYZ',
      'delivery': {'channel': 'email', 'status': 'sent', 'detail': ''},
    });
    expect(sent.delivered, isTrue);
  });

  test('aceita o link inteiro ou só o código do convite', () {
    expect(inviteTokenFrom(' http://192.168.0.10:5000/convite?token=AbC-123_x '), 'AbC-123_x');
    expect(inviteTokenFrom('AbC-123_x'), 'AbC-123_x');
  });

  test('cliente com token é uma nova instância e sabe se está logado', () {
    final anonymous = ApiClient('http://10.0.0.5:5000');
    final logged = anonymous.withToken('t0k3n');
    expect(anonymous.loggedIn, isFalse);
    expect(logged.loggedIn, isTrue);
    expect(logged.baseUrl, anonymous.baseUrl);
    expect(logged.withToken(null).loggedIn, isFalse);
  });

  test('valida o formulário de novo morador', () {
    expect(ResidentDraft.validate(name: '', email: 'ana@example.com'), isNotNull);
    expect(ResidentDraft.validate(name: 'Ana', email: 'ana'), isNotNull);
    expect(ResidentDraft.validate(name: 'Ana', email: 'ana@example'), isNotNull);
    expect(ResidentDraft.validate(name: 'Ana', email: 'ana@example.com'), isNull);
  });

  test('descreve o resultado de um envio sem dizer que enviou quando foi simulado', () {
    final simulated = DeliveryInfo.fromJson({'channel': 'push', 'status': 'simulated', 'detail': ''});
    expect(deliveryLabel(simulated), contains('simulado'));
    final sent = DeliveryInfo.fromJson({'channel': 'email', 'status': 'sent', 'detail': ''});
    expect(deliveryLabel(sent), 'E-mail: enviado');
  });
}
