import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/validation/validators.dart';
import '../../../../shared/widgets/accessible_card.dart';
import '../../../assistant/domain/services/event_planning_engine.dart';
import '../../../events/data/repositories/event_repository.dart';
import '../../../events/domain/models/event_category.dart';
import '../../../events/domain/models/event_model.dart';
import '../../../events/presentation/providers/event_providers.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1: Basics
  final _nameController = TextEditingController(text: 'Summer Gala & Reception');
  EventCategory _selectedCategory = EventCategory.wedding;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 60));
  final _cityController = TextEditingController(text: 'Chicago, IL');

  // Step 2: Scale & Budget
  final _guestCountController = TextEditingController(text: '100');
  final _budgetController = TextEditingController(text: '20000');
  String _selectedCurrency = 'USD';

  // Step 3: Style & Venue
  String _selectedTheme = 'Modern Elegance';
  VenueType _selectedVenueType = VenueType.hybrid;
  EventStyle _selectedStyle = EventStyle.modern;

  // Step 4: Special Requirements
  final Set<String> _selectedDietary = {'Vegetarian', 'Gluten-Free'};
  final Set<String> _selectedAccessibility = {'Wheelchair Ramp Access'};
  PlanningComplexity _selectedComplexity = PlanningComplexity.balanced;
  final _existingBookingsController = TextEditingController();
  final _specialRequirementsController = TextEditingController();

  bool _isGenerating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _guestCountController.dispose();
    _budgetController.dispose();
    _existingBookingsController.dispose();
    _specialRequirementsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty || _cityController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete event name and city')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      final guestErr = FormValidators.validateGuestCount(_guestCountController.text);
      final budgetErr = FormValidators.validateBudget(_budgetController.text);
      if (guestErr != null || budgetErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(guestErr ?? budgetErr!)),
        );
        return;
      }
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _generateAndSavePlan() async {
    setState(() => _isGenerating = true);

    try {
      const uuid = Uuid();
      final eventId = 'event_${uuid.v4().substring(0, 8)}';
      final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 100;
      final totalBudget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 20000.0;

      final newEvent = EventModel(
        id: eventId,
        name: _nameController.text.trim(),
        category: _selectedCategory,
        date: _selectedDate,
        city: _cityController.text.trim(),
        guestCount: guestCount,
        totalBudget: totalBudget,
        currency: _selectedCurrency,
        theme: _selectedTheme,
        venueType: _selectedVenueType,
        style: _selectedStyle,
        dietaryRequirements: _selectedDietary.toList(),
        accessibilityRequirements: _selectedAccessibility.toList(),
        planningComplexity: _selectedComplexity,
        existingBookings: _existingBookingsController.text.trim().isNotEmpty
            ? _existingBookingsController.text.trim()
            : null,
        specialRequirements: _specialRequirementsController.text.trim().isNotEmpty
            ? _specialRequirementsController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Generate structured plan
      final generatedPlan = EventPlanningService.generatePlanSync(event: newEvent);

      final newAggregate = EventAggregate(
        event: newEvent,
        budgetItems: generatedPlan.budgetItems,
        tasks: generatedPlan.tasks,
        vendors: generatedPlan.vendors,
        ideas: generatedPlan.ideas,
        runSheet: generatedPlan.runSheet,
      );

      await ref.read(activeEventProvider.notifier).createNewEventPlan(newAggregate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('🎉 Event Plan generated for "${newEvent.name}"!'),
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating plan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width > 800 ? 48 : 20,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Your Next Event', style: theme.textTheme.headlineMedium),
                        Text(
                          'Step ${_currentStep + 1} of 5 — ${_getStepTitle(_currentStep)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 5.0,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.outline.withAlpha(80),
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Step content in Card
              AccessibleCard(
                child: Form(
                  key: _formKey,
                  child: _buildCurrentStep(context),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentStep < 4)
                    ElevatedButton.icon(
                      onPressed: _nextStep,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Continue'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateAndSavePlan,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(_isGenerating ? 'Generating Plan...' : 'Generate Intelligent Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Basics & Category';
      case 1:
        return 'Scale & Budget';
      case 2:
        return 'Style & Atmosphere';
      case 3:
        return 'Dietary & Accessibility';
      case 4:
        return 'Review & Generate';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 0:
        return _buildStepBasics(context);
      case 1:
        return _buildStepScaleBudget(context);
      case 2:
        return _buildStepStyle(context);
      case 3:
        return _buildStepRequirements(context);
      case 4:
        return _buildStepReview(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: BASICS
  Widget _buildStepBasics(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are we celebrating?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        // Event Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Event Name *',
            hintText: 'e.g. Maya & Julian’s Botanical Wedding',
            prefixIcon: Icon(Icons.celebration_outlined),
          ),
          validator: FormValidators.validateEventName,
        ),
        const SizedBox(height: 16),

        // Event Category
        Text('Event Category *', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: EventCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return ChoiceChip(
              label: Text(cat.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedCategory = cat);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Event Date Picker
        Text('Event Date *', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormatter.formatFullDate(_selectedDate),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  DateFormatter.formatRelativeDays(_selectedDate),
                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // City
        TextFormField(
          controller: _cityController,
          decoration: const InputDecoration(
            labelText: 'City or Geographic Location *',
            hintText: 'e.g. Chicago, IL or Seattle, WA',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          validator: (v) => FormValidators.validateNotEmpty(v, 'Location'),
        ),
      ],
    );
  }

  // STEP 2: SCALE & BUDGET
  Widget _buildStepScaleBudget(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scale & Budget Constraints', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        // Guest count
        TextFormField(
          controller: _guestCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Expected Guest Count *',
            hintText: 'e.g. 100',
            prefixIcon: Icon(Icons.people_outline),
          ),
          validator: FormValidators.validateGuestCount,
        ),
        const SizedBox(height: 20),

        // Budget & Currency
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Target Budget *',
                  hintText: 'e.g. 20000',
                  prefixText: AppConstants.currencySymbols[_selectedCurrency] ?? '\$ ',
                ),
                validator: FormValidators.validateBudget,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                ),
                items: AppConstants.supportedCurrencies.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCurrency = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live calculation estimate card
        Builder(builder: (ctx) {
          final guests = int.tryParse(_guestCountController.text.trim()) ?? 100;
          final budget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 20000;
          final perHead = guests > 0 ? (budget / guests) : 0.0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Cost per Guest',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '~${CurrencyFormatter.format(perHead, currency: _selectedCurrency)} per attendee',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // STEP 3: STYLE & VENUE
  Widget _buildStepStyle(BuildContext context) {
    final theme = Theme.of(context);

    final themeOptions = [
      'Modern Elegance',
      'Rustic Chic & Barn Glow',
      'Botanical Glasshouse',
      'Cyber Neon & Retro Beats',
      'Classic Black Tie Gala',
      'Artisanal Boho Garden',
      'Eco-Sustainable Harvest',
      'Minimalist Contemporary',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style, Theme & Atmosphere', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        Text('Preferred Theme Concept', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: themeOptions.map((t) {
            final isSelected = _selectedTheme == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedTheme = t);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text('Venue Setting', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: VenueType.values.map((v) {
            final isSelected = _selectedVenueType == v;
            return ChoiceChip(
              label: Text(v.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedVenueType = v);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text('Formality & Aesthetic', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: EventStyle.values.map((s) {
            final isSelected = _selectedStyle == s;
            return ChoiceChip(
              label: Text(s.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedStyle = s);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // STEP 4: REQUIREMENTS
  Widget _buildStepRequirements(BuildContext context) {
    final theme = Theme.of(context);

    final dietaryOptions = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Nut-Free Certified',
      'Halal',
      'Kosher',
      'Dairy-Free',
    ];

    final accessOptions = [
      'Wheelchair Ramp Access',
      'Step-Free Venue Access',
      'Low-Sensory Quiet Zone',
      'ASL Sign Language Interpreters',
      'Assisted Listening Loop',
      'Accessible Restrooms',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Inclusivity & Special Requirements', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),

        Text('Dietary Accommodations', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: dietaryOptions.map((opt) {
            final isSelected = _selectedDietary.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedDietary.add(opt);
                  } else {
                    _selectedDietary.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text('Universal Accessibility Requirements', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accessOptions.map((opt) {
            final isSelected = _selectedAccessibility.contains(opt);
            return FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAccessibility.add(opt);
                  } else {
                    _selectedAccessibility.remove(opt);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text('Planning Detail Level', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PlanningComplexity.values.map((c) {
            final isSelected = _selectedComplexity == c;
            return ChoiceChip(
              label: Text(c.displayName),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _selectedComplexity = c);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        TextFormField(
          controller: _existingBookingsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Existing Bookings / Retained Vendors (Optional)',
            hintText: 'e.g. Venue already booked, \$3000 deposit paid',
          ),
        ),
      ],
    );
  }

  // STEP 5: REVIEW
  Widget _buildStepReview(BuildContext context) {
    final theme = Theme.of(context);
    final guests = int.tryParse(_guestCountController.text.trim()) ?? 100;
    final budget = double.tryParse(_budgetController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 20000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ready to Generate Your Event Plan', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          'Planora AI will build an itemized budget across 12 categories, generate an adaptive timeline, '
          'recommend benchmark vendors, craft personalized ideas, and assemble an event-day run sheet.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),

        _buildReviewRow('Event Name', _nameController.text),
        _buildReviewRow('Category', _selectedCategory.displayName),
        _buildReviewRow('Target Date', '${DateFormatter.formatFullDate(_selectedDate)} (${DateFormatter.formatRelativeDays(_selectedDate)})'),
        _buildReviewRow('Location', _cityController.text),
        _buildReviewRow('Guest Count', '$guests attendees'),
        _buildReviewRow('Total Budget', CurrencyFormatter.format(budget, currency: _selectedCurrency)),
        _buildReviewRow('Theme Concept', _selectedTheme),
        _buildReviewRow('Venue Setting', _selectedVenueType.displayName),
        _buildReviewRow('Style', _selectedStyle.displayName),
        if (_selectedDietary.isNotEmpty)
          _buildReviewRow('Dietary Requirements', _selectedDietary.join(', ')),
        if (_selectedAccessibility.isNotEmpty)
          _buildReviewRow('Accessibility', _selectedAccessibility.join(', ')),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
