import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../tasks/data/services/evidence_api_service.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../../../tasks/presentation/widgets/check_in_modal_bottom_sheet.dart';
import '../../../tasks/presentation/widgets/current_task_card.dart';
import '../widgets/active_checkin_card.dart';
import '../widgets/quick_attendance_card.dart';
import '../widgets/task_statistic_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskProvider = context.read<TaskProvider>();
      taskProvider.loadMyPlans();
      taskProvider.loadActiveCheckIns();
    });
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'NV';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final taskProvider = context.watch<TaskProvider>();
    final todayStr = Formatters.toIsoDateOnly(Formatters.nowInVietnam());

    final todayPlans = taskProvider.myPlans.where((plan) {
      try {
        final localDate = Formatters.parseVietnamDateTime(plan.startTime);
        return Formatters.toIsoDateOnly(localDate) == todayStr;
      } catch (_) {
        return plan.startTime.startsWith(todayStr);
      }
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final pendingCount = taskProvider.myPlans.where((plan) => plan.status == 'PENDING').length;

    final primaryTodayPlan = todayPlans.cast<dynamic>().firstWhere(
          (plan) => plan.status != 'CANCELLED' && plan.status != 'COMPLETED',
          orElse: () => null,
        );

    final primaryAssignee = primaryTodayPlan != null && user != null
        ? taskProvider.getMyAssignee(primaryTodayPlan, user.id)
        : null;

    final userInitials = _getInitials(user?.fullName);

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          await taskProvider.loadMyPlans();
          await taskProvider.loadActiveCheckIns();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),

              // Greeting Header Card (Warm Gold / Beige Theme)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAD8B7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC59B63).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Badge
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              userInitials,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Greeting & Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'XIN CHÀO,',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF8C7355),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.fullName ?? 'Nhân viên',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2C241E),
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification Bell Icon Button
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF9F0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.push('/staff/notifications'),
                            icon: const Icon(
                              LucideIcons.bell,
                              color: Color(0xFF8C7355),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bạn có ${todayPlans.length} kế hoạch hôm nay (${Formatters.formatDate(todayStr)})',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF7A6855),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Việc đang làm (đã check-in, chưa check-out) — nguồn: GET /schedule-plans/active
              if (user != null && taskProvider.activeCheckInPlans.isNotEmpty) ...[
                ...taskProvider.activeCheckInPlans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ActiveCheckInCard(
                      plan: plan,
                      myAssignee: taskProvider.getMyAssignee(plan, user.id),
                      onCheckOut: () => taskProvider.checkOut(plan.planId, user.id),
                    ),
                  ),
                ),
              ],

              // Quick Attendance Card
              QuickAttendanceCard(
                plan: primaryTodayPlan,
                myAssignee: primaryAssignee,
                activePlan: user != null ? taskProvider.getActiveCheckedInPlan(user.id) : null,
                onCheckInPressed: () {
                  if (primaryTodayPlan != null && user != null) {
                    final activePlan = taskProvider.getActiveCheckedInPlan(user.id);
                    if (activePlan != null && activePlan.planId != primaryTodayPlan.planId) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bạn đang thực hiện công việc "${activePlan.taskName}" (${activePlan.planCode}) chưa check-out. Vui lòng check-out trước khi check-in công việc mới.'),
                          backgroundColor: Colors.red.shade700,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                      return;
                    }
                    CheckInModalBottomSheet.show(
                      context,
                      taskName: primaryTodayPlan.taskName,
                      locationName: primaryTodayPlan.location,
                      targetLatitude: primaryTodayPlan.latitude,
                      targetLongitude: primaryTodayPlan.longitude,
                      onConfirmCheckIn: (photoFile, lat, lng) async {
                        String? evidenceId;
                        try {
                          final ev = await EvidenceApiService().upload(photoFile);
                          evidenceId = ev.evidenceId;
                        } catch (_) {}
                        if (context.mounted) {
                          await context.read<TaskProvider>().checkIn(
                            primaryTodayPlan.planId,
                            user.id,
                            checkInEvidenceId: evidenceId,
                            latitude: lat,
                            longitude: lng,
                          );
                        }
                      },
                    );
                  }
                },
                onCheckOutPressed: () {
                  if (primaryTodayPlan != null && user != null) {
                    taskProvider.checkOut(primaryTodayPlan.planId, user.id);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Statistic Grid
              TaskStatisticGrid(
                todayCount: todayPlans.length,
                pendingConfirmationCount: pendingCount,
              ),
              const SizedBox(height: 20),

              // Today's Plans List Section Header
              const Text(
                'Kế hoạch đang diễn ra hôm nay',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8C7355),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),

              if (taskProvider.isLoading) ...[
                const AppLoadingIndicator(message: 'Đang tải danh sách công việc...'),
              ] else if (todayPlans.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Không có kế hoạch nào hôm nay.',
                    style: TextStyle(fontSize: 14, color: AppColors.warmTextMuted),
                  ),
                ),
              ] else ...[
                ...todayPlans.map(
                  (plan) {
                    final activePlan = user != null ? taskProvider.getActiveCheckedInPlan(user.id) : null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CurrentTaskCard(
                        plan: plan,
                        myAssignee: user != null ? taskProvider.getMyAssignee(plan, user.id) : null,
                        activePlan: activePlan,
                        onCheckInPressed: () {
                          if (user != null) {
                            final activePlan = taskProvider.getActiveCheckedInPlan(user.id);
                            if (activePlan != null && activePlan.planId != plan.planId) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Bạn đang thực hiện công việc "${activePlan.taskName}" (${activePlan.planCode}) chưa check-out. Vui lòng check-out trước khi check-in công việc mới.'),
                                  backgroundColor: Colors.red.shade700,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              return;
                            }
                            CheckInModalBottomSheet.show(
                              context,
                              taskName: plan.taskName,
                              locationName: plan.location,
                              targetLatitude: plan.latitude,
                              targetLongitude: plan.longitude,
                              onConfirmCheckIn: (photoFile, lat, lng) async {
                                String? evidenceId;
                                try {
                                  final ev = await EvidenceApiService().upload(photoFile);
                                  evidenceId = ev.evidenceId;
                                } catch (_) {}
                                await taskProvider.checkIn(
                                  plan.planId,
                                  user.id,
                                  checkInEvidenceId: evidenceId,
                                  latitude: lat,
                                  longitude: lng,
                                );
                              },
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
