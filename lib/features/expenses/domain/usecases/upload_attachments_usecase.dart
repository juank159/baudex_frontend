// lib/features/expenses/domain/usecases/upload_attachments_usecase.dart
import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/services/file_service.dart';
import '../repositories/expense_repository.dart';

class UploadAttachmentsUseCase {
  final ExpenseRepository repository;

  UploadAttachmentsUseCase(this.repository);

  Future<Either<Failure, List<String>>> call(UploadAttachmentsParams params) async {
    return await repository.uploadAttachments(
      params.expenseId,
      params.files,
    );
  }
}

class UploadAttachmentsParams {
  final String expenseId;
  final List<AttachmentFile> files;

  UploadAttachmentsParams({
    required this.expenseId,
    required this.files,
  });
}
