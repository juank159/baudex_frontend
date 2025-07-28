// test/safe_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/app/shared/widgets/safe_text_editing_controller.dart';
import '../lib/app/shared/widgets/custom_text_field_safe.dart';

void main() {
  group('SafeTextEditingController Tests', () {
    late SafeTextEditingController controller;

    setUp(() {
      controller = SafeTextEditingController(debugLabel: 'TestController');
    });

    tearDown(() {
      if (!controller.isDisposed) {
        controller.dispose();
      }
    });

    test('should create controller safely', () {
      expect(controller.canSafelyAccess(), isTrue);
      expect(controller.isDisposed, isFalse);
      expect(controller.text, isEmpty);
    });

    test('should handle text operations safely', () {
      controller.text = 'test text';
      expect(controller.safeText(), equals('test text'));
      
      controller.safeSetText('new text');
      expect(controller.text, equals('new text'));
      
      controller.safeClear();
      expect(controller.text, isEmpty);
    });

    test('should handle dispose safely', () {
      controller.text = 'test';
      expect(controller.canSafelyAccess(), isTrue);
      
      controller.dispose();
      expect(controller.isDisposed, isTrue);
      expect(controller.canSafelyAccess(), isFalse);
      
      // Should not crash after dispose
      expect(() => controller.text, returnsNormally);
      expect(() => controller.safeText(), returnsNormally);
      expect(() => controller.safeClear(), returnsNormally);
    });

    test('should handle multiple dispose calls safely', () {
      controller.dispose();
      expect(controller.isDisposed, isTrue);
      
      // Multiple dispose calls should not crash
      expect(() => controller.dispose(), returnsNormally);
      expect(() => controller.dispose(), returnsNormally);
    });

    test('should handle listeners safely', () {
      bool listenerCalled = false;
      void testListener() {
        listenerCalled = true;
      }
      
      controller.addListener(testListener);
      controller.text = 'trigger listener';
      
      // Note: In real scenario, listener would be called
      // This test verifies that addListener doesn't crash
      
      controller.removeListener(testListener);
      controller.dispose();
      
      // Should not crash even with listeners
      expect(() => controller.addListener(testListener), returnsNormally);
    });

    test('should create from existing controller safely', () {
      final existingController = TextEditingController(text: 'existing text');
      final safeController = SafeTextEditingController.fromExisting(
        existingController,
        debugLabel: 'FromExisting',
      );
      
      expect(safeController.text, equals('existing text'));
      expect(safeController.canSafelyAccess(), isTrue);
      
      existingController.dispose();
      safeController.dispose();
    });

    test('should handle disposed source controller in fromExisting', () {
      final existingController = TextEditingController(text: 'test');
      existingController.dispose();
      
      // Should not crash even with disposed source
      final safeController = SafeTextEditingController.fromExisting(
        existingController,
        debugLabel: 'FromDisposed',
      );
      
      expect(safeController.canSafelyAccess(), isTrue);
      expect(safeController.text, isEmpty); // Should fallback to empty
      
      safeController.dispose();
    });
  });

  group('SafeTextEditingController Extension Tests', () {
    test('should check safety of normal controller', () {
      final controller = TextEditingController();
      expect(controller.isSafe, isTrue);
      
      controller.dispose();
      expect(controller.isSafe, isFalse);
    });

    test('should convert to safe controller', () {
      final controller = TextEditingController(text: 'test');
      final safeController = controller.toSafe('ConvertedController');
      
      expect(safeController.text, equals('test'));
      expect(safeController.canSafelyAccess(), isTrue);
      
      controller.dispose();
      safeController.dispose();
    });
  });

  group('CustomTextFieldSafe Widget Tests', () {
    testWidgets('should render without crashing', (WidgetTester tester) async {
      final controller = SafeTextEditingController(debugLabel: 'WidgetTest');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFieldSafe(
              controller: controller,
              label: 'Test Field',
              debugLabel: 'TestField',
            ),
          ),
        ),
      );
      
      expect(find.text('Test Field'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      
      controller.dispose();
    });

    testWidgets('should handle null controller gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFieldSafe(
              controller: null, // Null controller should not crash
              label: 'Test Field',
              debugLabel: 'NullControllerTest',
            ),
          ),
        ),
      );
      
      expect(find.text('Test Field'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should handle disposed controller gracefully', (WidgetTester tester) async {
      final controller = SafeTextEditingController(debugLabel: 'DisposedTest');
      controller.dispose(); // Dispose before using
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFieldSafe(
              controller: controller,
              label: 'Test Field',
              debugLabel: 'DisposedControllerTest',
            ),
          ),
        ),
      );
      
      // Should render placeholder field without crashing
      expect(find.text('Test Field'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('should handle text input and changes', (WidgetTester tester) async {
      final controller = SafeTextEditingController(debugLabel: 'InputTest');
      String? lastChangedValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFieldSafe(
              controller: controller,
              label: 'Test Field',
              debugLabel: 'InputTest',
              onChanged: (value) {
                lastChangedValue = value;
              },
            ),
          ),
        ),
      );
      
      // Enter text
      await tester.enterText(find.byType(TextFormField), 'test input');
      await tester.pump();
      
      expect(controller.text, equals('test input'));
      expect(lastChangedValue, equals('test input'));
      
      controller.dispose();
    });
  });

  group('Regression Tests', () {
    test('should prevent disposed controller errors during navigation', () {
      // Simulate navigation scenario
      final controllers = <SafeTextEditingController>[];
      
      // Create multiple controllers as might happen during navigation
      for (int i = 0; i < 10; i++) {
        final controller = SafeTextEditingController(
          debugLabel: 'NavigationTest$i',
          text: 'Initial text $i',
        );
        controllers.add(controller);
        
        // Simulate rapid disposal (navigation back)
        if (i % 2 == 0) {
          controller.dispose();
        }
      }
      
      // Should be able to access all controllers safely
      for (final controller in controllers) {
        expect(() => controller.safeText(), returnsNormally);
        expect(() => controller.canSafelyAccess(), returnsNormally);
        
        if (!controller.isDisposed) {
          controller.dispose();
        }
      }
    });

    test('should handle rapid text changes without crashing', () {
      final controller = SafeTextEditingController(debugLabel: 'RapidChanges');
      
      // Simulate rapid text changes
      for (int i = 0; i < 100; i++) {
        controller.safeSetText('Text change $i');
        expect(controller.safeText(), equals('Text change $i'));
      }
      
      controller.dispose();
      
      // Should not crash even after dispose
      for (int i = 0; i < 10; i++) {
        expect(() => controller.safeSetText('After dispose $i'), returnsNormally);
      }
    });
  });
}