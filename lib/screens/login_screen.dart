import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pythonproject/screens/group_list_screen.dart';
import 'package:pythonproject/screens/splash_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../core/app_colors.dart';
import 'register_screen.dart';
// import 'group_list_screen.dart'; // (XÓA) Không import nữa

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
Future<void> _login() async {
  setState(() => _loading = true);
  try {
    await Provider.of<AuthProvider>(context, listen: false)
        .login(_accountCtrl.text, _passwordCtrl.text);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SplashScreen(
            loadDataFunction: () => GroupListScreen.loadInitialData(context),
            nextScreen: const GroupListScreen(),
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu')),
    );
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text('PTIT TEAM',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const SizedBox(height: 50),
                TextField(
                  controller: _accountCtrl,
                  decoration: const InputDecoration(labelText: 'Account'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 30),
                CustomButton(
                    text: 'Đăng nhập', onPressed: _login, loading: _loading),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('Chưa có tài khoản? Đăng ký ngay'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}