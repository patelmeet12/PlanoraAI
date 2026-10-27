import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../providers/event_providers.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width > 900 ? 48 : 20,
        vertical: 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Next-Gen Event Planning Copilot',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Main Hero Title
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Text(
              'Your Personal Copilot for Extraordinary Celebrations',
              textAlign: TextAlign.center,
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Planora AI transforms the chaos of organizing weddings, birthdays, and community events '
              'into an intelligent, adaptive plan. Balance budgets, coordinate vendors, and adapt instantly when plans change.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/wizard'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Start Event Wizard'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: const Text('Open Active Dashboard'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // The Core Loop Steps
          AccessibleCard(
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
            child: Column(
              children: [
                Text(
                  'THE PLANORA INTELLIGENT WORKFLOW',
                  style: theme.textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStepChip(context, '1', 'Describe Event'),
                    _buildStepArrow(context),
                    _buildStepChip(context, '2', 'Generate Plan'),
                    _buildStepArrow(context),
                    _buildStepChip(context, '3', 'Optimize Budget'),
                    _buildStepArrow(context),
                    _buildStepChip(context, '4', 'Organize Vendors'),
                    _buildStepArrow(context),
                    _buildStepChip(context, '5', 'Follow Timeline'),
                    _buildStepArrow(context),
                    _buildStepChip(context, '6', 'Adapt to Changes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Explore Sample Events section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Explore Pre-Configured Showcase Events',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Jump straight into realistic event data to test budget calculations, task dependency checks, and the AI Copilot.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),

          // 3 Sample Event Cards
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 800;
              final card1 = _buildShowcaseCard(
                context,
                ref,
                eventId: 'sample_wedding_01',
                title: 'Botanical Wedding',
                subtitle: '120 guests • \$35,000 budget • 42 days out',
                icon: Icons.favorite,
                accentColor: AppColors.primary,
                description: 'Comprehensive high-detail plan featuring floral arches, vegan catering, and multi-shooter photo package.',
              );
              final card2 = _buildShowcaseCard(
                context,
                ref,
                eventId: 'sample_birthday_02',
                title: '30th Sunset Soirée',
                subtitle: '65 guests • \$8,500 budget • 12 days out',
                icon: Icons.cake,
                accentColor: AppColors.secondary,
                description: 'Rooftop celebration with live DJ, signature mixology bar, and ambient neon decor.',
              );
              final card3 = _buildShowcaseCard(
                context,
                ref,
                eventId: 'sample_community_03',
                title: 'Community Harvest',
                subtitle: '350 guests • \$12,000 budget • 5 days out',
                icon: Icons.groups,
                accentColor: AppColors.tertiary,
                description: 'Urgent sprint timeline test case with ASL interpreters, ADA ramp access, and public park logistics.',
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 16),
                    Expanded(child: card2),
                    const SizedBox(width: 16),
                    Expanded(child: card3),
                  ],
                );
              }
              return Column(
                children: [
                  card1,
                  const SizedBox(height: 16),
                  card2,
                  const SizedBox(height: 16),
                  card3,
                ],
              );
            },
          ),
          const SizedBox(height: 56),

          // 6 Feature pillars
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Built for Real Event Decision-Making',
              style: theme.textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: width > 900 ? 3 : (width > 600 ? 2 : 1),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: width > 900 ? 1.3 : 1.4,
            children: [
              _buildFeatureTile(
                context,
                icon: Icons.pie_chart,
                title: 'Intelligent Budget Optimizer',
                desc: 'Real mathematical tracking across 12 categories. Categorizes Within, Approaching, or Over Budget states and proposes non-destructive reductions.',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.timeline,
                title: 'Adaptive Event Timeline',
                desc: 'Automatically adapts milestone deadlines to remaining days (7-day emergency sprint vs 6-month roadmap). Detects circular dependencies.',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.storefront,
                title: 'Transparent Vendor Organizer',
                desc: 'Side-by-side comparison on pricing, rating, and deliverables. Clearly distinguishes verified user entries from demo benchmarks.',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.lightbulb,
                title: 'Personalized Ideas Engine',
                desc: 'Contextual concepts for decor, entertainment, and dietary logistics tailored to your exact venue type, theme, and accessibility requirements.',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.compare_arrows,
                title: 'Change Impact Analyzer',
                desc: 'Simulate guest count increases or budget adjustments. Computes before-and-after deltas across catering, venue capacity, and deadlines.',
              ),
              _buildFeatureTile(
                context,
                icon: Icons.schedule,
                title: 'Event-Day Run Sheet',
                desc: 'Minute-by-minute execution schedule with automated detection of overlapping room bookings and missing setup buffers.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepChip(BuildContext context, String num, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            num,
            style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildStepArrow(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios,
      size: 12,
      color: Theme.of(context).colorScheme.outline,
    );
  }

  Widget _buildShowcaseCard(
    BuildContext context,
    WidgetRef ref, {
    required String eventId,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String description,
  }) {
    final theme = Theme.of(context);

    return AccessibleCard(
      onTap: () async {
        await ref.read(activeEventProvider.notifier).switchEvent(eventId);
        if (context.mounted) context.go('/');
      },
      semanticLabel: 'Select showcase event $title',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Load Event',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final theme = Theme.of(context);

    return AccessibleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              desc,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
