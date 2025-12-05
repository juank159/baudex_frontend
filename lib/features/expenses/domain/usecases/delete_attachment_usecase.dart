// lib/features/expenses/domain/usecases/delete_attachment_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../repositories/expense_repository.dart';

class DeleteAttachmentUseCase {
  final ExpenseRepository repository;

  DeleteAttachmentUseCase(this.repository);

  Future<Either<Failure, void>> call(DeleteAttachmentParams params) async {
    return await repository.deleteAttachment(
      params.expenseId,
      params.filename,
    );
  }
}

class DeleteAttachmentParams {
  final String expenseId;
  final String filename;

  DeleteAttachmentParams({
    required this.expenseId,
    required this.filename,
  });
}
