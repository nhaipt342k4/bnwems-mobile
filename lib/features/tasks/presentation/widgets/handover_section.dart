import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class HandoverSection extends StatefulWidget {
  final String? existingNotes;
  final List<String> existingPhotoUrls;
  final bool isAlreadySubmitted;
  final Future<void> Function(String note, List<File> photoFiles) onSubmit;

  const HandoverSection({
    super.key,
    this.existingNotes,
    this.existingPhotoUrls = const [],
    this.isAlreadySubmitted = false,
    required this.onSubmit,
  });

  @override
  State<HandoverSection> createState() => _HandoverSectionState();
}

class _HandoverSectionState extends State<HandoverSection> {
  late final TextEditingController _noteController;
  final List<File> _photoFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.existingNotes ?? '');
    // Nếu provider báo đã nộp HOẶC đã có ảnh từ server thì khoá ngay từ đầu
    _isSubmitted = widget.isAlreadySubmitted || widget.existingPhotoUrls.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant HandoverSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Khi parent rebuild và truyền isAlreadySubmitted = true hoặc có ảnh server thì khoá ngay
    if (!_isSubmitted && (widget.isAlreadySubmitted || widget.existingPhotoUrls.isNotEmpty)) {
      setState(() => _isSubmitted = true);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() {
    // Không cho thao tác khi đã nộp
    if (_isSubmitted) return;

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
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() {
          _photoFiles.add(File(image.path));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể mở camera trên thiết bị/nền tảng này. Vui lòng chọn ảnh từ thư viện.';
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        setState(() {
          _photoFiles.addAll(images.map((img) => File(img.path)));
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể chọn ảnh từ thư viện: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  void _removePhoto(int index) {
    if (_isSubmitted) return;
    setState(() {
      _photoFiles.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitted) return;

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
      if (mounted) {
        setState(() {
          _isSubmitted = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi biên bản bàn giao thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSubmitted ? Colors.green.shade50 : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSubmitted ? Colors.green.shade300 : AppColors.borderLight,
          width: _isSubmitted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header ----------
          Row(
            children: [
              Expanded(
                child: const Text(
                  'Biên bản bàn giao hiện trường',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              if (_isSubmitted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCircle2, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Đã nộp',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ---------- Banner khi đã nộp ----------
          if (_isSubmitted)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.green.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Biên bản đã được nộp thành công. Bạn không thể chỉnh sửa thêm.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ---------- Note field (khoá nếu đã nộp) ----------
          AppTextField(
            label: 'Nội dung bàn giao',
            hintText: 'Đã bàn giao toàn bộ hệ thống khung nhôm cho đại diện khách hàng...',
            controller: _noteController,
            maxLines: 2,
            readOnly: _isSubmitted,
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

          // ---------- Ảnh: chỉ hiển thị danh sách khi đã nộp, không cho thêm/xoá ----------
          if (!_isSubmitted && _photoFiles.isEmpty && widget.existingPhotoUrls.isEmpty) ...[
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
          ] else if (_photoFiles.isNotEmpty || widget.existingPhotoUrls.isNotEmpty) ...[
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.existingPhotoUrls.length + _photoFiles.length + (_isSubmitted ? 0 : 1),
                itemBuilder: (ctx, index) {
                  // Nút thêm ảnh (chỉ khi chưa nộp)
                  if (!_isSubmitted && index == widget.existingPhotoUrls.length + _photoFiles.length) {
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

                  final isRemote = index < widget.existingPhotoUrls.length;
                  final imageUrl = isRemote ? widget.existingPhotoUrls[index] : null;
                  final file = !isRemote ? _photoFiles[index - widget.existingPhotoUrls.length] : null;

                  return Stack(
                    children: [
                      Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: (isRemote ? NetworkImage(imageUrl!) : FileImage(file!)) as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                          border: _isSubmitted
                              ? Border.all(color: Colors.green.shade400, width: 2)
                              : null,
                        ),
                      ),
                      if (!_isSubmitted && !isRemote)
                        Positioned(
                          top: 4,
                          right: 14,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index - widget.existingPhotoUrls.length),
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
                      if (_isSubmitted)
                        Positioned(
                          top: 4,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
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

          // ---------- Nút: ẩn hoàn toàn khi đã nộp ----------
          if (!_isSubmitted)
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
