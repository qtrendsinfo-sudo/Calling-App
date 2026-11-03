import '../entities/profile_entity.dart';
import '../entities/user_connection_entity.dart';

abstract class ConnectionRepository {
  Future<List<UserConnectionEntity>> getConnections();
  Future<List<UserConnectionEntity>> getIncomingRequests();
  Future<List<UserConnectionEntity>> getOutgoingRequests();
  Future<void> sendConnectionRequest(String targetUserId);
  Future<void> acceptConnectionRequest(String connectionId);
  Future<void> rejectConnectionRequest(String connectionId);
  Future<void> cancelConnectionRequest(String connectionId);
  Future<void> removeConnection(String connectionId);
  Future<void> blockUser(String targetUserId);
  Future<void> unblockUser(String targetUserId);
  Future<List<ProfileEntity>> getBlockedUsers();
  Future<RelationshipStatus> getRelationshipStatus(String targetUserId);
}
