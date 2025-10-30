import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_button.dart';
import '../core/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullname = TextEditingController();
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      await Provider.of<AuthProvider>(context, listen: false).register(
          _fullname.text, _account.text, _password.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công! Hãy đăng nhập.')));
      }
    } catch (_) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đăng ký thất bại')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Đăng ký'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _fullname, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 15),
              TextField(controller: _account, decoration: const InputDecoration(labelText: 'Account')),
              const SizedBox(height: 15),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 30),
              CustomButton(text: 'Đăng ký', onPressed: _register, loading: _loading),
            ],
          ),
        ),
      ),
    );
  }
}
