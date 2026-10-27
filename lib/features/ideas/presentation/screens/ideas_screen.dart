import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../../domain/models/event_idea.dart';
import '../../domain/services/ideas_generator_service.dart';

class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen> {
  bool _ecoFriendlyOnly = false;
  IdeaComplexity? _selectedComplexity;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.lightbulb_outline,
            title: 'No Event Active',
            message: 'Create an event to view personalized ideas tailored to your theme.',
          );
        }

        final ideas = aggregate.ideas;
        final criteria = IdeasFilterCriteria(
          ecoFriendlyOnly: _ecoFriendlyOnly,
          maxComplexity: _selectedComplexity,
          category: _selectedCategory,
          searchQuery: _searchController.text.trim(),
        );

        final filteredIdeas = IdeasGeneratorService.filterIdeas(ideas, criteria);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personalized Ideas Generator', style: theme.textTheme.headlineMedium),
                  Text(
                    'Curated concepts adapted to "${aggregate.event.name}" (${aggregate.event.theme})',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Filter Controls Card
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search ideas, decor, activities...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilterChip(
                          avatar: const Icon(Icons.eco, size: 16, color: AppColors.success),
                          label: const Text('Eco-Friendly Only'),
                          selected: _ecoFriendlyOnly,
                          onSelected: (val) => setState(() => _ecoFriendlyOnly = val),
                        ),
                        DropdownButton<String>(
                          value: _selectedCategory,
                          underline: const SizedBox.shrink(),
                          items: ['All', 'Decor', 'Food & Drink', 'Entertainment', 'Contingency', 'Accessibility', 'Activity']
                              .map((c) => DropdownMenuItem(value: c, child: Text('Category: $c')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                        DropdownButton<IdeaComplexity?>(
                          value: _selectedComplexity,
                          hint: const Text('Complexity: Any'),
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Complexity: Any')),
                            ...IdeaComplexity.values.map(
                              (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
                            ),
                          ],
                          onChanged: (val) => setState(() => _selectedComplexity = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ideas Grid / List
              if (filteredIdeas.isEmpty)
                const EmptyStateView(
                  icon: Icons.lightbulb_outline,
                  title: 'No Matching Ideas',
                  message: 'Adjust your search filters to explore other concepts.',
                )
              else
                ...filteredIdeas.map((idea) => _buildIdeaCard(context, idea)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading ideas: $e')),
    );
  }

  Widget _buildIdeaCard(BuildContext context, EventIdea idea) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AccessibleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              idea.title,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (idea.isEcoFriendly)
                            const StatusBadge(
                              label: 'Sustainable',
                              icon: Icons.eco,
                              type: BadgeType.success,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${idea.category} • Cost: ${idea.estimatedCostRange} • ${idea.complexity.displayName}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    idea.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: idea.isBookmarked ? AppColors.secondary : null,
                  ),
                  tooltip: idea.isBookmarked ? 'Remove Bookmark' : 'Bookmark Idea',
                  onPressed: () {
                    ref.read(activeEventProvider.notifier).toggleBookmarkIdea(idea.id);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(idea.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),

            // Why it matches banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Why it matches your event: ${idea.matchReason}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Benefits and limitations
            if (idea.benefits.isNotEmpty) ...[
              const Text('Key Benefits:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...idea.benefits.map((b) => Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text('✓ $b', style: theme.textTheme.bodySmall),
                  )),
              const SizedBox(height: 8),
            ],

            // Add to Tasks Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Suitability: ${idea.guestSuitability}',
                  style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
                ElevatedButton.icon(
                  onPressed: idea.isAddedToTasks
                      ? null
                      : () async {
                          await ref.read(activeEventProvider.notifier).addIdeaToTasks(idea);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.success,
                                content: Text('✓ Added "${idea.title}" to Timeline Tasks!'),
                              ),
                            );
                          }
                        },
                  icon: Icon(idea.isAddedToTasks ? Icons.check : Icons.add_task, size: 16),
                  label: Text(idea.isAddedToTasks ? 'Added to Tasks' : 'Add to Event Tasks'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
