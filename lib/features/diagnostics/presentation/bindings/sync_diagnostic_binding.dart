// lib/features/diagnostics/presentation/bindings/sync_diagnostic_binding.dart
import 'package:get/get.dart';
import '../controllers/sync_diagnostic_controller.dart';

class SyncDiagnosticBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SyncDiagnosticController>(
      () => SyncDiagnosticController(),
      fenix: true,
    );
  }
}
