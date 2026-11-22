// lib/features/invoices/data/invoice_list_query_plan.dart

/// Por dónde entra la lista de facturas a la base local.
///
/// - [createdAt], [date], [dueDate]: se recorre el índice ya en el orden
///   pedido y se detiene al completar la página (no lee el resto).
/// - [dateRange], [customer]: el índice deja solo un pedazo (un rango de
///   fechas, un cliente) y ese pedazo se ordena.
/// - [fullScan]: no hay índice que sirva (orden por número o por total):
///   se filtra y ordena toda la colección, como antes.
enum InvoiceListIndex { createdAt, date, dueDate, dateRange, customer, fullScan }

/// Regla pura (sin Isar ni Flutter) para elegir el índice de la lista.
///
/// El orden por defecto es `createdAt` (igual que el servidor y que el
/// `switch` de siempre: un `sortBy` desconocido también ordena por fecha
/// de creación).
InvoiceListIndex pickInvoiceListIndex({
  required String sortBy,
  bool hasDateRange = false,
  bool hasCustomer = false,
}) {
  // Un rango de fechas o un cliente reducen mucho el conjunto: se toma ese
  // pedazo por su índice y se ordena (es poco).
  if (hasDateRange) return InvoiceListIndex.dateRange;
  if (hasCustomer) return InvoiceListIndex.customer;
  switch (sortBy) {
    case 'date':
      return InvoiceListIndex.date;
    case 'dueDate':
      return InvoiceListIndex.dueDate;
    case 'number':
    case 'total':
      return InvoiceListIndex.fullScan;
    default:
      return InvoiceListIndex.createdAt;
  }
}

/// ¿El índice elegido ya entrega el orden pedido? Entonces no hace falta
/// ordenar y la base se detiene al llenar la página.
bool invoiceIndexGivesOrder(InvoiceListIndex index) =>
    index == InvoiceListIndex.createdAt ||
    index == InvoiceListIndex.date ||
    index == InvoiceListIndex.dueDate;

/// Datos de la paginación a partir del total y la página pedida.
({int totalPages, bool hasNextPage, bool hasPreviousPage}) invoicePageInfo({
  required int totalItems,
  required int page,
  required int limit,
}) {
  final totalPages = limit <= 0 ? 0 : (totalItems / limit).ceil();
  return (
    totalPages: totalPages,
    hasNextPage: page < totalPages,
    hasPreviousPage: page > 1,
  );
}
