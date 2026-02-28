// lib/features/messages/presentation/widgets/user_selector.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/messages_providers.dart';
import '../../domain/entities/message_entity.dart';

class UserSelector extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Function(MessageUserInfo) onSelect;
  final String? filterRole;
  final String? title;

  const UserSelector({
    super.key,
    required this.scrollController,
    required this.onSelect,
    this.filterRole,
    this.title,
  });

  @override
  ConsumerState<UserSelector> createState() => _UserSelectorState();
}

class _UserSelectorState extends ConsumerState<UserSelector> {
  final _searchController = TextEditingController();
  String? _selectedRole;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.filterRole;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(userSearchNotifierProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? 'Select Recipient',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, phone, or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(userSearchNotifierProvider.notifier).clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() => _isSearching = value.isNotEmpty);
                  if (value.length >= 2) {
                    ref.read(userSearchNotifierProvider.notifier).search(
                          value,
                          role: _selectedRole,
                        );
                  } else {
                    ref.read(userSearchNotifierProvider.notifier).clear();
                  }
                },
                autofocus: true,
              ),
              const SizedBox(height: 12),

              // Role filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedRole == null,
                      onSelected: (_) {
                        setState(() => _selectedRole = null);
                        if (_searchController.text.isNotEmpty) {
                          ref.read(userSearchNotifierProvider.notifier).search(
                                _searchController.text,
                                role: null,
                              );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Drivers'),
                      selected: _selectedRole == 'Driver',
                      onSelected: (_) {
                        setState(() => _selectedRole = _selectedRole == 'Driver' ? null : 'Driver');
                        if (_searchController.text.isNotEmpty) {
                          ref.read(userSearchNotifierProvider.notifier).search(
                                _searchController.text,
                                role: _selectedRole,
                              );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Shippers'),
                      selected: _selectedRole == 'Shipper',
                      onSelected: (_) {
                        setState(() => _selectedRole = _selectedRole == 'Shipper' ? null : 'Shipper');
                        if (_searchController.text.isNotEmpty) {
                          ref.read(userSearchNotifierProvider.notifier).search(
                                _searchController.text,
                                role: _selectedRole,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Results
        Expanded(
          child: _buildResults(context, searchState),
        ),
      ],
    );
  }

  Widget _buildResults(BuildContext context, UserSearchState state) {
    final theme = Theme.of(context);

    if (!_isSearching || _searchController.text.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching
                  ? 'Type at least 2 characters to search'
                  : 'Start typing to search users',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search by name, phone number, or email',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (state.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error searching users',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(userSearchNotifierProvider.notifier).search(
                      _searchController.text,
                      role: _selectedRole,
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      itemCount: state.results.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final user = state.results[index];
        return UserTile(
          user: user,
          onTap: () => widget.onSelect(user),
        );
      },
    );
  }
}

/// Individual user tile in search results
class UserTile extends StatelessWidget {
  final MessageUserInfo user;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage:
            user.profilePhotoUrl != null ? CachedNetworkImageProvider(user.profilePhotoUrl!) : null,
        child: user.profilePhotoUrl == null
            ? Text(
                user.initials,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.phone != null)
            Text(
              user.phone!,
              style: theme.textTheme.bodySmall,
            ),
          if (user.role != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role!, theme).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _getRoleColor(user.role!, theme),
                ),
              ),
            ),
        ],
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      isThreeLine: user.phone != null && user.role != null,
      onTap: onTap,
    );
  }

  Color _getRoleColor(String role, ThemeData theme) {
    switch (role.toLowerCase()) {
      case 'driver':
        return Colors.blue;
      case 'shipper':
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }
}

/// Multi-select user selector for broadcasts
class MultiUserSelector extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final List<MessageUserInfo> selectedUsers;
  final Function(List<MessageUserInfo>) onSelectionChanged;

  const MultiUserSelector({
    super.key,
    required this.scrollController,
    required this.selectedUsers,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<MultiUserSelector> createState() => _MultiUserSelectorState();
}

class _MultiUserSelectorState extends ConsumerState<MultiUserSelector> {
  final _searchController = TextEditingController();
  late List<MessageUserInfo> _selected;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUser(MessageUserInfo user) {
    setState(() {
      if (_selected.any((u) => u.id == user.id)) {
        _selected.removeWhere((u) => u.id == user.id);
      } else {
        _selected.add(user);
      }
    });
    widget.onSelectionChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(userSearchNotifierProvider);

    return Column(
      children: [
        // Header with selected count
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Recipients',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (_selected.isNotEmpty)
                          Text(
                            '${_selected.length} selected',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => _selected.clear());
                        widget.onSelectionChanged(_selected);
                      },
                      child: const Text('Clear All'),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (value) {
                  if (value.length >= 2) {
                    ref.read(userSearchNotifierProvider.notifier).search(
                          value,
                          role: _selectedRole,
                        );
                  }
                },
              ),
            ],
          ),
        ),

        // Selected users chips
        if (_selected.isNotEmpty)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final user = _selected[index];
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage: user.profilePhotoUrl != null
                        ? CachedNetworkImageProvider(user.profilePhotoUrl!)
                        : null,
                    child: user.profilePhotoUrl == null
                        ? Text(user.initials[0])
                        : null,
                  ),
                  label: Text(user.displayName),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _toggleUser(user),
                );
              },
            ),
          ),

        const Divider(),

        // Results
        Expanded(
          child: searchState.results.isEmpty && _searchController.text.isEmpty
              ? Center(
                  child: Text(
                    'Search for users to add',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: searchState.results.length,
                  itemBuilder: (context, index) {
                    final user = searchState.results[index];
                    final isSelected = _selected.any((u) => u.id == user.id);

                    return UserTile(
                      user: user,
                      onTap: () => _toggleUser(user),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleUser(user),
                      ),
                    );
                  },
                ),
        ),

        // Done button
        if (_selected.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text('Done (${_selected.length} selected)'),
            ),
          ),
      ],
    );
  }
}
