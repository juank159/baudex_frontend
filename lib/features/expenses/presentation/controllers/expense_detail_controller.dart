// lib/features/expenses/presentation/controllers/expense_detail_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/get_expense_by_id_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/approve_expense_usecase.dart';
import '../../domain/usecases/submit_expense_usecase.dart';

class ExpenseDetailController extends GetxController {
  // Dependencies
  final GetExpenseByIdUseCase _getExpenseByIdUseCase;
  final DeleteExpenseUseCase _deleteExpenseUseCase;
  final ApproveExpenseUseCase _approveExpenseUseCase;
  final SubmitExpenseUseCase _submitExpenseUseCase;

  ExpenseDetailController({
    required GetExpenseByIdUseCase getExpenseByIdUseCase,
    required DeleteExpenseUseCase deleteExpenseUseCase,
    required ApproveExpenseUseCase approveExpenseUseCase,
    required SubmitExpenseUseCase submitExpenseUseCase,
  }) : _getExpenseByIdUseCase = getExpenseByIdUseCase,
       _deleteExpenseUseCase = deleteExpenseUseCase,
       _approveExpenseUseCase = approveExpenseUseCase,
       _submitExpenseUseCase = submitExpenseUseCase;

  // Estado
  final _isLoading = false.obs;
  final _isProcessing = false.obs;
  final expense = Rxn<Expense>();

  // ID del gasto
  String? _expenseId;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    _expenseId = Get.parameters['id'];
    if (_expenseId == null) {
      _showError('Error', 'ID de gasto no válido');
      Get.back();
      return;
    }
  }

  @override
  void onReady() {
    super.onReady();
    loadExpense();
  }

  // Cargar gasto
  Future<void> loadExpense() async {
    if (_expenseId == null) return;

    _isLoading.value = true;

    try {
      print('📄 Cargando gasto: $_expenseId');

      final result = await _getExpenseByIdUseCase(
        GetExpenseByIdParams(id: _expenseId!),
      );

      result.fold(
        (failure) {
          print('❌ Error al cargar gasto: ${failure.message}');
          _showError('Error al cargar gasto', failure.message);
          expense.value = null;
        },
        (loadedExpense) {
          print('✅ Gasto cargado: ${loadedExpense.description}');
          expense.value = loadedExpense;
        },
      );
    } catch (e) {
      print('❌ Error inesperado al cargar gasto: $e');
      _showError('Error inesperado', 'No se pudo cargar el gasto');
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar gasto
  Future<void> deleteExpense() async {
    if (_expenseId == null || _isProcessing.value) return;

    _isProcessing.value = true;

    try {
      print('🗑️ Eliminando gasto: $_expenseId');

      final result = await _deleteExpenseUseCase(
        DeleteExpenseParams(id: _expenseId!),
      );

      result.fold(
        (failure) {
          print('❌ Error al eliminar gasto: ${failure.message}');
          _showError('Error al eliminar', failure.message);
        },
        (_) {
          print('✅ Gasto eliminado exitosamente');
          _showSuccess('Gasto eliminado exitosamente');
          Get.back(result: 'deleted');
        },
      );
    } catch (e) {
      print('❌ Error inesperado al eliminar gasto: $e');
      _showError('Error inesperado', 'No se pudo eliminar el gasto');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Aprobar gasto
  Future<void> approveExpense() async {
    if (_expenseId == null || _isProcessing.value) return;

    final currentExpense = expense.value;
    if (currentExpense == null || !currentExpense.canBeApproved) {
      _showError('Error', 'Este gasto no puede ser aprobado');
      return;
    }

    // Mostrar diálogo de confirmación con opción de notas
    final result = await _showApprovalDialog();
    if (result == null) return;

    _isProcessing.value = true;

    try {
      print('✅ Aprobando gasto: $_expenseId');

      final approvalResult = await _approveExpenseUseCase(
        ApproveExpenseParams(
          id: _expenseId!,
          notes: result['notes'],
        ),
      );

      approvalResult.fold(
        (failure) {
          print('❌ Error al aprobar gasto: ${failure.message}');
          _showError('Error al aprobar', failure.message);
        },
        (updatedExpense) {
          print('✅ Gasto aprobado exitosamente');
          _showSuccess('Gasto aprobado exitosamente');
          expense.value = updatedExpense;
        },
      );
    } catch (e) {
      print('❌ Error inesperado al aprobar gasto: $e');
      _showError('Error inesperado', 'No se pudo aprobar el gasto');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Enviar gasto para aprobación
  Future<void> submitExpense() async {
    if (_expenseId == null || _isProcessing.value) return;

    final currentExpense = expense.value;
    if (currentExpense == null || !currentExpense.canBeSubmitted) {
      _showError('Error', 'Este gasto no puede ser enviado para aprobación');
      return;
    }

    _isProcessing.value = true;

    try {
      print('📤 Enviando gasto para aprobación: $_expenseId');

      final result = await _submitExpenseUseCase(
        SubmitExpenseParams(id: _expenseId!),
      );

      result.fold(
        (failure) {
          print('❌ Error al enviar gasto: ${failure.message}');
          _showError('Error al enviar', failure.message);
        },
        (updatedExpense) {
          print('✅ Gasto enviado para aprobación');
          _showSuccess('Gasto enviado para aprobación');
          expense.value = updatedExpense;
        },
      );
    } catch (e) {
      print('❌ Error inesperado al enviar gasto: $e');
      _showError('Error inesperado', 'No se pudo enviar el gasto');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Refrescar datos
  Future<void> refreshExpense() async {
    await loadExpense();
  }

  // Diálogos y UI helpers
  Future<Map<String, String>?> _showApprovalDialog() async {
    final notesController = TextEditingController();
    
    return await Get.dialog<Map<String, String>>(
      AlertDialog(
        title: const Text('Aprobar Gasto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro que desea aprobar este gasto?',
              style: Get.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas de aprobación (opcional)',
                hintText: 'Comentarios adicionales...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              notesController.dispose();
              Get.back();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final notes = notesController.text.trim();
              notesController.dispose();
              Get.back(result: {
                'notes': notes.isEmpty ? null : notes,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
  }

  void _showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
      icon: const Icon(Icons.error, color: Colors.red),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade800,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }
}