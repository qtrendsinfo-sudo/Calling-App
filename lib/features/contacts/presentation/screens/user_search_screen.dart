import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../controllers/user_search_controller.dart';

/// Screen for searching and discovering Telora users worldwide.
class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(userSearchControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.searchUsers),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: AppStrings.searchHint,
                  prefixIcon: const Icon(AppIcons.search, color: AppColors.onSurfaceVariant),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(userSearchControllerProvider.notifier).clearSearch();
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {});
                  ref.read(userSearchControllerProvider.notifier).onQueryChanged(val);
                },
              ),
            ),

            // Content Area
            Expanded(
              child: _buildContent(searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(UserSearchState state) {
    if (state.isLoading && state.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.query.isEmpty) {
      return const TeloraEmptyState(
        icon: AppIcons.search,
        title: 'Discover People',
        description: 'Search for friends and colleagues by display name or @username.',
      );
    }

    if (state.results.isEmpty) {
      return const TeloraEmptyState(
        icon: Icons.person_search_outlined,
        title: AppStrings.noUsersFound,
        description: AppStrings.noUsersFoundDesc,
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      itemCount: state.results.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        if (index >= state.results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.m),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final profile = state.results[index];
        return TeloraCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.userProfile,
              arguments: profile,
            );
          },
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: profile.avatarUrl,
                displayName: profile.displayName,
                radius: 24,
                isOnline: profile.isOnline,
                showOnlineIndicator: true,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        profile.bio!,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}
