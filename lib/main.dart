import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';
import 'providers/task_provider.dart';
import 'providers/friends_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/prayer_times_provider.dart';
import 'services/local_storage_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/bottom_nav_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const BetterMuslimApp());
}

class BetterMuslimApp extends StatelessWidget {
  const BetterMuslimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PrayerTimesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Better Muslim',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(child: const _AppGate()),
          );
        },
      ),
    );
  }
}

/// Shows onboarding on first launch, then the main app.
/// Also handles incoming email sign-in links (passwordless auth).
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  late bool _onboardingDone;

  @override
  void initState() {
    super.initState();
    _onboardingDone = LocalStorageService.isOnboardingComplete();

    // Handle incoming email sign-in links on web
    if (kIsWeb) {
      _handleIncomingEmailLink();
    }
  }

  /// On web, check if the current URL contains a Firebase email sign-in link.
  /// If so, process it to complete sign-in automatically.
  void _handleIncomingEmailLink() {
    final uri = Uri.base.toString();
    final authProvider = context.read<AuthProvider>();

    // Check if the current URL is a valid sign-in link
    if (uri.contains('apiKey') && uri.contains('oobCode')) {
      // Delay slightly to let the widget tree stabilize
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final success = await authProvider.handleEmailLink(uri);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed in successfully! ✅'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_onboardingDone) {
      return OnboardingScreen(
        onComplete: () => setState(() => _onboardingDone = true),
      );
    }
    return const BottomNavShell();
  }
}
