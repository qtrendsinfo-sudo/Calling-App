import '../../../../domain/entities/profile_entity.dart';
import '../../../../domain/entities/user_connection_entity.dart';

enum ConnectionTabStatus {
  initial,
  loading,
  loaded,
  actionInProgress,
  error,
}

class ConnectionState {
  final ConnectionTabStatus status;
  final List<UserConnectionEntity> connections;
  final List<UserConnectionEntity> incomingRequests;
  final List<UserConnectionEntity> outgoingRequests;
  final List<ProfileEntity> blockedUsers;
  final String? errorMessage;
  final String? successMessage;

  const ConnectionState({
    required this.status,
    this.connections = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.blockedUsers = const [],
    this.errorMessage,
    this.successMessage,
  });

  factory ConnectionState.initial() => const ConnectionState(status: ConnectionTabStatus.initial);

  factory ConnectionState.loading() => const ConnectionState(status: ConnectionTabStatus.loading);

  ConnectionState copyWith({
    ConnectionTabStatus? status,
    List<UserConnectionEntity>? connections,
    List<UserConnectionEntity>? incomingRequests,
    List<UserConnectionEntity>? outgoingRequests,
    List<ProfileEntity>? blockedUsers,
    String? errorMessage,
    String? successMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      connections: connections ?? this.connections,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get isLoading => status == ConnectionTabStatus.loading;
  bool get isActionInProgress => status == ConnectionTabStatus.actionInProgress;
}
