import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class CheckInModalBottomSheet extends StatefulWidget {
  final String taskName;
  final String? locationName;
  final double? targetLatitude;
  final double? targetLongitude;
  final Future<void> Function(File photoFile, double? latitude, double? longitude) onConfirmCheckIn;

  const CheckInModalBottomSheet({
    super.key,
    required this.taskName,
    this.locationName,
    this.targetLatitude,
    this.targetLongitude,
    required this.onConfirmCheckIn,
  });

  static Future<void> show(
    BuildContext context, {
    required String taskName,
    String? locationName,
    double? targetLatitude,
    double? targetLongitude,
    required Future<void> Function(File photoFile, double? latitude, double? longitude) onConfirmCheckIn,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CheckInModalBottomSheet(
        taskName: taskName,
        locationName: locationName,
        targetLatitude: targetLatitude,
        targetLongitude: targetLongitude,
        onConfirmCheckIn: onConfirmCheckIn,
      ),
    );
  }

  @override
  State<CheckInModalBottomSheet> createState() => _CheckInModalBottomSheetState();
}

class _CheckInModalBottomSheetState extends State<CheckInModalBottomSheet> {
  bool _isCheckingGps = false;
  bool _hasGpsPermission = false;
  String? _gpsPermissionError;
  Position? _currentPosition;

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _checkAndInitGpsPermission();
  }

  Future<void> _checkAndInitGpsPermission() async {
    setState(() {
      _isCheckingGps = true;
      _gpsPermissionError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _hasGpsPermission = false;
            _gpsPermissionError = 'Dịch vụ định vị (GPS) trên thiết bị đang tắt.';
            _isCheckingGps = false;
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _hasGpsPermission = false;
            _gpsPermissionError = permission == LocationPermission.deniedForever
                ? 'Quyền truy cập vị trí bị chặn trong Cài đặt thiết bị.'
                : 'Ứng dụng chưa được cấp quyền truy cập vị trí (GPS).';
            _isCheckingGps = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _hasGpsPermission = true;
          _gpsPermissionError = null;
          _isCheckingGps = false;
        });
      }

      _fetchCurrentPosition();
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasGpsPermission = false;
          _gpsPermissionError = 'Không thể kiểm tra quyền vị trí: $e';
          _isCheckingGps = false;
        });
      }
    }
  }

  Future<void> _requestGpsPermission() async {
    setState(() {
      _isCheckingGps = true;
      _gpsPermissionError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (mounted) {
            setState(() {
              _hasGpsPermission = false;
              _gpsPermissionError = 'Dịch vụ GPS chưa được bật. Vui lòng bật GPS và thử lại.';
              _isCheckingGps = false;
            });
          }
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        if (mounted) {
          setState(() {
            _hasGpsPermission = false;
            _gpsPermissionError = 'Quyền vị trí bị chặn vĩnh viễn. Vui lòng bật trong Cài đặt ứng dụng.';
            _isCheckingGps = false;
          });
        }
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (mounted) {
          setState(() {
            _hasGpsPermission = true;
            _gpsPermissionError = null;
            _isCheckingGps = false;
          });
        }
        await _fetchCurrentPosition();
      } else {
        if (mounted) {
          setState(() {
            _hasGpsPermission = false;
            _gpsPermissionError = 'Quyền truy cập vị trí bị từ chối.';
            _isCheckingGps = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasGpsPermission = false;
          _gpsPermissionError = 'Không thể yêu cầu quyền vị trí: $e';
          _isCheckingGps = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentPosition() async {
    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 10),
          ),
        );
      } catch (_) {}

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
        } catch (_) {}
      }

      position ??= await Geolocator.getLastKnownPosition();

      if (mounted && position != null) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (_) {}
  }

  void _showImageSourcePickerModal() {
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
              'Tải ảnh bằng chứng điểm danh',
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
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: Icon(LucideIcons.image, color: Colors.green.shade800, size: 20),
              ),
              title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _photoFile = File(image.path);
          _submitError = null;
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'Không thể chụp/chọn ảnh: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_photoFile == null) {
      setState(() {
        _submitError = 'Vui lòng chụp ảnh bằng chứng điểm danh trực tiếp từ máy ảnh.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    if (_currentPosition == null && _hasGpsPermission) {
      await _fetchCurrentPosition();
    }

    try {
      await widget.onConfirmCheckIn(
        _photoFile!,
        _currentPosition?.latitude,
        _currentPosition?.longitude,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      final cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      if (mounted) {
        setState(() {
          _submitError = cleanMsg;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Điểm danh hiện trường',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.taskName,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (widget.locationName != null) ...[
            const SizedBox(height: 2),
            Text(
              'Địa điểm: ${widget.locationName}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 16),

          // Chỉ hiển thị mục yêu cầu GPS khi ứng dụng chưa có quyền truy cập GPS hoặc GPS bị tắt
          if (!_hasGpsPermission) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cancelledBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cancelledText.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPinOff, size: 20, color: AppColors.cancelledText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gpsPermissionError ?? 'Cần cấp quyền truy cập vị trí (GPS) để điểm danh.',
                      style: const TextStyle(fontSize: 12, color: AppColors.cancelledText),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isCheckingGps ? null : _requestGpsPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _isCheckingGps ? 'Đang bật...' : 'Cấp quyền GPS',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Đã có quyền vị trí: hiển thị badge nhỏ báo GPS sẵn sàng
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.completedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.completedText.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 14, color: AppColors.completedText),
                  const SizedBox(width: 6),
                  Text(
                    _currentPosition != null
                        ? 'Vị trí GPS sẵn sàng (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})'
                        : 'GPS sẵn sàng',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.completedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Section 2: Photo evidence capture
          const Text(
            'Ảnh bằng chứng điểm danh *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          if (_photoFile != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _photoFile!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _photoFile = null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.x, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            GestureDetector(
              onTap: _showImageSourcePickerModal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Icon(LucideIcons.camera, color: Colors.blue.shade700, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      'Chụp ảnh hoặc chọn ảnh từ thư viện',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hỗ trợ tải ảnh chụp trực tiếp hoặc ảnh có sẵn từ máy',
                      style: TextStyle(fontSize: 11, color: Colors.blue.shade700.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cancelledBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cancelledText.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.cancelledText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(fontSize: 12, color: AppColors.cancelledText, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Hủy',
                  variant: AppButtonVariant.outline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Xác nhận điểm danh',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
