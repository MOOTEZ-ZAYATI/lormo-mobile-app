import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/user_service.dart';
import 'services/task_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/onboarding_screen.dart';
import 'widgets/error_boundary.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AppLoader(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        useMaterial3: true,
      ),
    );
  }
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> with WidgetsBindingObserver {
  bool _initialized = false;
  late UserService _userService;
  late TaskService _taskService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0A0F),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services
      final prefs = await SharedPreferences.getInstance();
      final notificationService = NotificationService();
      await notificationService.initialize();
      _userService = UserService(prefs, notificationService);
      _taskService = TaskService(prefs: prefs, userService: _userService);

      // Set system UI
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0A0F),
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Container(
        color: const Color(0xFF0A0A0F),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00B4D8),
          ),
        ),
      );
    }

    return MyApp(
      userService: _userService,
      taskService: _taskService,
    );
  }
}

class MyApp extends StatelessWidget {
  final UserService userService;
  final TaskService taskService;

  const MyApp({
    super.key,
    required this.userService,
    required this.taskService,
  });

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();
    
    return MaterialApp(
      title: 'Lormo',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00B4D8),    // Bright Blue
          secondary: Color(0xFF38C172),   // Green
          surface: Colors.black,
          background: Colors.black,
          error: Color(0xFFE3342F),
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A),  // Slightly lighter black
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1A1A1A),
          indicatorColor: const Color(0xFF00B4D8).withOpacity(0.2),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 12),
          ),
        ),
      ),
      home: ErrorBoundary(
        child: FutureBuilder<bool>(
          future: userService.isFirstLaunch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                color: const Color(0xFF0A0A0F),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final isFirstLaunch = snapshot.data ?? true;
            return isFirstLaunch
                ? OnboardingScreen(
                    userService: userService,
                    taskService: taskService,
                  )
                : DashboardScreen(
                    userService: userService,
                    taskService: taskService,
                  );
          },
        ),
      ),
    );
  }
}