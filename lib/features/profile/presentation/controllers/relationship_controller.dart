import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/user_connection_entity.dart';
import '../../../../domain/repositories/connection_repository.dart';
import '../../../data/repositories/connection_repository_impl.dart';

final relationshipStatusProvider =
    FutureProvider.autoDispose.family<RelationshipStatus, String>((ref, targetUserId) async {
  final repository = ref.watch(connectionRepositoryProvider);
  return repository.getRelationshipStatus(targetUserId);
});
