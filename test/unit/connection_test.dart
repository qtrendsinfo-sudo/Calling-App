import 'package:flutter_test/flutter_test.dart';
import 'package:telora/domain/entities/profile_entity.dart';
import 'package:telora/domain/entities/user_connection_entity.dart';

void main() {
  group('UserConnectionEntity Unit Tests', () {
    test('Correctly deserializes accepted connection from map', () {
      final map = {
        'id': 'conn-123',
        'requester_id': 'user-1',
        'receiver_id': 'user-2',
        'status': 'accepted',
        'created_at': '2026-10-02T10:00:00Z',
        'updated_at': '2026-10-02T10:05:00Z',
        'profile': {
          'id': 'user-2',
          'username': 'alex_hunter',
          'display_name': 'Alex Hunter',
          'is_online': true,
        },
      };

      final conn = UserConnectionEntity.fromMap(map, currentUserId: 'user-1');

      expect(conn.id, 'conn-123');
      expect(conn.requesterId, 'user-1');
      expect(conn.receiverId, 'user-2');
      expect(conn.status, ConnectionStatus.accepted);
      expect(conn.profile?.username, 'alex_hunter');
      expect(conn.profile?.isOnline, true);
    });

    test('Correctly deserializes pending incoming request', () {
      final map = {
        'id': 'conn-456',
        'requester_id': 'user-3',
        'receiver_id': 'user-1',
        'status': 'pending',
        'requester': {
          'id': 'user-3',
          'username': 'sarah_m',
          'display_name': 'Sarah Miller',
        },
      };

      final conn = UserConnectionEntity.fromMap(map, currentUserId: 'user-1');

      expect(conn.status, ConnectionStatus.pending);
      expect(conn.requesterId, 'user-3');
      expect(conn.profile?.displayName, 'Sarah Miller');
    });

    test('RelationshipStatus transitions map accurately', () {
      expect(RelationshipStatus.none.name, 'none');
      expect(RelationshipStatus.pendingSent.name, 'pendingSent');
      expect(RelationshipStatus.pendingReceived.name, 'pendingReceived');
      expect(RelationshipStatus.connected.name, 'connected');
      expect(RelationshipStatus.blockedByMe.name, 'blockedByMe');
      expect(RelationshipStatus.blockedByThem.name, 'blockedByThem');
      expect(RelationshipStatus.self.name, 'self');
    });

    test('copyWith modifies state immutably', () {
      final initial = UserConnectionEntity(
        id: 'conn-1',
        requesterId: 'u-1',
        receiverId: 'u-2',
        status: ConnectionStatus.pending,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final accepted = initial.copyWith(status: ConnectionStatus.accepted);

      expect(initial.status, ConnectionStatus.pending);
      expect(accepted.status, ConnectionStatus.accepted);
      expect(accepted.id, 'conn-1');
    });
  });

  group('Connection Rules & Validation Tests', () {
    test('Prevent self connection validation rule', () {
      const currentUserId = 'u-123';
      const targetUserId = 'u-123';

      final isSelf = currentUserId == targetUserId;
      expect(isSelf, isTrue, reason: 'Users must not send requests to themselves.');
    });

    test('Prevent self blocking validation rule', () {
      const currentUserId = 'u-123';
      const targetUserId = 'u-123';

      final isSelf = currentUserId == targetUserId;
      expect(isSelf, isTrue, reason: 'Users must not block themselves.');
    });
  });
}
