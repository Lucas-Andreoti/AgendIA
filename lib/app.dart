
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/login_screen.dart';
import 'services/auth_service.dart';

class AgendiaApp extends StatefulWidget {
  const AgendiaApp({super.key});

  @override
  State<AgendiaApp> createState() => _AgendiaAppState();
}

class _AgendiaAppState extends State<AgendiaApp>
    with WidgetsBindingObserver {
  // Tempo máximo permitido sem interação.
  static const Duration _inactivityLimit =
      Duration(minutes: 15);

  // Verifica periodicamente a sessão.
  static const Duration _checkInterval =
      Duration(seconds: 5);

  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  final GlobalKey<ScaffoldMessengerState>
      _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Timer? _sessionTimer;

  DateTime _lastActivity = DateTime.now();

  bool _isForeground = true;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();

    // Observa mudanças de estado do aplicativo.
    WidgetsBinding.instance.addObserver(this);

    // Detecta teclas do teclado físico.
    HardwareKeyboard.instance.addHandler(
      _handleKeyboardEvent,
    );

    // Verifica o tempo de inatividade.
    _sessionTimer = Timer.periodic(
      _checkInterval,
      (_) => _checkInactivity(),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();

    HardwareKeyboard.instance.removeHandler(
      _handleKeyboardEvent,
    );

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // Detecta atividade pelo teclado.
  bool _handleKeyboardEvent(KeyEvent event) {
    if (event is KeyDownEvent ||
        event is KeyRepeatEvent) {
      _registerActivity();
    }

    // Não impede outras telas de receberem teclas.
    return false;
  }

  // Registra a última interação do usuário.
  void _registerActivity() {
    if (!_isForeground || _isRedirecting) {
      return;
    }

    final now = DateTime.now();

    // Verifica se a sessão já expirou ANTES
    // de atualizar o horário da última interação.
    if (AuthService.instance.isAuthenticated &&
        now.difference(_lastActivity) >=
            _inactivityLimit) {
      _expireSession();
      return;
    }

    _lastActivity = now;
  }

  // Verifica se o limite de inatividade foi atingido.
  void _checkInactivity() {
    if (!_isForeground || _isRedirecting) {
      return;
    }

    // Não aplica expiração à tela de login.
    if (!AuthService.instance.isAuthenticated) {
      return;
    }

    final elapsed = DateTime.now().difference(
      _lastActivity,
    );

    if (elapsed >= _inactivityLimit) {
      _expireSession();
    }
  }

  // Encerra a sessão expirada.
  void _expireSession() {
    if (_isRedirecting ||
        !AuthService.instance.isAuthenticated) {
      return;
    }

    _isRedirecting = true;

    // Remove o token imediatamente, sem
    // depender da resposta de uma API.
    AuthService.instance.clearLocalSession();

    _lastActivity = DateTime.now();

    // Retorna à tela de login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = _navigatorKey.currentState;

      if (navigator == null) {
        _isRedirecting = false;
        return;
      }

      navigator.pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );

      _scaffoldMessengerKey.currentState
          ?.showSnackBar(
        const SnackBar(
          content: Text(
            'Sua sessão expirou por inatividade. '
            'Faça login novamente.',
          ),
        ),
      );

      _isRedirecting = false;
    });

    WidgetsBinding.instance.scheduleFrame();
  }

  // Detecta quando o aplicativo entra ou
  // retorna do segundo plano.
  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;

      // Verifica o tempo transcorrido enquanto
      // o aplicativo estava em segundo plano.
      _checkInactivity();
    } else {
      _isForeground = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agendia',

      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
        ),

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),

      // Detecta interações em todas as telas.
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,

          onPointerDown: (_) {
            _registerActivity();
          },

          onPointerSignal: (_) {
            _registerActivity();
          },

          child: child ?? const SizedBox.shrink(),
        );
      },

      home: const LoginScreen(),
    );
  }
}
