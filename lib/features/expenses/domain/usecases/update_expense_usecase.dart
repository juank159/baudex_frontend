// lib/features/expenses/domain/usecases/update_expense_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository repository;

  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    return await repository.updateExpense(
      id: params.id,
      description: params.description,
      amount: params.amount,
      date: params.date,
      categoryId: params.categoryId,
      type: params.type,
      paymentMethod: params.paymentMethod,
      vendor: params.vendor,
      invoiceNumber: params.invoiceNumber,
      reference: params.reference,
      notes: params.notes,
      attachments: params.attachments,
      tags: params.tags,
      metadata: params.metadata,
    );
  }
}

class UpdateExpenseParams {
  final String id;
  final String? description;
  final double? amount;
  final DateTime? date;
  final String? categoryId;
  final ExpenseType? type;
  final PaymentMethod? paymentMethod;
  final String? vendor;
  final String? invoiceNumber;
  final String? reference;
  final String? notes;
  final List<String>? attachments;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  UpdateExpenseParams({
    required this.id,
    this.description,
    this.amount,
    this.date,
    this.categoryId,
    this.type,
    this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachments,
    this.tags,
    this.metadata,
  });
}
