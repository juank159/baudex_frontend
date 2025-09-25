// lib/app/data/local/isar_test_models_temp.dart
// Archivo temporal sin anotaciones ISAR para permitir compilación

// Modelos temporales sin ISAR hasta resolver problema de generación
class TestProduct {
  int id = 0;
  late String serverId;
  late String name;
  late String sku;
  late double price;
  late int stock;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;
  
  TestProduct();
}

class TestCustomer {
  int id = 0;
  late String serverId;
  late String name;
  late String email;
  late String phone;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;
  
  TestCustomer();
}

class TestInvoice {
  int id = 0;
  late String serverId;
  late String number;
  late String customerId;
  late double total;
  late double subtotal;
  late double tax;
  late bool isPaid;
  late DateTime dueDate;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;
  
  TestInvoice();
}

// Schemas temporales vacíos para compatibilidad
class TestProductSchema {
  static const String name = 'TestProduct';
}

class TestCustomerSchema {
  static const String name = 'TestCustomer';
}

class TestInvoiceSchema {
  static const String name = 'TestInvoice';
}