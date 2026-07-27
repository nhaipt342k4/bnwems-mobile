import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class VietQrWidget extends StatefulWidget {
  final double amount;
  final String addInfo;

  const VietQrWidget({
    super.key,
    required this.amount,
    required this.addInfo,
  });

  @override
  State<VietQrWidget> createState() => _VietQrWidgetState();
}

class _VietQrWidgetState extends State<VietQrWidget> {
  bool _copied = false;
  bool _isDownloading = false;

  String _buildQrUrl({String template = 'compact2'}) {
    final encodedAddInfo = Uri.encodeComponent(widget.addInfo);
    return 'https://img.vietqr.io/image/MB-0354148419-$template.png?amount=${widget.amount.toInt()}&addInfo=$encodedAddInfo&accountName=CONG%20TY%20BNWEMS';
  }

  void _copyContent() {
    Clipboard.setData(ClipboardData(text: widget.addInfo));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép nội dung chuyển khoản'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _downloadQrImage() async {
    setState(() => _isDownloading = true);

    try {
      final qrUrl = _buildQrUrl();
      final dio = Dio();
      final response = await dio.get<List<int>>(
        qrUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Không tải được dữ liệu ảnh từ server VietQR');
      }

      final bytes = Uint8List.fromList(response.data!);
      final sanitizedAddInfo = widget.addInfo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'VietQR_$sanitizedAddInfo';

      // Request photo gallery permission if required
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      // Save directly into the device's native Photo Gallery / Photos album
      await Gal.putImageBytes(
        bytes,
        name: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã lưu mã QR vào Thư viện ảnh (Photos) thành công!'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Fallback: save to Pictures directory if Gal faces permission restrictions
      try {
        final sanitizedAddInfo = widget.addInfo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        final fileName = 'VietQR_$sanitizedAddInfo.png';
        Directory? picturesDir;
        if (Platform.isAndroid) {
          picturesDir = Directory('/storage/emulated/0/Pictures');
          if (!await picturesDir.exists()) {
            picturesDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
          }
        } else {
          picturesDir = await getApplicationDocumentsDirectory();
        }
        final file = File('${picturesDir.path}/$fileName');
        final qrUrl = _buildQrUrl();
        final response = await Dio().get<List<int>>(
          qrUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          await file.writeAsBytes(response.data!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã lưu mã QR vào thư mục Pictures: $fileName'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi tải mã QR: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.amount <= 0) return const SizedBox.shrink();

    final qrUrl = _buildQrUrl();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cổng thanh toán VietQR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Image.network(
              qrUrl,
              height: 220,
              width: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 220,
                width: 220,
                color: Colors.grey.shade100,
                alignment: Alignment.center,
                child: const Text('Không tải được QR VietQR'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            Formatters.formatCurrency(widget.amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nội dung chuyển khoản: ${widget.addInfo}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyContent,
                  icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 16),
                  label: Text(_copied ? 'Đã chép' : 'Sao chép'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadQrImage,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.download, size: 16, color: Colors.white),
                  label: const Text(
                    'Tải hình ảnh QR',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
