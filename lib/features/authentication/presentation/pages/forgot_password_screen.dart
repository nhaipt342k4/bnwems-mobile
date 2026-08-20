import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.warmTextDark,
            fontFamily: 'serif',
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 18, color: Color(0xFF8C7355)),
            padding: EdgeInsets.zero,
            onPressed: () => context.pop(),
          ),
        ),
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

          // Top Key Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F2EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.keyRound,
              size: 44,
              color: AppColors.goldPrimary,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Khôi phục mật khẩu',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.warmTextDark,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập Tên đăng nhập hoặc Số điện thoại tài khoản của bạn để gửi yêu cầu cấp lại mật khẩu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.warmTextMuted, height: 1.4),
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
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

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Gửi yêu cầu khôi phục',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Quay lại Đăng nhập',
              style: TextStyle(color: AppColors.goldPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
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
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle2,
            size: 56,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Đã gửi yêu cầu khôi phục!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: AppColors.warmTextDark,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            'Yêu cầu khôi phục mật khẩu cho tài khoản "${_identifierController.text.trim()}" đã được ghi nhận. Vui lòng liên hệ với Quản trị viên (Admin) để nhận mật khẩu tạm thời.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.warmTextMuted, height: 1.5),
          ),
        ),

        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.go('/auth/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: AppColors.goldPrimary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text(
              'Về trang đăng nhập',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
