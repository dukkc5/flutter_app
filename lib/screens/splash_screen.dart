import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  final Future<void> Function() loadDataFunction;
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    required this.loadDataFunction,
    required this.nextScreen,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 1.0;
  bool _showWelcome = false;

  static const Duration _logoFadeDuration = Duration(milliseconds: 800);
  static const Duration _welcomeDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _startSequence();
  }

  Future<void> _startSequence() async {
    await widget.loadDataFunction();

    // 1. Logo hiện 1.5s rồi mờ đi
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _logoOpacity = 0.0);

    // 2. Hiện chữ "Xin chào"
    await Future.delayed(_logoFadeDuration);
    if (!mounted) return;
    setState(() => _showWelcome = true);

    // 3. Giữ 1.5s rồi biến mất ngay lập tức (không fade)
    await Future.delayed(_welcomeDuration);
    if (!mounted) return;
    setState(() => _showWelcome = false);

    // 4. Chuyển sang màn hình chính
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.fullName ?? authProvider.account ?? 'Bạn';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: AnimatedOpacity(
              opacity: _logoOpacity,
              duration: _logoFadeDuration,
              child: Image.asset(
                'assets/images/ptit_team_logo.png',
                width: 200,
                height: 200,
              ),
            ),
          ),
          if (_showWelcome)
            Positioned.fill(
              child: Container(
                color: Colors.red.shade900,
                child: Center(
                  child: Text(
                    'Xin chào, $userName!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
