import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../../../../domain/repositories/profile_repository.dart';
import '../../profile/presentation/controllers/profile_controller.dart';

class UserSearchState {
  final bool isLoading;
  final bool isLoadingMore;
  final String query;
  final List<ProfileEntity> results;
  final String? errorMessage;
  final bool hasReachedEnd;

  const UserSearchState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.query = '',
    this.results = const [],
    this.errorMessage,
    this.hasReachedEnd = false,
  });

  UserSearchState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? query,
    List<ProfileEntity>? results,
    String? errorMessage,
    bool? hasReachedEnd,
  }) {
    return UserSearchState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }
}

final userSearchControllerProvider =
    StateNotifierProvider<UserSearchController, UserSearchState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return UserSearchController(repository);
});

class UserSearchController extends StateNotifier<UserSearchState> {
  final ProfileRepository _repository;
  Timer? _debounceTimer;
  static const int _pageSize = 20;

  UserSearchController(this._repository) : super(const UserSearchState());

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      state = const UserSearchState();
      return;
    }

    state = state.copyWith(query: trimmed, isLoading: true, errorMessage: null);

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      await _executeSearch(trimmed, offset: 0);
    });
  }

  Future<void> _executeSearch(String query, {required int offset}) async {
    try {
      final results = await _repository.searchUsers(
        query: query,
        limit: _pageSize,
        offset: offset,
      );

      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        results: offset == 0 ? results : [...state.results, ...results],
        hasReachedEnd: results.length < _pageSize,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd || state.query.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    await _executeSearch(state.query, offset: state.results.length);
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = const UserSearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
