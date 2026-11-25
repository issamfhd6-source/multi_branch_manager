import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/app_database.dart';
import 'features/home/presentation/main_shell_screen.dart';
import 'features/users/domain/auth_models.dart';
import 'features/users/presentation/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  runApp(MultiBranchManagerApp(db: db));
}

class MultiBranchManagerApp extends StatefulWidget {
  final AppDatabase db;

  const MultiBranchManagerApp({
    super.key,
    required this.db,
  });

  @override
  State<MultiBranchManagerApp> createState() => _MultiBranchManagerAppState();
}

class _MultiBranchManagerAppState extends State<MultiBranchManagerApp> {
  AuthSession? _session;
  bool _darkMode = false;

  @override
  void dispose() {
    widget.db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة الفروع المتعددة',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: session == null
          ? LoginScreen(
              onAuthenticated: (newSession) {
                setState(() => _session = newSession);
              },
            )
          : MainShellScreen(
              db: widget.db,
              session: session,
              darkMode: _darkMode,
              onDarkModeChanged: (val) {
                setState(() => _darkMode = val);
              },
              onLogout: () {
                setState(() => _session = null);
              },
            ),
    );
  }
}
