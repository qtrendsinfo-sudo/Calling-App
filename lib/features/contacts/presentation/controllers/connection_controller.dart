import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../domain/repositories/connection_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/connection_repository_impl.dart';
import 'connection_state.dart';

final connectionControllerProvider =
    StateNotifierProvider<ConnectionController, ConnectionState>((ref) {
  final repository = ref.watch(connectionRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ConnectionController(repository, userId);
});

class ConnectionController extends StateNotifier<ConnectionState> {
  final ConnectionRepository _repository;
  final String? _currentUserId;

  ConnectionController(this._repository, this._currentUserId) : super(ConnectionState.initial()) {
    if (_currentUserId != null) {
      loadAll();
    }
  }

  Future<void> loadAll() async {
    state = state.copyWith(status: ConnectionTabStatus.loading, errorMessage: null);
    try {
      final results = await Future.wait([
        _repository.getConnections(),
        _repository.getIncomingRequests(),
        _repository.getOutgoingRequests(),
        _repository.getBlockedUsers(),
      ]);

      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        connections: results[0] as List<dynamic>,
        incomingRequests: results[1] as List<dynamic>,
        outgoingRequests: results[2] as List<dynamic>,
        blockedUsers: results[3] as List<dynamic>,
      );
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.error,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<bool> sendRequest(String targetUserId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.sendConnectionRequest(targetUserId);
      await loadAll();
      state = state.copyWith(successMessage: 'Connection request sent successfully.');
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      return false;
    }
  }

  Future<void> acceptRequest(String connectionId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.acceptConnectionRequest(connectionId);
      await loadAll();
      state = state.copyWith(successMessage: 'Connection accepted.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> rejectRequest(String connectionId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.rejectConnectionRequest(connectionId);
      await loadAll();
      state = state.copyWith(successMessage: 'Connection request declined.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> cancelRequest(String connectionId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.cancelConnectionRequest(connectionId);
      await loadAll();
      state = state.copyWith(successMessage: 'Connection request cancelled.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> removeConnection(String connectionId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.removeConnection(connectionId);
      await loadAll();
      state = state.copyWith(successMessage: 'Connection removed.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> blockUser(String targetUserId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.blockUser(targetUserId);
      await loadAll();
      state = state.copyWith(successMessage: 'User has been blocked.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    state = state.copyWith(status: ConnectionTabStatus.actionInProgress, errorMessage: null);
    try {
      await _repository.unblockUser(targetUserId);
      await loadAll();
      state = state.copyWith(successMessage: 'User has been unblocked.');
    } catch (e) {
      state = state.copyWith(
        status: ConnectionTabStatus.loaded,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
