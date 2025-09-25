// lib/app/data/local/isar_test_models.dart
// import 'package:isar/isar.dart';

// part 'isar_test_models.g.dart'; // Comentado temporalmente hasta resolver problema ISAR

// @collection // Comentado temporalmente hasta resolver problema ISAR
class TestProduct {
  // Id id = Isar.autoIncrement; // Comentado temporalmente
  int id = 0;
  
  // @Index(unique: true)
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

// @collection  
class TestCustomer {
  // Id id = Isar.autoIncrement;
  int id = 0;
  
  // @Index(unique: true)
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

// @collection
class TestInvoice {
  // Id id = Isar.autoIncrement;
  int id = 0;
  
  // @Index(unique: true)
  late String serverId;
  
  late String invoiceNumber;
  late String customerId;
  late double total;
  late DateTime invoiceDate;
  late bool isActive;
  late DateTime createdAt;
  late DateTime updatedAt;
  late bool isSynced;
  
  TestInvoice();
}