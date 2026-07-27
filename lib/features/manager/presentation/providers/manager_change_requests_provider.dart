import 'package:flutter/material.dart';
import '../../data/models/change_request.dart';
import '../../data/services/manager_change_request_service.dart';

class ManagerChangeRequestsProvider extends ChangeNotifier {
  final ManagerChangeRequestService _service;

  bool _isLoading = true;
  bool _actionLoading = false;
  String? _errorMessage;
  String? _actionError;

  List<ChangeRequest> _requests = [];
  ChangeRequest? _selectedRequest;

  bool get isLoading => _isLoading;
  bool get actionLoading => _actionLoading;
  String? get errorMessage => _errorMessage;
  String? get actionError => _actionError;

  List<ChangeRequest> get requests => _requests;
  ChangeRequest? get selectedRequest => _selectedRequest;

  ManagerChangeRequestsProvider({ManagerChangeRequestService? service})
      : _service = service ?? ManagerChangeRequestService();

  Future<void> fetchRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _requests = await _service.getChangeRequests(status: 'pending');
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
    }
    notifyListeners();
  }

  void selectRequest(ChangeRequest? req) {
    _selectedRequest = req;
    _actionError = null;
    notifyListeners();
  }

  Future<bool> handleDecision(String decision) async {
    if (_selectedRequest == null) return false;

    _actionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      await _service.approveChangeRequest(_selectedRequest!.changeRequestId, decision);
      _selectedRequest = null;
      await fetchRequests();
      _actionLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _actionError = e.toString().replaceAll('Exception: ', '');
      _actionLoading = false;
      notifyListeners();
      return false;
    }
  }
}
