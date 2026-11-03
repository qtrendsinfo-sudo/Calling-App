import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/user_connection_entity.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/remote/supabase_connection_datasource.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final dataSource = ref.watch(connectionRemoteDataSourceProvider);
  return ConnectionRepositoryImpl(dataSource);
});

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionRemoteDataSource _dataSource;

  ConnectionRepositoryImpl(this._dataSource);

  @override
  Future<List<UserConnectionEntity>> getConnections() {
    return _dataSource.getConnections();
  }

  @override
  Future<List<UserConnectionEntity>> getIncomingRequests() {
    return _dataSource.getIncomingRequests();
  }

  @override
  Future<List<UserConnectionEntity>> getOutgoingRequests() {
    return _dataSource.getOutgoingRequests();
  }

  @override
  Future<void> sendConnectionRequest(String targetUserId) {
    return _dataSource.sendConnectionRequest(targetUserId);
  }

  @override
  Future<void> acceptConnectionRequest(String connectionId) {
    return _dataSource.acceptConnectionRequest(connectionId);
  }

  @override
  Future<void> rejectConnectionRequest(String connectionId) {
    return _dataSource.rejectConnectionRequest(connectionId);
  }

  @override
  Future<void> cancelConnectionRequest(String connectionId) {
    return _dataSource.cancelConnectionRequest(connectionId);
  }

  @override
  Future<void> removeConnection(String connectionId) {
    return _dataSource.removeConnection(connectionId);
  }

  @override
  Future<void> blockUser(String targetUserId) {
    return _dataSource.blockUser(targetUserId);
  }

  @override
  Future<void> unblockUser(String targetUserId) {
    return _dataSource.unblockUser(targetUserId);
  }

  @override
  Future<List<ProfileEntity>> getBlockedUsers() {
    return _dataSource.getBlockedUsers();
  }

  @override
  Future<RelationshipStatus> getRelationshipStatus(String targetUserId) {
    return _dataSource.getRelationshipStatus(targetUserId);
  }
}
