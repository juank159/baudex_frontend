// lib/features/expenses/data/models/isar/isar_expense_category.dart
import 'package:baudex_desktop/app/data/local/enums/isar_enums.dart';
import 'package:baudex_desktop/features/expenses/domain/entities/expense_category.dart';
// import 'package:isar/isar.dart';

// part 'isar_expense_category.g.dart';

// @collection
class IsarExpenseCategory {
  // Id id = Isar.autoIncrement;
  int id = 0;

  // @Index(unique: true)
  late String serverId;

  // @Index()
  late String name;

  String? description;
  String? color; // Color en hexadecimal

  // @Enumerated(EnumType.name)
  late IsarExpenseCategoryStatus status;

  late double monthlyBudget;
  late bool isRequired;
  late int sortOrder;

  // Campos de auditoría
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  // Campos de sincronización
  late bool isSynced;
  DateTime? lastSyncAt;

  // Constructores
  IsarExpenseCategory();

  IsarExpenseCategory.create({
    required this.serverId,
    required this.name,
    this.description,
    this.color,
    required this.status,
    required this.monthlyBudget,
    required this.isRequired,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.isSynced,
    this.lastSyncAt,
  });

  // Mappers
  static IsarExpenseCategory fromEntity(ExpenseCategory entity) {
    return IsarExpenseCategory.create(
      serverId: entity.id,
      name: entity.name,
      description: entity.description,
      color: entity.color,
      status: _mapExpenseCategoryStatus(entity.status),
      monthlyBudget: entity.monthlyBudget,
      isRequired: entity.isRequired,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
      isSynced: true,
      lastSyncAt: DateTime.now(),
    );
  }

  ExpenseCategory toEntity() {
    return ExpenseCategory(
      id: serverId,
      name: name,
      description: description,
      color: color,
      status: _mapIsarExpenseCategoryStatus(status),
      monthlyBudget: monthlyBudget,
      isRequired: isRequired,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  // Helpers para mapeo de enums
  static IsarExpenseCategoryStatus _mapExpenseCategoryStatus(
    ExpenseCategoryStatus status,
  ) {
    switch (status) {
      case ExpenseCategoryStatus.active:
        return IsarExpenseCategoryStatus.active;
      case ExpenseCategoryStatus.inactive:
        return IsarExpenseCategoryStatus.inactive;
    }
  }

  static ExpenseCategoryStatus _mapIsarExpenseCategoryStatus(
    IsarExpenseCategoryStatus status,
  ) {
    switch (status) {
      case IsarExpenseCategoryStatus.active:
        return ExpenseCategoryStatus.active;
      case IsarExpenseCategoryStatus.inactive:
        return ExpenseCategoryStatus.inactive;
    }
  }

  // Métodos de utilidad
  bool get isDeleted => deletedAt != null;
  bool get isActive => status == IsarExpenseCategoryStatus.active && !isDeleted;
  bool get needsSync => !isSynced;
  bool get hasBudget => monthlyBudget > 0;

  void markAsUnsynced() {
    isSynced = false;
    updatedAt = DateTime.now();
  }

  void markAsSynced() {
    isSynced = true;
    lastSyncAt = DateTime.now();
  }

  void softDelete() {
    deletedAt = DateTime.now();
    markAsUnsynced();
  }

  void updateBudget(double newBudget) {
    monthlyBudget = newBudget;
    markAsUnsynced();
  }

  @override
  String toString() {
    return 'IsarExpenseCategory{serverId: $serverId, name: $name, monthlyBudget: $monthlyBudget, isSynced: $isSynced}';
  }
}
