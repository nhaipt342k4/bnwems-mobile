import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

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
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        if (mounted) {
          setState(() {
            _hasGpsPermission = true;
            _gpsPermissionError = null;
            _isCheckingGps = false;
          });
        }
        _fetchCurrentPosition();
      } else {
        if (mounted) {
          setState(() {
            _hasGpsPermission = false;
            _gpsPermissionError = 'Bạn đã từ chối cấp quyền GPS.';
            _isCheckingGps = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasGpsPermission = false;
          _gpsPermissionError = 'Lỗi yêu cầu quyền GPS: $e';
          _isCheckingGps = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPhotoFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        setState(() {
          _photoFile = File(image.path);
          _submitError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = 'Không thể mở máy ảnh trên thiết bị này. Vui lòng chọn ảnh từ thư viện.';
        });
      }
    }
  }

  Future<void> _pickPhotoFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _photoFile = File(image.path);
          _submitError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = 'Không thể mở thư viện ảnh: $e';
        });
      }
    }
  }

  void _showImageSourcePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn nguồn ảnh chụp điểm danh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFAF6F0), shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, color: AppColors.goldPrimary, size: 20),
              ),
              title: const Text('Chụp ảnh trực tiếp từ camera', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C241E))),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotoFromCamera();
              },
            ),
            const Divider(height: 1, color: Color(0xFFEFE8DC)),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFAF6F0), shape: BoxShape.circle),
                child: const Icon(LucideIcons.image, color: AppColors.goldPrimary, size: 20),
              ),
              title: const Text('Chọn ảnh sẵn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2C241E))),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotoFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_photoFile == null) {
      setState(() {
        _submitError = 'Vui lòng chụp hoặc tải ảnh bằng chứng hiện trường trước khi Check-in.';
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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Điểm danh hiện trường',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C241E),
                  fontFamily: 'serif',
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF6F0),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(LucideIcons.x, size: 18, color: Color(0xFF2C241E)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task & Location Summary Card (Vibrant Warm Gold Gradient)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC59B63), Color(0xFFA87E46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC59B63).withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taskName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (widget.locationName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Địa điểm: ${widget.locationName}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFFF7EEDD)),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // GPS Status Pill
          if (!_hasGpsPermission) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mapPinOff, size: 20, color: Color(0xFFDC2626)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _gpsPermissionError ?? 'Cần cấp quyền truy cập vị trí (GPS) để điểm danh.',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isCheckingGps ? null : _requestGpsPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle, size: 15, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    _currentPosition != null
                        ? 'GPS sẵn sàng (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})'
                        : 'GPS sẵn sàng',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Photo Evidence Upload Section
          const Text(
            'Ảnh bằng chứng điểm danh *',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
          ),
          const SizedBox(height: 8),

          if (_photoFile != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.all(6),
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
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9EE),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0DFBD)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFAF6F0),
                      ),
                      child: const Icon(LucideIcons.camera, color: AppColors.goldPrimary, size: 24),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Chụp ảnh hoặc chọn ảnh từ thư viện',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2C241E)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Hỗ trợ tải ảnh chụp trực tiếp hoặc ảnh có sẵn từ máy',
                      style: TextStyle(fontSize: 12, color: AppColors.warmTextMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _submitError!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),

          // Action Buttons: Hủy (Outlined) & Xác nhận điểm danh (Solid Gold)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFC59B63)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC59B63), fontSize: 14.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Xác nhận điểm danh', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
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
