import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
        backgroundColor: AppColors.goldPrimary,
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
          const SnackBar(
            content: Text('Đã lưu mã QR vào Thư viện ảnh (Photos) thành công!'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 4),
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
                backgroundColor: const Color(0xFF16A34A),
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
              backgroundColor: const Color(0xFFDC2626),
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
    if (widget.amount < 0) return const SizedBox.shrink();

    final qrUrl = _buildQrUrl();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Cổng thanh toán VietQR',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C241E),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF6F0),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFEFE8DC)),
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
                child: const Text('Không tải được QR VietQR', style: TextStyle(color: AppColors.warmTextMuted, fontSize: 13)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            Formatters.formatCurrency(widget.amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC59B63),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nội dung chuyển khoản: ${widget.addInfo}',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.warmTextMuted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyContent,
                  icon: Icon(_copied ? LucideIcons.check : LucideIcons.copy, size: 16, color: const Color(0xFF2C241E)),
                  label: Text(_copied ? 'Đã chép' : 'Sao chép', style: const TextStyle(color: Color(0xFF2C241E), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFEFE8DC)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    backgroundColor: AppColors.goldPrimary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
