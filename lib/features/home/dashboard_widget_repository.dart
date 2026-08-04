import 'widgets/agenda_widget.dart';
import 'widgets/forum_widget.dart';
import 'widgets/payments_widget.dart';
import 'widgets/recipes_widget.dart';
import 'widgets/trip_widget.dart';
import '../calendar/services/calendar_service.dart';
import '../forum/services/forum_service.dart';
import '../recipes/services/recipes_service.dart';
import '../subscription/services/subscription_service.dart';
import '../travel/services/travel_service.dart';
import 'dashboard_widget.dart';
import 'dashboard_widget_spec.dart';

/// Baut die [DashboardWidgetSpec] für jeden Widget-Typ aus den Services.
class DashboardWidgetRepository {
  const DashboardWidgetRepository({
    required this.recipes,
    required this.calendar,
    required this.travel,
    required this.forum,
    required this.subscription,
  });

  final RecipesService recipes;
  final CalendarService calendar;
  final TravelService travel;
  final ForumService forum;
  final SubscriptionService subscription;

  DashboardWidgetSpec specFor(DashboardWidgetType type) {
    return switch (type) {
      DashboardWidgetType.recipes => RecipesWidgetSpec(recipes),
      DashboardWidgetType.calendarAgenda => AgendaWidgetSpec(calendar),
      DashboardWidgetType.nextTrip => TripWidgetSpec(travel),
      DashboardWidgetType.forumPosts => ForumWidgetSpec(forum),
      DashboardWidgetType.openPayments => PaymentsWidgetSpec(subscription),
    };
  }
}
