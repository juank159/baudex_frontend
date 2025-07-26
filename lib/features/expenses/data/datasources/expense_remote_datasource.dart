// lib/features/expenses/data/datasources/expense_remote_datasource.dart
import 'package:dio/dio.dart';
import '../../../../app/config/constants/api_constants.dart';
import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/expense_model.dart';
import '../models/expenses_list_response_model.dart';
import '../models/expense_category_model.dart';
import '../models/expense_categories_response_model.dart';
import '../models/expense_stats_model.dart';
import '../models/expense_response_model.dart';
import '../models/create_expense_request_model.dart';
import '../models/update_expense_request_model.dart';
import '../models/create_expense_category_request_model.dart';

abstract class ExpenseRemoteDataSource {
  Future<ExpensesListResponseModel> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    String? orderDirection,
  });

  Future<ExpenseModel> getExpenseById(String id);
  Future<ExpenseModel> createExpense(CreateExpenseRequestModel request);
  Future<ExpenseModel> updateExpense(String id, UpdateExpenseRequestModel request);
  Future<void> deleteExpense(String id);
  Future<ExpenseModel> submitExpense(String id);
  Future<ExpenseModel> approveExpense(String id, String? notes);
  Future<ExpenseModel> rejectExpense(String id, String reason);
  Future<ExpenseModel> markAsPaid(String id);
  Future<List<ExpenseModel>> searchExpenses(String query);
  Future<ExpenseStatsModel> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<ExpenseCategoriesResponseModel> getExpenseCategories({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  });

  Future<ExpenseCategoryModel> getExpenseCategoryById(String id);
  Future<ExpenseCategoryModel> createExpenseCategory(CreateExpenseCategoryRequestModel request);
  Future<ExpenseCategoryModel> updateExpenseCategory(String id, CreateExpenseCategoryRequestModel request);
  Future<void> deleteExpenseCategory(String id);
  Future<List<ExpenseCategoryModel>> searchExpenseCategories(String query);
}

class ExpenseRemoteDataSourceImpl implements ExpenseRemoteDataSource {
  final DioClient dioClient;

  ExpenseRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ExpensesListResponseModel> getExpenses({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? type,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search?.isNotEmpty == true) queryParams['search'] = search;
      if (status?.isNotEmpty == true) queryParams['status'] = status;
      if (type?.isNotEmpty == true) queryParams['type'] = type;
      if (categoryId?.isNotEmpty == true) queryParams['categoryId'] = categoryId;
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (orderBy?.isNotEmpty == true) queryParams['orderBy'] = orderBy;
      if (orderDirection?.isNotEmpty == true) queryParams['orderDirection'] = orderDirection;

      final response = await dioClient.get(
        ApiConstants.expenses,
        queryParameters: queryParams,
      );

      return ExpensesListResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener gastos',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener gastos: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final response = await dioClient.get('${ApiConstants.expenses}/$id');
      
      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }
      
      throw ServerException(
        'Gasto no encontrado',
        statusCode: 404,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> createExpense(CreateExpenseRequestModel request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.expenses,
        data: request.toJson(),
      );

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al crear el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al crear el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> updateExpense(String id, UpdateExpenseRequestModel request) async {
    try {
      final response = await dioClient.patch(
        '${ApiConstants.expenses}/$id',
        data: request.toJson(),
      );

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al actualizar el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al actualizar el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await dioClient.delete('${ApiConstants.expenses}/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al eliminar el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al eliminar el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> submitExpense(String id) async {
    try {
      final response = await dioClient.post('${ApiConstants.expenses}/$id/submit');

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al enviar el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al enviar el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> approveExpense(String id, String? notes) async {
    try {
      final data = <String, dynamic>{};
      if (notes?.isNotEmpty == true) data['notes'] = notes;

      final response = await dioClient.post(
        '${ApiConstants.expenses}/$id/approve',
        data: data,
      );

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al aprobar el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al aprobar el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> rejectExpense(String id, String reason) async {
    try {
      final response = await dioClient.post(
        '${ApiConstants.expenses}/$id/reject',
        data: {'reason': reason},
      );

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al rechazar el gasto',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al rechazar el gasto: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseModel> markAsPaid(String id) async {
    try {
      final response = await dioClient.post('${ApiConstants.expenses}/$id/mark-paid');

      final expenseResponse = ExpenseResponseModel.fromJson(response.data);
      if (expenseResponse.data != null) {
        return expenseResponse.data!;
      }

      throw ServerException(
        'Error al procesar la respuesta del servidor',
        statusCode: 500,
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al marcar como pagado',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al marcar como pagado: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.expenses}/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((expense) => ExpenseModel.fromJson(expense)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al buscar gastos',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al buscar gastos: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseStatsModel> getExpenseStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await dioClient.get(
        '${ApiConstants.expenses}/stats',
        queryParameters: queryParams,
      );

      return ExpenseStatsModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener estadísticas',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener estadísticas: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseCategoriesResponseModel> getExpenseCategories({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (search?.isNotEmpty == true) queryParams['search'] = search;
      if (status?.isNotEmpty == true) queryParams['status'] = status;
      if (orderBy?.isNotEmpty == true) queryParams['orderBy'] = orderBy;
      if (orderDirection?.isNotEmpty == true) queryParams['orderDirection'] = orderDirection;

      final response = await dioClient.get(
        ApiConstants.expenseCategories,
        queryParameters: queryParams,
      );

      return ExpenseCategoriesResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener categorías',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener categorías: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseCategoryModel> getExpenseCategoryById(String id) async {
    try {
      final response = await dioClient.get('${ApiConstants.expenseCategories}/$id');
      return ExpenseCategoryModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al obtener la categoría',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al obtener la categoría: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseCategoryModel> createExpenseCategory(CreateExpenseCategoryRequestModel request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.expenseCategories,
        data: request.toJson(),
      );

      return ExpenseCategoryModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al crear la categoría',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al crear la categoría: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<ExpenseCategoryModel> updateExpenseCategory(String id, CreateExpenseCategoryRequestModel request) async {
    try {
      final response = await dioClient.patch(
        '${ApiConstants.expenseCategories}/$id',
        data: request.toJson(),
      );

      return ExpenseCategoryModel.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al actualizar la categoría',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al actualizar la categoría: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<void> deleteExpenseCategory(String id) async {
    try {
      await dioClient.delete('${ApiConstants.expenseCategories}/$id');
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al eliminar la categoría',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al eliminar la categoría: $e',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ExpenseCategoryModel>> searchExpenseCategories(String query) async {
    try {
      final response = await dioClient.get(
        '${ApiConstants.expenseCategories}/search',
        queryParameters: {'q': query},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((category) => ExpenseCategoryModel.fromJson(category)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data['message'] ?? 'Error al buscar categorías',
        statusCode: e.response?.statusCode ?? 500,
      );
    } catch (e) {
      throw ServerException(
        'Error inesperado al buscar categorías: $e',
        statusCode: 500,
      );
    }
  }
}