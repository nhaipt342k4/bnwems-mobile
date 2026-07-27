import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class HandoverSection extends StatefulWidget {
  final Future<void> Function(String note, File photoFile) onSubmit;

  const HandoverSection({
    super.key,
    required this.onSubmit,
  });

  @override
  State<HandoverSection> createState() => _HandoverSectionState();
}

class _HandoverSectionState extends State<HandoverSection> {
  final _noteController = TextEditingController();
  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() => _photoFile = File(image.path));
    }
  }

  Future<void> _handleSubmit() async {
    if (_photoFile == null) {
      setState(() => _error = 'Vui lòng chụp ảnh biên bản hoặc hiện trường bàn giao.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_noteController.text.trim(), _photoFile!);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biên bản bàn giao hiện trường',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Nội dung bàn giao',
            hintText: 'Đã bàn giao toàn bộ hệ thống khung nhôm cho đại diện khách hàng...',
            controller: _noteController,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ảnh biên bản bàn giao / chữ ký *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (_photoFile != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_photoFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _photoFile = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(LucideIcons.camera, size: 18),
              label: const Text('Chụp ảnh biên bản bàn giao'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.cancelledText)),
          ],
          const SizedBox(height: 16),
          AppButton(
            text: 'Gửi biên bản bàn giao',
            isFullWidth: true,
            isLoading: _isSubmitting,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
