import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/app_router.dart';
import '../../domain/entities/document_queue_item.dart';
import '../providers/document_queue_providers.dart';
import '../widgets/document_queue_tile.dart';

/// Screen displaying the queue of documents pending review.
/// Documents are ordered oldest-first (longest-waiting reviewed first).
class DocumentQueueScreen extends ConsumerWidget {
  const DocumentQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentQueueNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          state.totalCount > 0
              ? 'Document Queue (${state.totalCount})'
              : 'Document Queue',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(documentQueueNotifierProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(context, ref, state, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DocumentQueueState state,
    ThemeData theme,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              state.error ?? 'Failed to load document queue',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(documentQueueNotifierProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No documents pending review',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All documents have been reviewed',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(documentQueueNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.documents.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.documents.length) {
            // Load more trigger
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(documentQueueNotifierProvider.notifier)
                  .loadNextPage();
            });
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = state.documents[index];
          return DocumentQueueTile(
            item: item,
            onTap: () => _navigateToReview(context, item),
          );
        },
      ),
    );
  }

  void _navigateToReview(BuildContext context, DocumentQueueItem item) {
    context.goToDocumentReview(
      documentId: item.document.id,
      extra: item,
    );
  }
}
