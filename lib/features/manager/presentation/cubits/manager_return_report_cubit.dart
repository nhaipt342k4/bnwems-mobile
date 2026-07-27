import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/manager_inventory_service.dart';
import 'manager_return_report_state.dart';

class ManagerReturnReportCubit extends Cubit<ManagerReturnReportState> {
  final ManagerInventoryService _inventoryService;

  ManagerReturnReportCubit({ManagerInventoryService? inventoryService})
      : _inventoryService = inventoryService ?? ManagerInventoryService(),
        super(ManagerReturnReportInitial());

  Future<void> loadReturnReports() async {
    emit(ManagerReturnReportLoading());

    try {
      final reports = await _inventoryService.getReturnReports();
      emit(ManagerReturnReportListLoaded(reports));
    } catch (e) {
      emit(ManagerReturnReportError(e.toString()));
    }
  }

  Future<void> loadReturnReportDetail(String reportId) async {
    emit(ManagerReturnReportLoading());

    try {
      final report = await _inventoryService.getReturnReport(reportId);
      emit(ManagerReturnReportDetailLoaded(report));
    } catch (e) {
      emit(ManagerReturnReportError(e.toString()));
    }
  }

  Future<bool> confirmReturnReport(String reportId) async {
    try {
      await _inventoryService.confirmReturnReport(reportId);
      await loadReturnReportDetail(reportId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
