import '../../domain/models/event_model.dart';
import '../../domain/models/event_category.dart';
import '../../../assistant/domain/services/event_planning_engine.dart';
import 'event_repository.dart';

class SampleEvents {
  static List<EventAggregate> getInitialSamples() {
    // 1. Wedding Sample (42 days out)
    final weddingEvent = EventModel(
      id: 'sample_wedding_01',
      name: 'Maya & Julian’s Botanical Wedding',
      category: EventCategory.wedding,
      date: DateTime.now().add(const Duration(days: 42)),
      city: 'San Francisco, CA',
      guestCount: 120,
      totalBudget: 35000.0,
      currency: 'USD',
      theme: 'Botanical Glasshouse & Warm Glow',
      venueType: VenueType.hybrid,
      style: EventStyle.modern,
      dietaryRequirements: ['Vegetarian', 'Gluten-Free', 'Nut-Free'],
      accessibilityRequirements: ['Wheelchair Ramp Access', 'Low-Sensory Quiet Zone'],
      planningComplexity: PlanningComplexity.highDetail,
      existingBookings: 'Venue booked with \$5,000 reservation deposit.',
      specialRequirements: 'Clear marquee contingency required for sudden fog or rain.',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    );

    final weddingPlan = EventPlanningService.generatePlanSync(event: weddingEvent);

    // 2. Milestone Birthday (12 days out)
    final birthdayEvent = EventModel(
      id: 'sample_birthday_02',
      name: 'Marcus’s 30th Rooftop Sunset Soirée',
      category: EventCategory.birthday,
      date: DateTime.now().add(const Duration(days: 12)),
      city: 'Austin, TX',
      guestCount: 65,
      totalBudget: 8500.0,
      currency: 'USD',
      theme: 'Neon Velvet & Retro Beats',
      venueType: VenueType.indoor,
      style: EventStyle.casual,
      dietaryRequirements: ['Vegan friendly options', 'Dairy-free cupcakes'],
      accessibilityRequirements: ['Elevator access to rooftop terrace'],
      planningComplexity: PlanningComplexity.balanced,
      existingBookings: 'Lounge deposit confirmed.',
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      updatedAt: DateTime.now(),
    );

    final birthdayPlan = EventPlanningService.generatePlanSync(event: birthdayEvent);

    // 3. Community Summit (5 days out - urgent testing scenario!)
    final communityEvent = EventModel(
      id: 'sample_community_03',
      name: 'Oakwood Green Community Harvest Festival',
      category: EventCategory.communityEvent,
      date: DateTime.now().add(const Duration(days: 5)),
      city: 'Portland, OR',
      guestCount: 350,
      totalBudget: 12000.0,
      currency: 'USD',
      theme: 'Sustainable Harvest & Local Art',
      venueType: VenueType.outdoor,
      style: EventStyle.casual,
      dietaryRequirements: ['Local farm vegan stew', 'Halal certified barbecue'],
      accessibilityRequirements: ['ASL Sign Language Interpreters', 'Step-Free ADA Pathways', 'Assisted Listening'],
      planningComplexity: PlanningComplexity.highDetail,
      existingBookings: 'Public park permit issued.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

    final communityPlan = EventPlanningService.generatePlanSync(event: communityEvent);

    return [
      EventAggregate(
        event: weddingEvent,
        budgetItems: weddingPlan.budgetItems,
        tasks: weddingPlan.tasks,
        vendors: weddingPlan.vendors,
        ideas: weddingPlan.ideas,
        runSheet: weddingPlan.runSheet,
      ),
      EventAggregate(
        event: birthdayEvent,
        budgetItems: birthdayPlan.budgetItems,
        tasks: birthdayPlan.tasks,
        vendors: birthdayPlan.vendors,
        ideas: birthdayPlan.ideas,
        runSheet: birthdayPlan.runSheet,
      ),
      EventAggregate(
        event: communityEvent,
        budgetItems: communityPlan.budgetItems,
        tasks: communityPlan.tasks,
        vendors: communityPlan.vendors,
        ideas: communityPlan.ideas,
        runSheet: communityPlan.runSheet,
      ),
    ];
  }
}
