import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class HandoverSection extends StatefulWidget {
  final Future<void> Function(String note, List<File> photoFiles) onSubmit;

  const HandoverSection({
    super.key,
    required this.onSubmit,
  });

  @override
  State<HandoverSection> createState() => _HandoverSectionState();
}

class _HandoverSectionState extends State<HandoverSection> {
  final _noteController = TextEditingController();
  final List<File> _photoFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải ảnh biên bản bàn giao / chữ ký',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.camera, color: Colors.blue.shade800, size: 20),
              ),
              title: const Text('Chụp ảnh từ máy ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.image, color: Colors.green.shade800, size: 20),
              ),
              title: const Text('Chọn nhiều ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      setState(() {
        _photoFiles.add(File(image.path));
        _error = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isNotEmpty) {
      setState(() {
        _photoFiles.addAll(images.map((img) => File(img.path)));
        _error = null;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoFiles.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_photoFiles.isEmpty) {
      setState(() => _error = 'Vui lòng chụp hoặc tải lên ít nhất 1 ảnh biên bản/hiện trường bàn giao.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_noteController.text.trim(), List.from(_photoFiles));
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ảnh biên bản bàn giao / chữ ký *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (_photoFiles.isNotEmpty)
                Text(
                  'Đã chọn ${_photoFiles.length} ảnh',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_photoFiles.isEmpty) ...[
            InkWell(
              onTap: _showImagePickerOptions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.camera, color: Colors.blue.shade700, size: 26),
                    const SizedBox(height: 6),
                    Text(
                      'Chụp ảnh hoặc chọn nhiều ảnh từ thư viện',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Hỗ trợ tải lên biên bản bàn giao & chữ ký khách hàng',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _photoFiles.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == _photoFiles.length) {
                    return GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, color: Colors.blue.shade800, size: 24),
                            const SizedBox(height: 4),
                            Text(
                              'Thêm ảnh',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final file = _photoFiles[index];
                  return Stack(
                    children: [
                      Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(file),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
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
