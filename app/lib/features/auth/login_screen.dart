import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_state.dart';
import '../../shared/widgets/app_surface_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'aaa@aaa.com');
  final _password = TextEditingController(text: 'aaaaaa');
  final _name = TextEditingController();
  var _register = false;
  var _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = context.read<AppState>();
      if (_register) {
        await state.register(_email.text.trim(), _password.text, _name.text.trim());
      } else {
        await state.login(_email.text.trim(), _password.text);
      }
      // Router will handle redirect automatically
      print('Login successful, auth.canUseApp: ${state.auth.canUseApp}, isLoggedIn: ${state.auth.isLoggedIn}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404')) {
        setState(() => _error = '服务器 API 未更新（缺少登录接口）。请点「跳过」或联系管理员部署新版本。');
      } else {
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.rocket_launch_rounded, size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('GrowthOS', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _register ? '创建账号，开启成长之旅' : '登录你的成长工作台',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppSurfaceCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_register) ...[
                          TextField(controller: _name, decoration: const InputDecoration(labelText: '姓名')),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        TextField(
                          controller: _email,
                          decoration: const InputDecoration(labelText: '邮箱'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _password,
                          decoration: const InputDecoration(labelText: '密码'),
                          obscureText: true,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                            ),
                            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_register ? '注册' : '登录'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: () => setState(() => _register = !_register),
                          child: Text(_register ? '已有账号？登录' : '没有账号？注册'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () async {
                      await context.read<AppState>().skipLogin();
                      if (context.mounted) context.go('/dashboard');
                    },
                    child: const Text('跳过（本地模式）'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
