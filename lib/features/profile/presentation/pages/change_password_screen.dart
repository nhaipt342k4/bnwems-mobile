import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
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
            title: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthProvider>().logout();
                  context.go('/auth/login');
                },
                child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.shieldAlert, color: Colors.blue.shade800, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vì lý do bảo mật, mật khẩu mới cần có độ dài ít nhất 6 ký tự.',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
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
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Mật khẩu hiện tại *',
                        hintText: 'Nhập mật khẩu hiện tại...',
                        obscureText: _obscureOld,
                        controller: _oldPasswordController,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOld ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.textMuted),
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
                          icon: Icon(_obscureNew ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.textMuted),
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
                          icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: AppColors.textMuted),
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

                AppButton(
                  text: 'Cập nhật mật khẩu',
                  isFullWidth: true,
                  isLoading: authProvider.isLoading,
                  onPressed: _handleChangePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
