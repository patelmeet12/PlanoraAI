import 'package:flutter_test/flutter_test.dart';
import 'package:planora_ai/features/events/domain/models/event_category.dart';
import 'package:planora_ai/features/events/domain/models/event_model.dart';
import 'package:planora_ai/features/ideas/domain/services/ideas_generator_service.dart';

void main() {
  group('IdeasGeneratorService Tests', () {
    final testEvent = EventModel(
      id: 'e1',
      name: 'Outdoor Spring Wedding',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 45)),
      city: 'Portland',
      guestCount: 100,
      totalBudget: 25000,
      theme: 'Botanical Glasshouse',
      venueType: VenueType.outdoor,
      dietaryRequirements: ['Vegan', 'Gluten-Free'],
      accessibilityRequirements: ['Wheelchair Ramp Access'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Generates weather contingency idea when venue is outdoor', () {
      final ideas = IdeasGeneratorService.generateContextualIdeas(testEvent);
      final hasContingency = ideas.any((i) => i.category == 'Contingency');
      expect(hasContingency, true);
    });

    test('Generates dietary station idea matching event dietary constraints', () {
      final ideas = IdeasGeneratorService.generateContextualIdeas(testEvent);
      final hasDietaryIdea = ideas.any((i) => i.category == 'Catering');
      expect(hasDietaryIdea, true);
    });

    test('FilterCriteria filters eco-friendly ideas correctly', () {
      final ideas = IdeasGeneratorService.generateContextualIdeas(testEvent);
      const criteria = IdeasFilterCriteria(ecoFriendlyOnly: true);
      final filtered = IdeasGeneratorService.filterIdeas(ideas, criteria);

      expect(filtered.isNotEmpty, true);
      for (final idea in filtered) {
        expect(idea.isEcoFriendly, true);
      }
    });

    test('FilterCriteria filters by search query on title or description', () {
      final ideas = IdeasGeneratorService.generateContextualIdeas(testEvent);
      const criteria = IdeasFilterCriteria(searchQuery: 'marquee');
      final filtered = IdeasGeneratorService.filterIdeas(ideas, criteria);

      expect(filtered.length, 1);
      expect(filtered.first.title.toLowerCase().contains('marquee'), true);
    });
  });
}
