import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../providers/event_providers.dart';

class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return activeEventAsync.when(
      data: (aggregate) {
        if (aggregate == null) {
          return const EmptyStateView(
            icon: Icons.event_busy,
            title: 'No Active Event',
            message: 'Please create an event to inspect its profile details.',
          );
        }

        final event = aggregate.event;
        final days = DateFormatter.daysRemaining(event.date);

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: width > 900 ? 36 : 16,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Event Profile & Concept', style: theme.textTheme.headlineMedium),
                      Text('Core specifications and architectural guidelines', style: theme.textTheme.bodySmall),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/impact'),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Simulate / Edit Changes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Overview Header Card
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(
                          label: event.category.displayName,
                          icon: Icons.celebration,
                          type: BadgeType.info,
                        ),
                        StatusBadge(
                          label: days >= 0 ? '$days days remaining' : 'Event concluded',
                          type: days <= 7 ? BadgeType.error : BadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.name,
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Target Date: ${DateFormatter.formatFullDate(event.date)} in ${event.city}',
                      style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Specifications Grid
              LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final card1 = AccessibleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scale & Venue Logistics', style: theme.textTheme.titleMedium),
                        const Divider(height: 20),
                        _buildDetailRow('Guest Headcount', '${event.guestCount} Attendees'),
                        _buildDetailRow('Total Target Budget', CurrencyFormatter.format(event.totalBudget, currency: event.currency)),
                        _buildDetailRow('Venue Environment', event.venueType.displayName),
                        _buildDetailRow('Event Style', event.style.displayName),
                        _buildDetailRow('Planning Complexity', event.planningComplexity.displayName),
                      ],
                    ),
                  );

                  final card2 = AccessibleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Theme & Inclusivity', style: theme.textTheme.titleMedium),
                        const Divider(height: 20),
                        _buildDetailRow('Theme Concept', event.theme),
                        _buildDetailRow(
                          'Dietary Accommodations',
                          event.dietaryRequirements.isNotEmpty
                              ? event.dietaryRequirements.join(', ')
                              : 'None specified',
                        ),
                        _buildDetailRow(
                          'Universal Accessibility',
                          event.accessibilityRequirements.isNotEmpty
                              ? event.accessibilityRequirements.join(', ')
                              : 'Standard accessibility',
                        ),
                        if (event.existingBookings != null)
                          _buildDetailRow('Existing Bookings', event.existingBookings!),
                        if (event.specialRequirements != null)
                          _buildDetailRow('Special Contingency', event.specialRequirements!),
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: card1),
                        const SizedBox(width: 16),
                        Expanded(child: card2),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      card1,
                      const SizedBox(height: 16),
                      card2,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading details: $e')),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
