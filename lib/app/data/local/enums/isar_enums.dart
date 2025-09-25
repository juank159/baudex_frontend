// lib/app/data/local/enums/isar_enums.dart
import 'package:isar/isar.dart';

// ==================== PRODUCT ENUMS ====================

@Name('ProductType')
enum IsarProductType {
  @Name('product')
  product,
  @Name('service')
  service,
}

@Name('ProductStatus')
enum IsarProductStatus {
  @Name('active')
  active,
  @Name('inactive')
  inactive,
  @Name('outOfStock')
  outOfStock,
}

@Name('PriceType')
enum IsarPriceType {
  @Name('price1')
  price1,
  @Name('price2')
  price2,
  @Name('price3')
  price3,
  @Name('special')
  special,
  @Name('cost')
  cost,
}

@Name('PriceStatus')
enum IsarPriceStatus {
  @Name('active')
  active,
  @Name('inactive')
  inactive,
}

// ==================== CUSTOMER ENUMS ====================

@Name('DocumentType')
enum IsarDocumentType {
  @Name('cc')
  cc,
  @Name('nit')
  nit,
  @Name('ce')
  ce,
  @Name('passport')
  passport,
  @Name('other')
  other,
}

@Name('CustomerStatus')
enum IsarCustomerStatus {
  @Name('active')
  active,
  @Name('inactive')
  inactive,
  @Name('suspended')
  suspended,
}

// ==================== CATEGORY ENUMS ====================

@Name('CategoryStatus')
enum IsarCategoryStatus {
  @Name('active')
  active,
  @Name('inactive')
  inactive,
}

// ==================== INVOICE ENUMS ====================

@Name('InvoiceStatus')
enum IsarInvoiceStatus {
  @Name('draft')
  draft,
  @Name('pending')
  pending,
  @Name('paid')
  paid,
  @Name('overdue')
  overdue,
  @Name('cancelled')
  cancelled,
  @Name('partiallyPaid')
  partiallyPaid,
}

@Name('PaymentMethod')
enum IsarPaymentMethod {
  @Name('cash')
  cash,
  @Name('credit')
  credit,
  @Name('creditCard')
  creditCard,
  @Name('debitCard')
  debitCard,
  @Name('bankTransfer')
  bankTransfer,
  @Name('check')
  check,
  @Name('other')
  other,
}

// ==================== EXPENSE ENUMS ====================

@Name('ExpenseStatus')
enum IsarExpenseStatus {
  @Name('draft')
  draft,
  @Name('pending')
  pending,
  @Name('approved')
  approved,
  @Name('rejected')
  rejected,
  @Name('paid')
  paid,
}

@Name('ExpenseType')
enum IsarExpenseType {
  @Name('operating')
  operating,
  @Name('administrative')
  administrative,
  @Name('sales')
  sales,
  @Name('financial')
  financial,
  @Name('extraordinary')
  extraordinary,
}

@Name('ExpenseCategoryStatus')
enum IsarExpenseCategoryStatus {
  @Name('active')
  active,
  @Name('inactive')
  inactive,
}

// ==================== ORGANIZATION ENUMS ====================

@Name('SubscriptionPlan')
enum IsarSubscriptionPlan {
  @Name('trial')
  trial,
  @Name('basic')
  basic,
  @Name('premium')
  premium,
  @Name('enterprise')
  enterprise,
}

@Name('SubscriptionStatus')
enum IsarSubscriptionStatus {
  @Name('active')
  active,
  @Name('expired')
  expired,
  @Name('cancelled')
  cancelled,
  @Name('suspended')
  suspended,
}

// ==================== NOTIFICATION ENUMS ====================

@Name('NotificationType')
enum IsarNotificationType {
  @Name('system')
  system,
  @Name('payment')
  payment,
  @Name('invoice')
  invoice,
  @Name('lowStock')
  lowStock,
  @Name('expense')
  expense,
  @Name('sale')
  sale,
  @Name('user')
  user,
  @Name('reminder')
  reminder,
}

@Name('NotificationPriority')
enum IsarNotificationPriority {
  @Name('low')
  low,
  @Name('medium')
  medium,
  @Name('high')
  high,
  @Name('urgent')
  urgent,
}