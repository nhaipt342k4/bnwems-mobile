import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final oldPass = _oldPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.changePassword(oldPass, newPass, confirmPass);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().logout();
                  context.go('/auth/login');
                },
                child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldPrimary)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu cũ.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Đổi mật khẩu',
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
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner (Gold/Cream)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF0DFBD)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF7F2EA),
                        ),
                        child: const Icon(LucideIcons.shieldAlert, color: AppColors.goldPrimary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Vì lý do bảo mật, mật khẩu mới cần có độ dài ít nhất 6 ký tự.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF5C4E43), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Container
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
                        label: 'Mật khẩu hiện tại *',
                        hintText: 'Nhập mật khẩu hiện tại...',
                        obscureText: _obscureOld,
                        controller: _oldPasswordController,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOld ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.warmTextMuted),
                          onPressed: () => setState(() => _obscureOld = !_obscureOld),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng nhập mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Mật khẩu mới *',
                        hintText: 'Nhập mật khẩu mới...',
                        obscureText: _obscureNew,
                        controller: _newPasswordController,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.warmTextMuted),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng nhập mật khẩu mới';
                          }
                          if (val.length < 6) {
                            return 'Mật khẩu phải có ít nhất 6 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Xác nhận mật khẩu mới *',
                        hintText: 'Nhập lại mật khẩu mới...',
                        obscureText: _obscureConfirm,
                        controller: _confirmPasswordController,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.warmTextMuted),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng xác nhận mật khẩu mới';
                          }
                          if (val != _newPasswordController.text) {
                            return 'Mật khẩu xác nhận không trùng khớp';
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
                    onPressed: authProvider.isLoading ? null : _handleChangePassword,
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
                            'Cập nhật mật khẩu',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
