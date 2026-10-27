import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../events/presentation/providers/event_providers.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _serverEndpointCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  @override
  void dispose() {
    _serverEndpointCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final aiSettings = ref.watch(aiSettingsProvider);
    final allEventsAsync = ref.watch(allEventsProvider);
    final activeEventAsync = ref.watch(activeEventProvider);
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width > 900 ? 36 : 16,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Settings & Data Management', style: theme.textTheme.headlineMedium),
              Text(
                'Configure appearance, AI engine modes, multi-event management, and data persistence',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),

              // Theme Appearance Card
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Appearance & Theme', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (set) {
                        ref.read(themeModeProvider.notifier).setThemeMode(set.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Integration & Security Engine
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Planning AI Architecture', style: theme.textTheme.titleMedium),
                        StatusBadge(
                          label: aiSettings.isRealAiEnabled ? 'AI-Powered' : 'Smart Demo Mode',
                          type: aiSettings.isRealAiEnabled ? BadgeType.success : BadgeType.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Planora AI employs a transparent, provider-independent architecture. By default, it operates in '
                      'Smart Demo Mode using pure deterministic business logic, timeline heuristic algorithms, and local rules. '
                      'Never embed secret credentials or private API keys directly in client-side browser source code.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Connect to Real External AI Server'),
                      subtitle: const Text('Route requests through a verified server-side proxy'),
                      value: aiSettings.isRealAiEnabled,
                      onChanged: (val) {
                        ref.read(aiSettingsProvider.notifier).updateSettings(isRealAiEnabled: val);
                      },
                    ),

                    if (aiSettings.isRealAiEnabled) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _serverEndpointCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Server Proxy Endpoint',
                          hintText: 'https://api.yourdomain.com/planora-ai',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _apiKeyCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Session Auth Token (In-memory only)',
                          hintText: 'Bearer token for proxy authentication',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Multi-Event Management Card
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Stored Event Plans', style: theme.textTheme.titleMedium),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/wizard'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Event'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    allEventsAsync.when(
                      data: (events) {
                        final activeId = activeEventAsync.value?.event.id;
                        return Column(
                          children: events.map((agg) {
                            final isActive = agg.event.id == activeId;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isActive ? Icons.check_circle : Icons.event,
                                color: isActive ? AppColors.success : null,
                              ),
                              title: Text(
                                agg.event.name,
                                style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                              ),
                              subtitle: Text(
                                '${agg.event.category.displayName} • ${agg.event.guestCount} guests • \$${agg.event.totalBudget.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isActive)
                                    TextButton(
                                      onPressed: () {
                                        ref.read(activeEventProvider.notifier).switchEvent(agg.event.id);
                                      },
                                      child: const Text('Switch'),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () async {
                                      final confirm = await ConfirmDialog.show(
                                        context,
                                        title: 'Delete Event?',
                                        content: 'Are you sure you want to delete "${agg.event.name}"?',
                                        confirmLabel: 'Delete',
                                        isDestructive: true,
                                      );
                                      if (confirm == true) {
                                        await ref.read(eventRepositoryProvider).deleteEvent(agg.event.id);
                                        ref.invalidate(allEventsProvider);
                                        ref.invalidate(activeEventProvider);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Data Backup, Export & Reset
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Persistence & Privacy', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Your event data is persisted locally in browser storage via SharedPreferences. '
                      'Notice: Browser cache clears will erase local records. Export regular JSON backups to safeguard your plans.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final repo = ref.read(eventRepositoryProvider);
                            final jsonStr = await repo.exportDataJson();
                            if (context.mounted) {
                              _showExportDialog(context, jsonStr);
                            }
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export JSON Backup'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showImportDialog(context),
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Import JSON Backup'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await ConfirmDialog.show(
                              context,
                              title: 'Reset to Sample Data?',
                              content: 'This will reset your workspace to the 3 showcase events (Botanical Wedding, Birthday Soirée, Community Harvest).',
                              confirmLabel: 'Reset Data',
                            );
                            if (confirm == true) {
                              await ref.read(activeEventProvider.notifier).resetToSampleData();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✓ Reset to sample events successfully!')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Reset to Sample Data'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final confirm = await ConfirmDialog.show(
                              context,
                              title: 'Clear All Local Data?',
                              content: 'Permanently remove all local events and planning records? This cannot be undone.',
                              confirmLabel: 'Delete All',
                              isDestructive: true,
                            );
                            if (confirm == true) {
                              await ref.read(eventRepositoryProvider).clearAllData();
                              ref.invalidate(allEventsProvider);
                              ref.invalidate(activeEventProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All local data cleared.')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text('Clear All Local Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Export JSON Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Copy this JSON payload to restore your events in any browser:'),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: 480,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(jsonStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showImportDialog(BuildContext context) {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Import JSON Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste valid Planora JSON array here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final text = textCtrl.text.trim();
                final success = await ref.read(eventRepositoryProvider).importDataJson(text);
                if (success) {
                  ref.invalidate(allEventsProvider);
                  ref.invalidate(activeEventProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('✓ Data imported successfully!'),
                      ),
                    );
                  }
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text('Invalid or malformed JSON payload'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}
