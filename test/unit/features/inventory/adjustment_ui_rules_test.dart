// Regla pura del ajuste de stock: Sumar / Restar / Poner cantidad exacta.
import 'package:baudex_desktop/features/inventory/presentation/controllers/inventory_adjustments_controller.dart';
import 'package:flutter_test/flutter_test.dart';

StockAdjustmentPlan plan(StockAdjustMode? mode, int? n, {int current = 20}) =>
    StockAdjustmentPlan(current: current, mode: mode, amount: n);

void main() {
  test('restar 5 de 20: quedan 15, diferencia −5', () {
    final p = plan(StockAdjustMode.subtract, 5);
    expect(p.newQuantity, 15);
    expect(p.difference, -5);
    expect(p.error, isNull);
    expect(p.resultText, 'Hay 20 → quedarán 15 (−5)');
    expect(p.shortResultText, '20 → 15 (−5)');
    expect(p.buttonText, 'Restar 5 unidades');
  });

  test('sumar 5 a 20: quedan 25, diferencia +5', () {
    final p = plan(StockAdjustMode.add, 5);
    expect(p.newQuantity, 25);
    expect(p.difference, 5);
    expect(p.resultText, 'Hay 20 → quedarán 25 (+5)');
    expect(p.buttonText, 'Sumar 5 unidades');
    expect(plan(StockAdjustMode.add, 1).buttonText, 'Sumar 1 unidad');
  });

  test('cantidad exacta 15: quedan 15, diferencia −5', () {
    final p = plan(StockAdjustMode.exact, 15);
    expect(p.newQuantity, 15);
    expect(p.difference, -5);
    expect(p.buttonText, 'Guardar: quedan 15');
    expect(plan(StockAdjustMode.exact, 0).difference, -20);
  });

  test('restar más de lo que hay: error y no listo', () {
    final p = plan(StockAdjustMode.subtract, 25);
    expect(p.error, 'No puedes restar 25: solo hay 20.');
    expect(p.isReady, isFalse);
    expect(p.resultText, isNull);
  });

  test('exacta igual a lo que hay: nada que cambiar', () {
    final p = plan(StockAdjustMode.exact, 20);
    expect(p.error, 'Ya hay 20. No hay nada que cambiar.');
    expect(p.isReady, isFalse);
  });

  test('sin opción o sin número: no hay plan ni error', () {
    expect(plan(null, 5).newQuantity, isNull);
    expect(plan(StockAdjustMode.add, null).newQuantity, isNull);
    expect(plan(StockAdjustMode.add, null).error, isNull);
    expect(plan(null, null).difference, 0);
    expect(plan(StockAdjustMode.add, 0).error, isNotNull);
    expect(plan(StockAdjustMode.subtract, 0).error, isNotNull);
  });

  test('razones que encajan con cada opción', () {
    expect(reasonsForMode(StockAdjustMode.subtract), [
      'Mercancía dañada',
      'Productos vencidos',
      'Pérdida o robo',
      'Error en sistema',
      'Otro',
    ]);
    expect(reasonsForMode(StockAdjustMode.add), [
      'Devolución de cliente',
      'Error en sistema',
      'Otro',
    ]);
    expect(
      defaultReasonForMode(StockAdjustMode.exact),
      'Corrección de inventario físico',
    );
    expect(
      reasonsForMode(StockAdjustMode.exact),
      contains('Corrección de inventario físico'),
    );
  });
}
