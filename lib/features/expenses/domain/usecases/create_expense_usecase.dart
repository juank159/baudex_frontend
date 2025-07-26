// lib/features/expenses/domain/usecases/create_expense_usecase.dart
import 'package:baudex_desktop/app/core/errors/failures.dart';
import 'package:baudex_desktop/app/core/usecases/usecase.dart';
import 'package:dartz/dartz.dart';

import '../entities/expense.dart';
import '../repositories/expense_repository.dart';

class CreateExpenseUseCase implements UseCase<Expense, CreateExpenseParams> {
  final ExpenseRepository repository;

  CreateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(CreateExpenseParams params) async {
    return await repository.createExpense(
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
      status: params.status,
    );
  }
}

class CreateExpenseParams {
  final String description;
  final double amount;
  final DateTime date;
  final String categoryId;
  final ExpenseType type;
  final PaymentMethod paymentMethod;
  final String? vendor;
  final String? invoiceNumber;
  final String? reference;
  final String? notes;
  final List<String>? attachments;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;
  final ExpenseStatus? status;

  CreateExpenseParams({
    required this.description,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    required this.paymentMethod,
    this.vendor,
    this.invoiceNumber,
    this.reference,
    this.notes,
    this.attachments,
    this.tags,
    this.metadata,
    this.status,
  });
}
