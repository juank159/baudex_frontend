// lib/features/purchase_orders/data/models/purchase_order_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/purchase_order.dart';

part 'purchase_order_model.g.dart';

String? _parseStringFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

@JsonSerializable()
class PurchaseOrderModel {
  final String id;
  final String? orderNumber;
  final String? supplierId;
  final String? supplierName;
  final String? status;
  final String? priority;
  final String? orderDate;
  final String? expectedDeliveryDate;
  final String? deliveredDate;
  final String? actualDeliveryDate;
  final String? supplierReference;
  final String? terms;
  final String? taxPercentage;
  final String? discountPercentage;
  final String? shippingCost;
  final String? currency;
  @JsonKey(fromJson: _parseDouble)
  final double subtotal;
  @JsonKey(fromJson: _parseDouble)
  final double taxAmount;
  @JsonKey(fromJson: _parseDouble)
  final double discountAmount;
  @JsonKey(name: 'total', fromJson: _parseDouble)
  final double totalAmount;

  static double _parseDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0.0;
  }

  static String? _parseCreatedBy(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final firstName = value['firstName'] as String?;
      final lastName = value['lastName'] as String?;
      if (firstName != null && lastName != null) {
        return '$firstName $lastName';
      }
      return value['email'] as String? ?? value['id'] as String?;
    }
    return value.toString();
  }

  static String? _parseApprovedBy(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final firstName = value['firstName'] as String?;
      final lastName = value['lastName'] as String?;
      if (firstName != null && lastName != null) {
        return '$firstName $lastName';
      }
      return value['email'] as String? ?? value['id'] as String?;
    }
    return value.toString();
  }


  final List<PurchaseOrderItemModel>? items;
  final String? notes;
  final String? internalNotes;
  final String? deliveryAddress;
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? supplier;
  final List<dynamic>? batches;
  @JsonKey(fromJson: _parseCreatedBy)
  final String? createdBy;
  @JsonKey(fromJson: _parseApprovedBy)
  final String? approvedBy;
  final String? approvedAt;
  final String? createdAt;
  final String? updatedAt;

  const PurchaseOrderModel({
    required this.id,
    this.orderNumber,
    this.supplierId,
    this.supplierName,
    this.status,
    this.priority,
    this.orderDate,
    this.expectedDeliveryDate,
    this.deliveredDate,
    this.actualDeliveryDate,
    this.supplierReference,
    this.terms,
    this.taxPercentage,
    this.discountPercentage,
    this.shippingCost,
    this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    this.items,
    this.notes,
    this.internalNotes,
    this.deliveryAddress,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.attachments,
    this.metadata,
    this.supplier,
    this.batches,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrderModel.fromJson(Map<String, dynamic> json) {
    try {
      // Extraer supplierName del objeto supplier si está disponible
      String? supplierName = json['supplierName'] as String?;
      if (supplierName == null && json['supplier'] != null) {
        final supplier = json['supplier'] as Map<String, dynamic>;
        supplierName = supplier['name'] as String?;
        print('🏢 DEBUG: Extrayendo supplierName del objeto supplier: $supplierName');
      }
      
      // Extraer supplierId del objeto supplier si está disponible
      String? supplierId = json['supplierId'] as String?;
      if (supplierId == null && json['supplier'] != null) {
        final supplier = json['supplier'] as Map<String, dynamic>;
        supplierId = supplier['id'] as String?;
      }
      
      // Crear el json modificado
      final modifiedJson = Map<String, dynamic>.from(json);
      modifiedJson['supplierName'] = supplierName;
      modifiedJson['supplierId'] = supplierId;
      
      return _$PurchaseOrderModelFromJson(modifiedJson);
    } catch (e) {
      print('❌ Error en PurchaseOrderModel.fromJson: $e');
      print('📋 JSON recibido: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$PurchaseOrderModelToJson(this);

  PurchaseOrder toEntity() {
    try {
      print('🔍 Convirtiendo model a entity - ID: $id');
      print('🔍 Fechas: orderDate=$orderDate, expectedDeliveryDate=$expectedDeliveryDate');
      
      final parsedOrderDate = orderDate != null && orderDate!.isNotEmpty ? DateTime.parse(orderDate!) : null;
      final parsedExpectedDeliveryDate = expectedDeliveryDate != null && expectedDeliveryDate!.isNotEmpty ? DateTime.parse(expectedDeliveryDate!) : null;
      final parsedDeliveredDate = deliveredDate != null && deliveredDate!.isNotEmpty ? DateTime.parse(deliveredDate!) : null;
      
      print('🔍 Fechas parseadas correctamente');
      
      // Procesar items y extraer información de damaged/missing desde batches
      final entityItems = <PurchaseOrderItem>[];
      if (items != null) {
        for (int i = 0; i < items!.length; i++) {
          final item = items![i];
          var damagedQty = double.tryParse(item.damagedQuantity ?? '0')?.toInt();
          var missingQty = double.tryParse(item.missingQuantity ?? '0')?.toInt();
          
          // Si no tenemos damaged/missing del item, extraer desde batches
          if ((damagedQty == null || damagedQty == 0) && (missingQty == null || missingQty == 0)) {
            if (batches != null && i < batches!.length) {
              final batchInfo = PurchaseOrderItemModel._extractDamagedMissingFromBatch(batches![i]);
              damagedQty = batchInfo['damaged'];
              missingQty = batchInfo['missing'];
              print('🔍 Extraído de batch para item $i: damaged=$damagedQty, missing=$missingQty');
            }
          }
          
          entityItems.add(item.toEntity().copyWith(
            damagedQuantity: damagedQty,
            missingQuantity: missingQty,
          ));
        }
      }
      
      print('🔍 Items convertidos: ${entityItems.length}');
      
      return PurchaseOrder(
        id: id,
        orderNumber: orderNumber,
        supplierId: supplierId,
        supplierName: supplierName,
        status: _parseStatus(status ?? 'pending'),
        priority: _parsePriority(priority ?? 'medium'),
        orderDate: parsedOrderDate,
        expectedDeliveryDate: parsedExpectedDeliveryDate,
        deliveredDate: parsedDeliveredDate,
        currency: currency,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        items: entityItems,
        notes: notes,
        internalNotes: internalNotes,
        deliveryAddress: deliveryAddress,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        attachments: attachments,
        createdBy: createdBy,
        approvedBy: approvedBy,
        approvedAt: approvedAt != null && approvedAt!.isNotEmpty ? DateTime.parse(approvedAt!) : null,
        createdAt: createdAt != null && createdAt!.isNotEmpty ? DateTime.parse(createdAt!) : null,
        updatedAt: updatedAt != null && updatedAt!.isNotEmpty ? DateTime.parse(updatedAt!) : null,
      );
    } catch (e) {
      print('❌ Error en PurchaseOrderModel.toEntity(): $e');
      print('📋 Datos del modelo: {id: $id, orderNumber: $orderNumber, status: $status}');
      print('📋 Fechas: orderDate=$orderDate, expectedDeliveryDate=$expectedDeliveryDate');
      rethrow;
    }
  }

  factory PurchaseOrderModel.fromEntity(PurchaseOrder entity) {
    return PurchaseOrderModel(
      id: entity.id,
      orderNumber: entity.orderNumber,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      status: entity.status.name,
      priority: entity.priority.name,
      orderDate: entity.orderDate?.toIso8601String(),
      expectedDeliveryDate: entity.expectedDeliveryDate?.toIso8601String(),
      deliveredDate: entity.deliveredDate?.toIso8601String(),
      actualDeliveryDate: null,
      supplierReference: null,
      terms: null,
      taxPercentage: null,
      discountPercentage: null,
      shippingCost: null,
      currency: entity.currency,
      subtotal: entity.subtotal,
      taxAmount: entity.taxAmount,
      discountAmount: entity.discountAmount,
      totalAmount: entity.totalAmount,
      items: entity.items.map((item) => PurchaseOrderItemModel.fromEntity(item)).toList(),
      notes: entity.notes,
      internalNotes: entity.internalNotes,
      deliveryAddress: entity.deliveryAddress,
      contactPerson: entity.contactPerson,
      contactPhone: entity.contactPhone,
      contactEmail: entity.contactEmail,
      attachments: entity.attachments,
      metadata: null,
      supplier: null,
      batches: null,
      createdBy: entity.createdBy,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt?.toIso8601String(),
      createdAt: entity.createdAt?.toIso8601String(),
      updatedAt: entity.updatedAt?.toIso8601String(),
    );
  }

  static PurchaseOrderStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return PurchaseOrderStatus.draft;
      case 'pending':
        return PurchaseOrderStatus.pending;
      case 'approved':
        return PurchaseOrderStatus.approved;
      case 'rejected':
        return PurchaseOrderStatus.rejected;
      case 'sent':
        return PurchaseOrderStatus.sent;
      case 'partially_received':
        return PurchaseOrderStatus.partiallyReceived;
      case 'received':
        return PurchaseOrderStatus.received;
      case 'cancelled':
        return PurchaseOrderStatus.cancelled;
      default:
        return PurchaseOrderStatus.draft;
    }
  }

  static PurchaseOrderPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return PurchaseOrderPriority.low;
      case 'medium':
        return PurchaseOrderPriority.medium;
      case 'high':
        return PurchaseOrderPriority.high;
      case 'urgent':
        return PurchaseOrderPriority.urgent;
      default:
        return PurchaseOrderPriority.medium;
    }
  }
}

@JsonSerializable()
class PurchaseOrderItemModel {
  final String? id;
  final String? productId;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int? lineNumber;
  final String? quantity;
  final String? unitCost;
  @JsonKey(fromJson: _parseStringFromDynamic)
  final String? totalCost;
  final String? receivedQuantity;
  final String? damagedQuantity;
  final String? missingQuantity;
  final String? pendingQuantity;
  final String? expectedDate;
  final String? lastReceivedDate;
  final Map<String, dynamic>? metadata;
  final String? organizationId;
  final String? purchaseOrderId;
  final Map<String, dynamic>? product;

  const PurchaseOrderItemModel({
    this.id,
    this.productId,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.lineNumber,
    this.quantity,
    this.unitCost,
    this.totalCost,
    this.receivedQuantity,
    this.damagedQuantity,
    this.missingQuantity,
    this.pendingQuantity,
    this.expectedDate,
    this.lastReceivedDate,
    this.metadata,
    this.organizationId,
    this.purchaseOrderId,
    this.product,
  });

  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderItemModelToJson(this);

  PurchaseOrderItem toEntity() {
    try {
      return PurchaseOrderItem(
        id: id ?? '',
        productId: productId ?? '',
        productName: product?['name'] ?? 'Producto sin nombre',
        productCode: product?['sku'],
        productDescription: product?['description'],
        unit: '',
        quantity: double.tryParse(quantity ?? '0')?.toInt() ?? 0,
        receivedQuantity: double.tryParse(receivedQuantity ?? '0')?.toInt() ?? 0,
        damagedQuantity: double.tryParse(damagedQuantity ?? '0')?.toInt(),
        missingQuantity: double.tryParse(missingQuantity ?? '0')?.toInt(),
        unitPrice: double.tryParse(unitCost ?? '0') ?? 0.0,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        subtotal: double.tryParse(totalCost ?? '0') ?? 0.0,
        taxPercentage: 0.0,
        taxAmount: 0.0,
        totalAmount: double.tryParse(totalCost ?? '0') ?? 0.0,
        notes: notes,
        createdAt: createdAt != null && createdAt!.isNotEmpty ? DateTime.parse(createdAt!) : DateTime.now(),
        updatedAt: updatedAt != null && updatedAt!.isNotEmpty ? DateTime.parse(updatedAt!) : DateTime.now(),
      );
    } catch (e) {
      print('❌ Error en PurchaseOrderItemModel.toEntity(): $e');
      print('📋 Item data: {id: $id, productId: $productId, quantity: $quantity}');
      rethrow;
    }
  }

  static Map<String, int> _extractDamagedMissingFromBatch(dynamic batch) {
    final Map<String, int> result = {'damaged': 0, 'missing': 0};
    
    try {
      if (batch is Map<String, dynamic> && batch['metadata'] != null) {
        final metadata = batch['metadata'] as Map<String, dynamic>;
        final notes = metadata['notes'] as String?;
        
        if (notes != null) {
          // Buscar patrones como "Dañados: 10" o "Faltantes: 15"
          final damagedMatch = RegExp(r'Dañados:\s*(\d+)').firstMatch(notes);
          final missingMatch = RegExp(r'Faltantes:\s*(\d+)').firstMatch(notes);
          
          if (damagedMatch != null) {
            result['damaged'] = int.tryParse(damagedMatch.group(1) ?? '0') ?? 0;
          }
          
          if (missingMatch != null) {
            result['missing'] = int.tryParse(missingMatch.group(1) ?? '0') ?? 0;
          }
        }
      }
    } catch (e) {
      print('⚠️ Error extracting damaged/missing from batch metadata: $e');
    }
    
    return result;
  }

  factory PurchaseOrderItemModel.fromEntity(PurchaseOrderItem entity) {
    return PurchaseOrderItemModel(
      id: entity.id,
      productId: entity.productId,
      notes: entity.notes,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      deletedAt: null,
      lineNumber: 1,
      quantity: entity.quantity.toString(),
      unitCost: entity.unitPrice.toString(),
      totalCost: entity.totalAmount.toString(),
      receivedQuantity: (entity.receivedQuantity ?? 0).toString(),
      damagedQuantity: (entity.damagedQuantity ?? 0).toString(),
      missingQuantity: (entity.missingQuantity ?? 0).toString(),
      pendingQuantity: (entity.quantity - (entity.receivedQuantity ?? 0)).toString(),
      expectedDate: null,
      lastReceivedDate: null,
      metadata: null,
      organizationId: null,
      purchaseOrderId: '',
      product: null,
    );
  }
}

@JsonSerializable()
class PurchaseOrderStatsModel {
  final int total;
  @JsonKey(name: 'byStatus')
  final Map<String, int> byStatus;
  @JsonKey(name: 'totalValue')
  final num totalValue;
  @JsonKey(name: 'averageOrderValue')
  final num? averageOrderValue;

  const PurchaseOrderStatsModel({
    required this.total,
    required this.byStatus,
    required this.totalValue,
    this.averageOrderValue,
  });

  factory PurchaseOrderStatsModel.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderStatsModelToJson(this);

  PurchaseOrderStats toEntity({List<PurchaseOrder> orders = const []}) {
    return PurchaseOrderStats(
      totalPurchaseOrders: total,
      pendingOrders: byStatus['pending'] ?? 0,
      approvedOrders: byStatus['approved'] ?? 0,
      sentOrders: byStatus['sent'] ?? 0,
      partiallyReceivedOrders: byStatus['partially_received'] ?? 0,
      receivedOrders: byStatus['received'] ?? 0,
      cancelledOrders: byStatus['cancelled'] ?? 0,
      overdueOrders: 0, // No disponible en el backend actual
      totalValue: totalValue.toDouble(),
      averageOrderValue: averageOrderValue?.toDouble() ?? 0.0,
      totalPending: 0, // No disponible en el backend actual
      totalReceived: 0, // No disponible en el backend actual
      ordersBySupplier: {}, // No disponible en el backend actual
      valueBySupplier: {}, // No disponible en el backend actual
      ordersByMonth: {}, // No disponible en el backend actual
      topOrdersByValue: [], // No disponible en el backend actual
      recentActivity: [], // No disponible en el backend actual
      cancellationRate: 0.0, // No disponible en el backend actual
      orders: orders, // Pasar las órdenes para cálculos dinámicos
    );
  }
}