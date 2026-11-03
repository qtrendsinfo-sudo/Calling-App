import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/user_connection_entity.dart';
import '../../../../presentation/common_widgets/telora_button.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../controllers/connection_controller.dart';
import '../controllers/connection_state.dart';

/// Comprehensive Contacts and Connection Requests Screen.
class ContactsTabScreen extends ConsumerStatefulWidget {
  const ContactsTabScreen({super.key});

  @override
  ConsumerState<ContactsTabScreen> createState() => _ContactsTabScreenState();
}

class _ContactsTabScreenState extends ConsumerState<ContactsTabScreen> {
  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.navContacts),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppStrings.connections),
                    if (connectionState.connections.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${connectionState.connections.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppStrings.connectionRequests),
                    if (connectionState.incomingRequests.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${connectionState.incomingRequests.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(AppIcons.search, color: AppColors.onSurfaceVariant),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
              tooltip: AppStrings.searchUsers,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.read(connectionControllerProvider.notifier).loadAll(),
          child: TabBarView(
            children: [
              _buildConnectionsList(connectionState),
              _buildRequestsList(connectionState),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
          backgroundColor: AppColors.tertiary,
          foregroundColor: AppColors.onTertiary,
          elevation: 2,
          tooltip: AppStrings.searchUsers,
          child: const Icon(Icons.person_add_rounded, size: 24),
        ),
      ),
    );
  }

  Widget _buildConnectionsList(ConnectionState state) {
    if (state.isLoading && state.connections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.connections.isEmpty) {
      return Padding(
        padding: AppSpacing.screenPadding,
        child: TeloraEmptyState(
          icon: AppIcons.contactsOutlined,
          title: AppStrings.emptyContactsTitle,
          description: AppStrings.emptyContactsDesc,
          actionText: 'Find People',
          onAction: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: state.connections.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final conn = state.connections[index];
        final profile = conn.profile;
        final name = profile?.displayName ?? 'User';
        final username = profile?.username ?? 'user';

        return TeloraCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
          onTap: profile != null
              ? () => Navigator.of(context).pushNamed(AppRoutes.userProfile, arguments: profile)
              : null,
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: profile?.avatarUrl,
                displayName: name,
                radius: 24,
                isOnline: profile?.isOnline ?? false,
                showOnlineIndicator: true,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@$username',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.chats, size: 20, color: AppColors.primary),
                tooltip: AppStrings.message,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chat with $name ready.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsList(ConnectionState state) {
    if (state.isLoading && state.incomingRequests.isEmpty && state.outgoingRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.incomingRequests.isEmpty && state.outgoingRequests.isEmpty) {
      return const Padding(
        padding: AppSpacing.screenPadding,
        child: TeloraEmptyState(
          icon: Icons.mark_email_unread_outlined,
          title: 'No Pending Requests',
          description: 'When people send you connection requests, they will appear here.',
        ),
      );
    }

    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        // Incoming Requests Section
        if (state.incomingRequests.isNotEmpty) ...[
          Text(
            AppStrings.incomingRequests.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          ...state.incomingRequests.map((req) {
            final profile = req.profile;
            final name = profile?.displayName ?? 'User';
            final username = profile?.username ?? 'user';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: TeloraCard(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  children: [
                    Row(
                      children: [
                        UserAvatar(
                          avatarUrl: profile?.avatarUrl,
                          displayName: name,
                          radius: 22,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '@$username',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: TeloraButton(
                            text: AppStrings.accept,
                            height: 38,
                            onPressed: () => ref
                                .read(connectionControllerProvider.notifier)
                                .acceptRequest(req.id),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: TeloraOutlinedButton(
                            text: AppStrings.reject,
                            height: 38,
                            onPressed: () => ref
                                .read(connectionControllerProvider.notifier)
                                .rejectRequest(req.id),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.l),
        ],

        // Sent Requests Section
        if (state.outgoingRequests.isNotEmpty) ...[
          Text(
            AppStrings.sentRequests.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          ...state.outgoingRequests.map((req) {
            final profile = req.profile;
            final name = profile?.displayName ?? 'User';
            final username = profile?.username ?? 'user';

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: TeloraCard(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
                child: Row(
                  children: [
                    UserAvatar(
                      avatarUrl: profile?.avatarUrl,
                      displayName: name,
                      radius: 22,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '@$username',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref
                          .read(connectionControllerProvider.notifier)
                          .cancelRequest(req.id),
                      child: Text(
                        AppStrings.cancelRequest,
                        style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
