import 'package:uuid/uuid.dart';
import '../../../events/domain/models/event_category.dart';
import '../../../events/domain/models/event_model.dart';
import '../models/event_idea.dart';

class IdeasFilterCriteria {
  final double? maxBudget;
  final IdeaComplexity? maxComplexity;
  final bool ecoFriendlyOnly;
  final String? category;
  final String? searchQuery;

  const IdeasFilterCriteria({
    this.maxBudget,
    this.maxComplexity,
    this.ecoFriendlyOnly = false,
    this.category,
    this.searchQuery,
  });
}

class IdeasGeneratorService {
  /// Generate contextual event ideas tailored to the event model
  static List<EventIdea> generateContextualIdeas(EventModel event) {
    const uuid = Uuid();
    final List<EventIdea> ideas = [];

    final isOutdoor = event.venueType == VenueType.outdoor || event.venueType == VenueType.hybrid;
    final hasAccessibility = event.accessibilityRequirements.isNotEmpty;
    final hasDietary = event.dietaryRequirements.isNotEmpty;

    // 1. Weather Contingency (if outdoor/hybrid)
    if (isOutdoor) {
      ideas.add(EventIdea(
        id: uuid.v4(),
        eventId: event.id,
        title: 'Clear-Span Ambient Marquee & Rain Contingency Plan',
        category: 'Contingency',
        description: 'Establish a 48-hour weather trigger with a clear-top tent rental allowing scenic natural light while keeping guests protected from rain or gusty winds.',
        estimatedCostRange: '\$800 - \$2,200',
        minCost: 800,
        maxCost: 2200,
        guestSuitability: 'All ${event.guestCount} guests',
        complexity: IdeaComplexity.medium,
        benefits: [
          'Guarantees event proceeds regardless of rain or sudden storms',
          'Preserves outdoor scenic views through transparent roof panels',
          'Provides overhead rigging points for warm festoon lighting',
        ],
        limitations: [
          'Requires refundable deposit 7 days prior to reserve equipment',
        ],
        matchReason: 'Directly protects your ${event.venueType.displayName} venue layout in ${event.city}.',
        isEcoFriendly: false,
      ));
    }

    // 2. Sustainable Decor Concept
    ideas.add(EventIdea(
      id: uuid.v4(),
      eventId: event.id,
      title: 'Potted Botanical Centerpieces with Guest Take-Home Favors',
      category: 'Decor',
      description: 'Replace cut flowers that wither after one evening with lush potted ferns, rosemary topiaries, and succulents in terracotta pots that double as guest favors.',
      estimatedCostRange: '\$250 - \$650',
      minCost: 250,
      maxCost: 650,
      guestSuitability: 'All guests',
      complexity: IdeaComplexity.low,
      benefits: [
        'Zero floral waste; plants survive for years in guest homes',
        'Cuts combined decor and favor expenses by up to 45%',
        'Adds organic natural fragrance to dining tables',
      ],
      limitations: [
        'Requires coordination at end of night for guest distribution',
      ],
      matchReason: 'Fits your "${event.theme}" theme while optimizing budget efficiency.',
      isEcoFriendly: true,
    ));

    // 3. Category-specific ideas
    if (event.category == EventCategory.wedding) {
      ideas.add(EventIdea(
        id: uuid.v4(),
        eventId: event.id,
        title: 'Interactive Audio Guestbook via Vintage Rotary Phone',
        category: 'Entertainment',
        description: 'Set up an authentic retro rotary phone where guests pick up the receiver, hear your recorded greeting, and leave heartfelt voice messages all night.',
        estimatedCostRange: '\$180 - \$350',
        minCost: 180,
        maxCost: 350,
        guestSuitability: 'All age groups',
        complexity: IdeaComplexity.low,
        benefits: [
          'Captures emotional voices and laughter of loved ones forever',
          'Engages older family members and young tech fans alike',
          'Delivered as digital audio tracks for easy sharing',
        ],
        limitations: [
          'Requires quiet placement away from loud sound speakers',
        ],
        matchReason: 'Provides an intimate personal touch tailored for your wedding.',
        isEcoFriendly: true,
      ));
    } else if (event.category == EventCategory.birthday) {
      ideas.add(EventIdea(
        id: uuid.v4(),
        eventId: event.id,
        title: 'Custom Mocktail/Cocktail Tasting Station & Live Flair Mixology',
        category: 'Food & Drink',
        description: 'A curated signature drinks bar featuring 3 custom recipes inspired by the guest of honor, complete with fresh botanical garnishes.',
        estimatedCostRange: '\$400 - \$950',
        minCost: 400,
        maxCost: 950,
        guestSuitability: 'Teens & Adults',
        complexity: IdeaComplexity.medium,
        benefits: [
          'Creates a lively social focal point during the reception',
          'Accommodates non-alcoholic and alcohol-free drinkers elegantly',
        ],
        limitations: [
          'Requires dedicated bartender or certified server',
        ],
        matchReason: 'Elevates a celebration vibe for ${event.guestCount} party guests.',
        isEcoFriendly: false,
      ));
    } else if (event.category == EventCategory.communityEvent) {
      ideas.add(EventIdea(
        id: uuid.v4(),
        eventId: event.id,
        title: 'Collaborative Community Canvas Mural Wall',
        category: 'Activity',
        description: 'A large guided art canvas where attendees of all ages add colors, messages, and handprints to commemorate community unity.',
        estimatedCostRange: '\$150 - \$300',
        minCost: 150,
        maxCost: 300,
        guestSuitability: 'Children, Youth, Adults & Seniors',
        complexity: IdeaComplexity.low,
        benefits: [
          'Creates an enduring commemorative piece for the community space',
          'Extremely cost-effective per participant',
          'Encourages cross-generational interaction',
        ],
        limitations: [
          'Requires washable paints and cleanup supplies nearby',
        ],
        matchReason: 'Empowers inclusive participation for a large community crowd.',
        isEcoFriendly: true,
      ));
    }

    // 4. Dietary Innovation (if dietary requirements mentioned)
    if (hasDietary) {
      ideas.add(EventIdea(
        id: uuid.v4(),
        eventId: event.id,
        title: 'Artisanal Global Tapas & Live Action Grazing Station',
        category: 'Catering',
        description: 'A beautifully labeled grazing station clearly separating gluten-free, vegan, nut-free, and halal delights with dedicated serving tongs.',
        estimatedCostRange: '\$600 - \$1,400',
        minCost: 600,
        maxCost: 1400,
        guestSuitability: 'Special dietary guests & foodies',
        complexity: IdeaComplexity.medium,
        benefits: [
          'Eliminates guest anxiety over cross-contamination',
          'Visual labeling with ingredient cards builds attendee trust',
          'Reduces food waste compared to pre-plated set menus',
        ],
        limitations: [
          'Requires diligent replenishment by catering staff',
        ],
        matchReason: 'Directly addresses: ${event.dietaryRequirements.join(", ")}.',
        isEcoFriendly: true,
      ));
    }

    // 5. Accessibility Arrangements (if accessibility mentioned or general best practice)
    ideas.add(EventIdea(
      id: uuid.v4(),
      eventId: event.id,
      title: hasAccessibility
          ? 'Dedicated Low-Sensory Chillout Lounge & Priority Seating'
          : 'Universal Access Pathway & Seating Flow',
      category: 'Accessibility',
      description: 'Establish a designated quiet zone with comfortable seating, low ambient lighting, and noise-dampening panels for neurodivergent guests or elders needing respite.',
      estimatedCostRange: '\$100 - \$300',
      minCost: 100,
      maxCost: 300,
      guestSuitability: 'Elders, neurodivergent guests, parents with infants',
      complexity: IdeaComplexity.low,
      benefits: [
        'Ensures everyone feels welcome and can remain at the event longer',
        'Provides step-free rest and calm conversation space',
      ],
      limitations: [
        'Requires a quiet alcove or separate room in the venue',
      ],
      matchReason: hasAccessibility
          ? 'Matches your accessibility criteria: ${event.accessibilityRequirements.join(", ")}'
          : 'Elevates hospitality and comfort for all attendees.',
      isEcoFriendly: true,
    ));

    return ideas;
  }

  /// Filter ideas according to user criteria
  static List<EventIdea> filterIdeas(List<EventIdea> ideas, IdeasFilterCriteria criteria) {
    return ideas.where((idea) {
      if (criteria.ecoFriendlyOnly && !idea.isEcoFriendly) {
        return false;
      }
      if (criteria.maxBudget != null && idea.minCost > criteria.maxBudget!) {
        return false;
      }
      if (criteria.maxComplexity != null) {
        if (criteria.maxComplexity == IdeaComplexity.low && idea.complexity != IdeaComplexity.low) {
          return false;
        }
        if (criteria.maxComplexity == IdeaComplexity.medium && idea.complexity == IdeaComplexity.high) {
          return false;
        }
      }
      if (criteria.category != null && criteria.category!.isNotEmpty && criteria.category != 'All') {
        if (idea.category.toLowerCase() != criteria.category!.toLowerCase()) {
          return false;
        }
      }
      if (criteria.searchQuery != null && criteria.searchQuery!.trim().isNotEmpty) {
        final query = criteria.searchQuery!.toLowerCase();
        final matches = idea.title.toLowerCase().contains(query) ||
            idea.description.toLowerCase().contains(query) ||
            idea.matchReason.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }
}
