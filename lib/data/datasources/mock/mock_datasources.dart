import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/call_entity.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/signaling_message.dart';
import '../../../domain/entities/user_connection_entity.dart';
import '../remote/supabase_auth_datasource.dart';
import '../remote/supabase_call_datasource.dart';
import '../remote/supabase_chat_datasource.dart';
import '../remote/supabase_connection_datasource.dart';
import '../remote/supabase_profile_datasource.dart';

/// Pre-populated Demo Profiles for Sandbox & Web Preview.
final mockAlice = ProfileEntity(
  id: '00000000-0000-0000-0000-000000000001',
  username: 'alice',
  displayName: 'Alice Al-Mansoor',
  bio: 'Exploring Telora Web Preview & Real-time Calling 🚀',
  isOnline: true,
  createdAt: DateTime.now().subtract(const Duration(days: 30)),
);

final mockBob = ProfileEntity(
  id: '00000000-0000-0000-0000-000000000002',
  username: 'bob',
  displayName: 'Bob Davis',
  bio: 'Ready for WebRTC voice & video calls! 📞',
  isOnline: true,
  createdAt: DateTime.now().subtract(const Duration(days: 20)),
);

final mockCharlie = ProfileEntity(
  id: '00000000-0000-0000-0000-000000000003',
  username: 'charlie',
  displayName: 'Charlie Vance',
  bio: 'Flutter & WebRTC enthusiast 💻',
  isOnline: false,
  lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
  createdAt: DateTime.now().subtract(const Duration(days: 10)),
);

final mockSarah = ProfileEntity(
  id: '00000000-0000-0000-0000-000000000004',
  username: 'sarah',
  displayName: 'Sarah Miller',
  bio: 'Saying hello from Dubai 🌟',
  isOnline: true,
  createdAt: DateTime.now().subtract(const Duration(days: 5)),
);

/// -------------------------------------------------------------
/// Mock Auth Remote DataSource
/// -------------------------------------------------------------
class MockAuthDataSourceImpl implements AuthRemoteDataSource {
  static final MockAuthDataSourceImpl instance = MockAuthDataSourceImpl._();
  MockAuthDataSourceImpl._();
  factory MockAuthDataSourceImpl() => instance;

  final _authController = StreamController<AuthState>.broadcast();
  User? _mockUser = User(
    id: '00000000-0000-0000-0000-000000000001',
    appMetadata: const {},
    userMetadata: const {'username': 'alice', 'display_name': 'Alice Al-Mansoor'},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: 'alice@telora.app',
  );

  Session? _mockSession = Session(
    accessToken: 'mock-access-token',
    tokenType: 'bearer',
    user: User(
      id: '00000000-0000-0000-0000-000000000001',
      appMetadata: const {},
      userMetadata: const {'username': 'alice', 'display_name': 'Alice Al-Mansoor'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: 'alice@telora.app',
    ),
  );

  @override
  Stream<AuthState> get onAuthStateChange => _authController.stream;

  @override
  User? get currentUser => _mockUser;

  @override
  Session? get currentSession => _mockSession;

  @override
  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    _mockUser = User(
      id: '00000000-0000-0000-0000-000000000001',
      appMetadata: const {},
      userMetadata: const {'username': 'alice', 'display_name': 'Alice Al-Mansoor'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email.isNotEmpty ? email : 'alice@telora.app',
    );
    _mockSession = Session(accessToken: 'mock-token', tokenType: 'bearer', user: _mockUser!);
    _authController.add(AuthState(AuthChangeEvent.signedIn, _mockSession));
    return AuthResponse(session: _mockSession, user: _mockUser);
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    return signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<UserResponse> updateUserPassword(String newPassword) async {
    return UserResponse.fromJson({'user': _mockUser?.toJson()});
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
    _mockSession = null;
    _authController.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Future<void> deleteAccount() async {
    await signOut();
  }
}

/// -------------------------------------------------------------
/// Mock Profile Remote DataSource
/// -------------------------------------------------------------
class MockProfileDataSourceImpl implements ProfileRemoteDataSource {
  static final MockProfileDataSourceImpl instance = MockProfileDataSourceImpl._();
  MockProfileDataSourceImpl._();
  factory MockProfileDataSourceImpl() => instance;

  final Map<String, ProfileEntity> _profiles = {
    mockAlice.id: mockAlice,
    mockBob.id: mockBob,
    mockCharlie.id: mockCharlie,
    mockSarah.id: mockSarah,
  };

  @override
  Future<ProfileEntity?> getMyProfile() async => _profiles[mockAlice.id];

  @override
  Future<ProfileEntity?> getProfile(String userId) async => _profiles[userId];

  @override
  Future<ProfileEntity> updateProfile({
    required String userId,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final existing = _profiles[userId] ?? mockAlice;
    final updated = existing.copyWith(
      displayName: displayName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
    );
    _profiles[userId] = updated;
    return updated;
  }

  @override
  Future<List<ProfileEntity>> searchUsers({required String query, int limit = 20, int offset = 0}) async {
    final q = query.toLowerCase();
    return _profiles.values.where((p) {
      return p.displayName.toLowerCase().contains(q) || (p.username?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<String> uploadAvatar({required String userId, required List<int> imageBytes, required String fileExtension}) async {
    return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200';
  }

  @override
  Future<void> deleteAvatar({required String userId}) async {
    if (_profiles.containsKey(userId)) {
      _profiles[userId] = _profiles[userId]!.copyWith(avatarUrl: null);
    }
  }

  @override
  Future<bool> checkUsernameAvailability(String username) async => true;

  @override
  Future<void> updateOnlineStatus({required String userId, required bool isOnline}) async {}
}

/// -------------------------------------------------------------
/// Mock Connection Remote DataSource
/// -------------------------------------------------------------
class MockConnectionDataSourceImpl implements ConnectionRemoteDataSource {
  static final MockConnectionDataSourceImpl instance = MockConnectionDataSourceImpl._();
  MockConnectionDataSourceImpl._();
  factory MockConnectionDataSourceImpl() => instance;

  final List<UserConnectionEntity> _connections = [
    UserConnectionEntity(
      id: 'conn-1',
      requesterId: mockAlice.id,
      receiverId: mockBob.id,
      status: ConnectionStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      otherUser: mockBob,
    ),
    UserConnectionEntity(
      id: 'conn-2',
      requesterId: mockCharlie.id,
      receiverId: mockAlice.id,
      status: ConnectionStatus.accepted,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      otherUser: mockCharlie,
    ),
  ];

  final List<UserConnectionEntity> _incomingRequests = [
    UserConnectionEntity(
      id: 'conn-3',
      requesterId: mockSarah.id,
      receiverId: mockAlice.id,
      status: ConnectionStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
      otherUser: mockSarah,
    ),
  ];

  final List<ProfileEntity> _blockedUsers = [];

  @override
  Future<List<UserConnectionEntity>> getConnections() async => List.from(_connections);

  @override
  Future<List<UserConnectionEntity>> getIncomingRequests() async => List.from(_incomingRequests);

  @override
  Future<List<UserConnectionEntity>> getOutgoingRequests() async => [];

  @override
  Future<void> sendConnectionRequest(String targetUserId) async {}

  @override
  Future<void> acceptConnectionRequest(String connectionId) async {
    final idx = _incomingRequests.indexWhere((c) => c.id == connectionId);
    if (idx != -1) {
      final req = _incomingRequests.removeAt(idx);
      _connections.add(req.copyWith(status: ConnectionStatus.accepted));
    }
  }

  @override
  Future<void> rejectConnectionRequest(String connectionId) async {
    _incomingRequests.removeWhere((c) => c.id == connectionId);
  }

  @override
  Future<void> cancelConnectionRequest(String connectionId) async {}

  @override
  Future<void> removeConnection(String connectionId) async {
    _connections.removeWhere((c) => c.id == connectionId);
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    _connections.removeWhere((c) => c.otherUser?.id == targetUserId);
    final p = MockProfileDataSourceImpl.instance._profiles[targetUserId];
    if (p != null) _blockedUsers.add(p);
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    _blockedUsers.removeWhere((p) => p.id == targetUserId);
  }

  @override
  Future<List<ProfileEntity>> getBlockedUsers() async => List.from(_blockedUsers);

  @override
  Future<RelationshipStatus> getRelationshipStatus(String targetUserId) async {
    if (_blockedUsers.any((p) => p.id == targetUserId)) return RelationshipStatus.blockedByMe;
    if (_connections.any((c) => c.otherUser?.id == targetUserId)) return RelationshipStatus.connected;
    if (_incomingRequests.any((c) => c.otherUser?.id == targetUserId)) return RelationshipStatus.pendingIncoming;
    return RelationshipStatus.none;
  }
}

/// -------------------------------------------------------------
/// Mock Chat Remote DataSource
/// -------------------------------------------------------------
class MockChatDataSourceImpl implements ChatRemoteDataSource {
  static final MockChatDataSourceImpl instance = MockChatDataSourceImpl._();
  MockChatDataSourceImpl._();
  factory MockChatDataSourceImpl() => instance;

  final Map<String, StreamController<MessageEntity>> _messageControllers = {};

  final List<MessageEntity> _bobMessages = [
    MessageEntity(
      id: 'msg-1',
      conversationId: 'conv-bob',
      senderId: mockBob.id,
      content: 'Hello Alice! Welcome to Telora Web Preview.',
      type: MessageType.text,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      senderProfile: mockBob,
    ),
    MessageEntity(
      id: 'msg-2',
      conversationId: 'conv-bob',
      senderId: mockAlice.id,
      content: 'Hi Bob! Glad to test the messaging interface.',
      type: MessageType.text,
      createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      senderProfile: mockAlice,
    ),
    MessageEntity(
      id: 'msg-3',
      conversationId: 'conv-bob',
      senderId: mockBob.id,
      content: 'Tap the Voice Call or Video Call icon in the top bar to test our WebRTC calling engine! 📞',
      type: MessageType.text,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      senderProfile: mockBob,
    ),
  ];

  @override
  Future<List<ConversationEntity>> getConversations() async {
    return [
      ConversationEntity(
        id: 'conv-bob',
        type: ConversationType.direct,
        updatedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        otherMember: mockBob,
        lastMessage: _bobMessages.last,
        unreadCount: 0,
      ),
      ConversationEntity(
        id: 'conv-charlie',
        type: ConversationType.direct,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        otherMember: mockCharlie,
        lastMessage: MessageEntity(
          id: 'msg-c1',
          conversationId: 'conv-charlie',
          senderId: mockCharlie.id,
          content: 'Looking forward to our team sync.',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          senderProfile: mockCharlie,
        ),
        unreadCount: 1,
      ),
    ];
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation(String recipientUserId) async {
    final convs = await getConversations();
    return convs.firstWhere(
      (c) => c.otherMember?.id == recipientUserId,
      orElse: () => ConversationEntity(
        id: 'conv-$recipientUserId',
        type: ConversationType.direct,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        otherMember: MockProfileDataSourceImpl.instance._profiles[recipientUserId] ?? mockBob,
      ),
    );
  }

  @override
  Future<List<MessageEntity>> getMessages({required String conversationId, int limit = 30, DateTime? before}) async {
    return List.from(_bobMessages.reversed);
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final msg = MessageEntity(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      senderId: mockAlice.id,
      content: content,
      type: type,
      createdAt: DateTime.now(),
      senderProfile: mockAlice,
    );
    _bobMessages.add(msg);
    _messageControllers[conversationId]?.add(msg);

    // Simulate auto-reply from Bob in demo mode
    Future.delayed(const Duration(milliseconds: 1200), () {
      final reply = MessageEntity(
        id: 'reply-${DateTime.now().millisecondsSinceEpoch}',
        conversationId: conversationId,
        senderId: mockBob.id,
        content: 'Received: "$content" 👍 (Web Sandbox Auto-Reply)',
        type: MessageType.text,
        createdAt: DateTime.now(),
        senderProfile: mockBob,
      );
      _bobMessages.add(reply);
      _messageControllers[conversationId]?.add(reply);
    });

    return msg;
  }

  @override
  Future<void> markAsRead(String conversationId) async {}

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    if (!_messageControllers.containsKey(conversationId)) {
      _messageControllers[conversationId] = StreamController<MessageEntity>.broadcast();
    }
    return _messageControllers[conversationId]!.stream;
  }
}

/// -------------------------------------------------------------
/// Mock Call Remote DataSource
/// -------------------------------------------------------------
class MockCallDataSourceImpl implements CallRemoteDataSource {
  static final MockCallDataSourceImpl instance = MockCallDataSourceImpl._();
  MockCallDataSourceImpl._();
  factory MockCallDataSourceImpl() => instance;

  final _incomingCallController = StreamController<CallEntity>.broadcast();
  final Map<String, StreamController<CallStatus>> _statusControllers = {};
  final Map<String, StreamController<SignalingMessage>> _signalingControllers = {};

  final List<CallEntity> _calls = [
    CallEntity(
      id: 'call-1',
      callerId: mockBob.id,
      receiverId: mockAlice.id,
      callType: CallType.video,
      status: CallStatus.connected,
      startedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      connectedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      endedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1, minutes: 57)),
      durationSeconds: 180,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      callerProfile: mockBob,
      receiverProfile: mockAlice,
    ),
    CallEntity(
      id: 'call-2',
      callerId: mockAlice.id,
      receiverId: mockCharlie.id,
      callType: CallType.voice,
      status: CallStatus.connected,
      startedAt: DateTime.now().subtract(const Duration(hours: 4)),
      connectedAt: DateTime.now().subtract(const Duration(hours: 4)),
      endedAt: DateTime.now().subtract(const Duration(hours: 3, minutes: 58)),
      durationSeconds: 120,
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      callerProfile: mockAlice,
      receiverProfile: mockCharlie,
    ),
    CallEntity(
      id: 'call-3',
      callerId: mockBob.id,
      receiverId: mockAlice.id,
      callType: CallType.voice,
      status: CallStatus.missed,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      callerProfile: mockBob,
      receiverProfile: mockAlice,
    ),
  ];

  @override
  Future<List<CallEntity>> getCallHistory() async => List.from(_calls);

  @override
  Stream<CallEntity> listenIncomingCalls() => _incomingCallController.stream;

  @override
  Stream<CallStatus> listenCallStatus(String callId) {
    if (!_statusControllers.containsKey(callId)) {
      _statusControllers[callId] = StreamController<CallStatus>.broadcast();
    }
    return _statusControllers[callId]!.stream;
  }

  @override
  Future<CallEntity> initiateCall({required String receiverId, required CallType type}) async {
    final receiverProfile = MockProfileDataSourceImpl.instance._profiles[receiverId] ?? mockBob;
    final call = CallEntity(
      id: 'call-${DateTime.now().millisecondsSinceEpoch}',
      callerId: mockAlice.id,
      receiverId: receiverId,
      callType: type,
      status: CallStatus.ringing,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
      callerProfile: mockAlice,
      receiverProfile: receiverProfile,
    );
    _calls.insert(0, call);

    // Simulate receiver answering after 1.5 seconds in preview mode
    Future.delayed(const Duration(milliseconds: 1500), () {
      _statusControllers[call.id]?.add(CallStatus.connected);

      // Simulate remote WebRTC answer signaling
      _signalingControllers[call.id]?.add(
        SignalingMessage(
          callId: call.id,
          senderId: receiverId,
          receiverId: mockAlice.id,
          type: SignalingType.answer,
          payload: {'sdp': 'v=0\r\no=mock-answer', 'type': 'answer'},
          timestamp: DateTime.now(),
        ),
      );
    });

    return call;
  }

  @override
  Future<void> updateCallStatus({required String callId, required CallStatus status}) async {
    final idx = _calls.indexWhere((c) => c.id == callId);
    if (idx != -1) {
      _calls[idx] = _calls[idx].copyWith(status: status);
    }
    _statusControllers[callId]?.add(status);
  }

  @override
  Future<void> sendSignaling(SignalingMessage message) async {
    _signalingControllers[message.callId]?.add(message);
  }

  @override
  Stream<SignalingMessage> listenSignaling(String callId) {
    if (!_signalingControllers.containsKey(callId)) {
      _signalingControllers[callId] = StreamController<SignalingMessage>.broadcast();
    }
    return _signalingControllers[callId]!.stream;
  }
}
