// lib/features/subscriptions/subscriptions.dart

// Module de suscripciones para manejo offline-first
//
// Este modulo proporciona:
// - Gestion de suscripciones con cache local
// - Validacion de limites por plan
// - Politica de gracia offline
// - Notificaciones proactivas de expiracion

// Domain entities
export 'domain/entities/subscription.dart';
export 'domain/entities/subscription_enums.dart';
export 'domain/entities/subscription_usage.dart';
export 'domain/entities/action_validation.dart';
export 'domain/entities/plan_limits.dart';
export 'domain/entities/plan_features.dart';

// Domain repositories
export 'domain/repositories/subscription_repository.dart';

// Data models
export 'data/models/subscription_model.dart';
export 'data/models/subscription_usage_model.dart';
export 'data/models/action_validation_model.dart';
export 'data/models/plan_limits_model.dart';
export 'data/models/plan_features_model.dart';

// Data datasources
export 'data/datasources/subscription_remote_datasource.dart';
export 'data/datasources/subscription_local_datasource.dart';

// Data repositories
export 'data/repositories/subscription_repository_impl.dart';

// Presentation controllers
export 'presentation/controllers/subscription_controller.dart';

// Presentation bindings
export 'presentation/bindings/subscription_binding.dart';

// Presentation widgets
export 'presentation/widgets/subscription_widgets.dart';
