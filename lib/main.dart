import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pythonproject/screens/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/group_provider.dart';
import 'providers/task_provider.dart';
import 'providers/invitation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/group_list_screen.dart';
import 'core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const PTITWorkerApp());
}

class PTITWorkerApp extends StatelessWidget {
  const PTITWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, GroupProvider>(
          create: (_) => GroupProvider(AuthProvider()),
          update: (_, auth, prev) => GroupProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(AuthProvider()),
          update: (_, auth, prev) => TaskProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, InvitationProvider>(
          create: (_) => InvitationProvider(AuthProvider()),
          update: (_, auth, prev) => InvitationProvider(auth),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PTIT Worker',
        theme: ThemeData(
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            background: Colors.white,
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),

          // (MỚI) Thêm màu cho hiệu ứng nhấn (ripple)
          splashColor: AppColors.primary.withOpacity(0.1),

          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
              .copyWith(
                headlineMedium: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
                titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                bodyMedium: GoogleFonts.poppins(fontSize: 14),
              ),

          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 1,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),

          cardTheme: CardThemeData(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            labelStyle: const TextStyle(color: AppColors.grey),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),

          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            backgroundColor: Colors.white,
            elevation: 5,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

// (AuthOrHome giữ nguyên)
class AuthOrHome extends StatefulWidget {
  const AuthOrHome({super.key});

  @override
  State<AuthOrHome> createState() => _AuthOrHomeState();
}

class _AuthOrHomeState extends State<AuthOrHome> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isAuthenticated ? const GroupListScreen() : const LoginScreen();
  }
}
