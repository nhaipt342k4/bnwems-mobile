import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/geofence_util.dart';
import '../../../../core/widgets/app_button.dart';

class CheckInModalBottomSheet extends StatefulWidget {
  final String taskName;
  final String? locationName;
  final double? targetLatitude;
  final double? targetLongitude;
  final Future<void> Function(File photoFile) onConfirmCheckIn;

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
    required Future<void> Function(File photoFile) onConfirmCheckIn,
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
  bool _gpsVerified = false;
  String? _gpsError;
  double? _distanceMeters;

  File? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  String? _submitError;

  Future<void> _verifyGpsLocation() async {
    setState(() {
      _isCheckingGps = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Dịch vụ định vị GPS chưa được bật. Vui lòng bật GPS trên thiết bị.';
          _isCheckingGps = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Quyền truy cập vị trí bị từ chối.';
            _isCheckingGps = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Quyền vị trí bị chặn vĩnh viễn trong cài đặt thiết bị.';
          _isCheckingGps = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Verify geofence if target coordinates available
      if (widget.targetLatitude != null && widget.targetLongitude != null) {
        final geofence = GeofenceUtil.checkGeofence(
          currentLat: position.latitude,
          currentLon: position.longitude,
          targetLat: widget.targetLatitude!,
          targetLon: widget.targetLongitude!,
        );

        if (!geofence.isWithinRadius) {
          setState(() {
            _gpsVerified = false;
            _distanceMeters = geofence.distanceMeters;
            _gpsError =
                'Vị trí của bạn vượt quá bán kính ${AppConfig.geofenceRadiusMeters.toInt()}m (${geofence.distanceMeters.toInt()}m) so với điểm công tác.';
            _isCheckingGps = false;
          });
          return;
        }

        setState(() {
          _gpsVerified = true;
          _distanceMeters = geofence.distanceMeters;
          _gpsError = null;
          _isCheckingGps = false;
        });
      } else {
        // Assume verified if no location specified
        setState(() {
          _gpsVerified = true;
          _gpsError = null;
          _isCheckingGps = false;
        });
      }
    } catch (e) {
      setState(() {
        _gpsError = 'Không thể xác định vị trí hiện tại: ${e.toString()}';
        _isCheckingGps = false;
      });
    }
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
        });
      }
    } catch (e) {
      setState(() {
        _submitError = 'Không thể chọn/chụp ảnh: $e';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_gpsVerified) {
      setState(() {
        _submitError = 'Vui lòng kiểm tra và xác nhận vị trí GPS trước khi điểm danh.';
      });
      return;
    }

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

    try {
      await widget.onConfirmCheckIn(_photoFile!);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _submitError = e.toString();
        _isSubmitting = false;
      });
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

          // Section 1: GPS Verification
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _gpsVerified ? AppColors.completedBg : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gpsVerified ? AppColors.completedText.withValues(alpha: 0.3) : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _gpsVerified ? LucideIcons.checkCircle2 : LucideIcons.mapPin,
                      size: 18,
                      color: _gpsVerified ? AppColors.completedText : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _gpsVerified
                            ? 'Vị trí hợp lệ ${_distanceMeters != null ? '(${_distanceMeters!.toInt()}m)' : ''}'
                            : 'Xác thực vị trí GPS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _gpsVerified ? AppColors.completedText : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _isCheckingGps ? null : _verifyGpsLocation,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isCheckingGps ? 'Đang kiểm tra...' : (_gpsVerified ? 'Kiểm tra lại' : 'Kiểm tra GPS'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                if (_gpsError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _gpsError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.cancelledText),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text('Chụp ảnh điểm danh trực tiếp'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Text(
              _submitError!,
              style: const TextStyle(fontSize: 12, color: AppColors.cancelledText),
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
