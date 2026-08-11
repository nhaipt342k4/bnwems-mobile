import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final authProvider = context.read<AuthProvider>();

    await authProvider.requestForgotPassword(identifier);

    if (mounted) {
      setState(() => _isSubmitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quên mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _isSubmitted ? _buildSuccessView() : _buildRequestForm(authProvider),
        ),
      ),
    );
  }

  Widget _buildRequestForm(AuthProvider authProvider) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Top Lock Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.keyRound,
              size: 44,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Khôi phục mật khẩu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập Tên đăng nhập hoặc Số điện thoại tài khoản của bạn để gửi yêu cầu cấp lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                AppTextField(
                  label: 'Tên đăng nhập hoặc Số điện thoại *',
                  hintText: 'Ví dụ: manager01 hoặc 0912345678',
                  controller: _identifierController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập Tên đăng nhập hoặc Số điện thoại';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          if (authProvider.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(authProvider.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 24),

          AppButton(
            text: 'Gửi yêu cầu khôi phục',
            isFullWidth: true,
            isLoading: authProvider.isLoading,
            onPressed: _handleForgotPassword,
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Quay lại Đăng nhập', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.checkCircle2,
            size: 56,
            color: Colors.green.shade600,
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Đã gửi yêu cầu khôi phục!',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            'Yêu cầu khôi phục mật khẩu cho tài khoản "${_identifierController.text.trim()}" đã được ghi nhận. Vui lòng liên hệ với Quản trị viên (Admin) để nhận mật khẩu tạm thời.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
        ),

        const SizedBox(height: 32),

        AppButton(
          text: 'Về trang đăng nhập',
          isFullWidth: true,
          onPressed: () => context.go('/auth/login'),
        ),
      ],
    );
  }
}
