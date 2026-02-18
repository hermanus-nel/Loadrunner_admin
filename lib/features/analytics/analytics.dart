// lib/features/analytics/analytics.dart
// 
// Barrel export file for analytics feature

// Domain - Entities
export 'domain/entities/activity_metrics.dart';
export 'domain/entities/financial_metrics.dart';
export 'domain/entities/performance_metrics.dart';
export 'domain/entities/date_range.dart';

// Domain - Repository
export 'domain/repositories/analytics_repository.dart';

// Data - Repository Implementation
export 'data/repositories/analytics_repository_impl.dart';

// Presentation - Providers
export 'presentation/providers/analytics_providers.dart';

// Presentation - Screens
export 'presentation/screens/analytics_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/date_range_selector.dart';
export 'presentation/widgets/metric_card.dart';
export 'presentation/widgets/revenue_chart.dart';
export 'presentation/widgets/shipments_chart.dart';
export 'presentation/widgets/ratings_chart.dart';
