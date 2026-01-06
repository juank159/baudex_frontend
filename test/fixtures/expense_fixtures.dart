// test/fixtures/expense_fixtures.dart
import 'package:baudex_desktop/features/expenses/domain/entities/expense.dart';
import 'package:baudex_desktop/features/expenses/domain/entities/expense_category.dart';

/// Test fixtures for Expenses module
class ExpenseFixtures {
  // ============================================================================
  // ENTITY FIXTURES (Domain Layer)
  // ============================================================================

  /// Creates a single expense entity with default test data
  static Expense createExpenseEntity({
    String id = 'exp-001',
    String description = 'Test Expense',
    double amount = 100000.0,
    DateTime? date,
    ExpenseStatus status = ExpenseStatus.pending,
    ExpenseType type = ExpenseType.operating,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? vendor = 'Test Vendor',
    String? invoiceNumber = 'INV-001',
    String? reference,
    String? notes,
    String categoryId = 'exp-cat-001',
    String createdById = 'user-001',
  }) {
    return Expense(
      id: id,
      description: description,
      amount: amount,
      date: date ?? DateTime(2024, 1, 1),
      status: status,
      type: type,
      paymentMethod: paymentMethod,
      vendor: vendor,
      invoiceNumber: invoiceNumber,
      reference: reference,
      notes: notes,
      categoryId: categoryId,
      createdById: createdById,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of expense entities
  static List<Expense> createExpenseEntityList(int count) {
    return List.generate(count, (index) {
      return createExpenseEntity(
        id: 'exp-${(index + 1).toString().padLeft(3, '0')}',
        description: 'Expense ${index + 1}',
        amount: (index + 1) * 50000.0,
        invoiceNumber: 'INV-${(index + 1).toString().padLeft(3, '0')}',
      );
    });
  }

  // ============================================================================
  // EXPENSE CATEGORY FIXTURES
  // ============================================================================

  /// Creates a single expense category entity
  static ExpenseCategory createExpenseCategoryEntity({
    String id = 'exp-cat-001',
    String name = 'Test Category',
    String? description = 'Test expense category',
    String? color = '#FF5722',
    ExpenseCategoryStatus status = ExpenseCategoryStatus.active,
    double monthlyBudget = 1000000.0,
    bool isRequired = false,
    int sortOrder = 0,
    double? monthlySpent,
    double? budgetUtilization,
  }) {
    return ExpenseCategory(
      id: id,
      name: name,
      description: description,
      color: color,
      status: status,
      monthlyBudget: monthlyBudget,
      isRequired: isRequired,
      sortOrder: sortOrder,
      monthlySpent: monthlySpent,
      budgetUtilization: budgetUtilization,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a list of expense category entities
  static List<ExpenseCategory> createExpenseCategoryEntityList(int count) {
    return List.generate(count, (index) {
      return createExpenseCategoryEntity(
        id: 'exp-cat-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Category ${index + 1}',
        sortOrder: index,
      );
    });
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES - EXPENSES
  // ============================================================================

  /// Creates a draft expense
  static Expense createDraftExpense({
    String id = 'exp-draft',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Draft Expense',
      status: ExpenseStatus.draft,
    );
  }

  /// Creates a pending expense
  static Expense createPendingExpense({
    String id = 'exp-pending',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Pending Expense',
      status: ExpenseStatus.pending,
    );
  }

  /// Creates an approved expense
  static Expense createApprovedExpense({
    String id = 'exp-approved',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Approved Expense',
      status: ExpenseStatus.approved,
    );
  }

  /// Creates a paid expense
  static Expense createPaidExpense({
    String id = 'exp-paid',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Paid Expense',
      status: ExpenseStatus.paid,
    );
  }

  /// Creates a rejected expense
  static Expense createRejectedExpense({
    String id = 'exp-rejected',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Rejected Expense',
      status: ExpenseStatus.rejected,
    );
  }

  /// Creates a high-value expense (requires approval)
  static Expense createHighValueExpense({
    String id = 'exp-high-value',
    double amount = 1000000.0,
  }) {
    return createExpenseEntity(
      id: id,
      description: 'High Value Expense',
      amount: amount,
      status: ExpenseStatus.pending,
      type: ExpenseType.extraordinary,
    );
  }

  /// Creates an operating expense
  static Expense createOperatingExpense({
    String id = 'exp-operating',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Office Supplies',
      type: ExpenseType.operating,
      amount: 150000.0,
    );
  }

  /// Creates an administrative expense
  static Expense createAdministrativeExpense({
    String id = 'exp-administrative',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Legal Services',
      type: ExpenseType.administrative,
      amount: 500000.0,
    );
  }

  /// Creates a sales expense
  static Expense createSalesExpense({
    String id = 'exp-sales',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Marketing Campaign',
      type: ExpenseType.sales,
      amount: 800000.0,
    );
  }

  /// Creates an expense with attachments
  static Expense createExpenseWithAttachments({
    String id = 'exp-with-attachments',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Expense with Attachments',
    );
  }

  /// Creates an expense with tags
  static Expense createExpenseWithTags({
    String id = 'exp-with-tags',
  }) {
    return createExpenseEntity(
      id: id,
      description: 'Expense with Tags',
    );
  }

  // ============================================================================
  // SPECIAL CASE FIXTURES - EXPENSE CATEGORIES
  // ============================================================================

  /// Creates an inactive expense category
  static ExpenseCategory createInactiveExpenseCategory({
    String id = 'exp-cat-inactive',
  }) {
    return createExpenseCategoryEntity(
      id: id,
      name: 'Inactive Category',
      status: ExpenseCategoryStatus.inactive,
    );
  }

  /// Creates a required expense category
  static ExpenseCategory createRequiredExpenseCategory({
    String id = 'exp-cat-required',
  }) {
    return createExpenseCategoryEntity(
      id: id,
      name: 'Utilities',
      isRequired: true,
      monthlyBudget: 500000.0,
    );
  }

  /// Creates a category over budget
  static ExpenseCategory createCategoryOverBudget({
    String id = 'exp-cat-over-budget',
  }) {
    return createExpenseCategoryEntity(
      id: id,
      name: 'Over Budget Category',
      monthlyBudget: 1000000.0,
      monthlySpent: 1200000.0,
      budgetUtilization: 120.0,
    );
  }

  /// Creates a category near budget limit
  static ExpenseCategory createCategoryNearBudgetLimit({
    String id = 'exp-cat-near-limit',
  }) {
    return createExpenseCategoryEntity(
      id: id,
      name: 'Near Budget Limit Category',
      monthlyBudget: 1000000.0,
      monthlySpent: 850000.0,
      budgetUtilization: 85.0,
    );
  }

  /// Creates a category within budget
  static ExpenseCategory createCategoryWithinBudget({
    String id = 'exp-cat-within-budget',
  }) {
    return createExpenseCategoryEntity(
      id: id,
      name: 'Within Budget Category',
      monthlyBudget: 1000000.0,
      monthlySpent: 500000.0,
      budgetUtilization: 50.0,
    );
  }

  // ============================================================================
  // BATCH CREATION HELPERS
  // ============================================================================

  /// Creates a mix of expenses with different statuses
  static List<Expense> createMixedStatusExpenses() {
    return [
      createDraftExpense(id: 'exp-001'),
      createPendingExpense(id: 'exp-002'),
      createApprovedExpense(id: 'exp-003'),
      createPaidExpense(id: 'exp-004'),
      createRejectedExpense(id: 'exp-005'),
    ];
  }

  /// Creates expenses by type
  static List<Expense> createExpensesByType() {
    return [
      createOperatingExpense(id: 'exp-001'),
      createAdministrativeExpense(id: 'exp-002'),
      createSalesExpense(id: 'exp-003'),
      createExpenseEntity(
        id: 'exp-004',
        description: 'Bank Fees',
        type: ExpenseType.financial,
      ),
      createExpenseEntity(
        id: 'exp-005',
        description: 'Emergency Repair',
        type: ExpenseType.extraordinary,
      ),
    ];
  }

  /// Creates expenses with different payment methods
  static List<Expense> createExpensesByPaymentMethod() {
    return [
      createExpenseEntity(
        id: 'exp-001',
        description: 'Cash Expense',
        paymentMethod: PaymentMethod.cash,
      ),
      createExpenseEntity(
        id: 'exp-002',
        description: 'Credit Card Expense',
        paymentMethod: PaymentMethod.creditCard,
      ),
      createExpenseEntity(
        id: 'exp-003',
        description: 'Bank Transfer Expense',
        paymentMethod: PaymentMethod.bankTransfer,
      ),
    ];
  }

  /// Creates expense categories with budget status
  static List<ExpenseCategory> createCategoriesByBudgetStatus() {
    return [
      createCategoryWithinBudget(id: 'exp-cat-001'),
      createCategoryNearBudgetLimit(id: 'exp-cat-002'),
      createCategoryOverBudget(id: 'exp-cat-003'),
    ];
  }
}
