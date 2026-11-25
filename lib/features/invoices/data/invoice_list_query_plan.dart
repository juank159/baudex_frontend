// lib/features/invoices/data/invoice_list_query_plan.dart

/// Por dónde entra la lista de facturas a la base local.
///
/// - [createdAt], [date], [dueDate]: se recorre el índice ya en el orden
///   pedido y se detiene al completar la página (no lee el resto).
/// - [dateRange], [customer]: el índice deja solo un pedazo (un rango de
///   fechas, un cliente) y ese pedazo se ordena.
/// - [status]: uno o varios estados con el orden por defecto: el índice
///   estado + fecha de creación entrega solo esas facturas (con un solo
///   estado, ya en orden).
/// - [fullScan]: no hay índice que sirva (orden por número o por total):
///   se filtra y ordena toda la colección, como antes.
enum InvoiceListIndex {
  createdAt,
  date,
  dueDate,
  dateRange,
  customer,
  status,
  fullScan,
}

/// ¿El orden pedido es el de por defecto (fecha de creación)? Un `sortBy`
/// desconocido también ordena por fecha de creación.
bool isCreatedAtSort(String sortBy) =>
    sortBy != 'number' &&
    sortBy != 'date' &&
    sortBy != 'total' &&
    sortBy != 'dueDate';

/// Regla pura (sin Isar ni Flutter) para elegir el índice de la lista.
///
/// El orden por defecto es `createdAt` (igual que el servidor y que el
/// `switch` de siempre: un `sortBy` desconocido también ordena por fecha
/// de creación).
InvoiceListIndex pickInvoiceListIndex({
  required String sortBy,
  bool hasDateRange = false,
  bool hasCustomer = false,
  bool hasStatus = false,
}) {
  // Un rango de fechas o un cliente reducen mucho el conjunto: se toma ese
  // pedazo por su índice y se ordena (es poco).
  if (hasDateRange) return InvoiceListIndex.dateRange;
  if (hasCustomer) return InvoiceListIndex.customer;
  // Un estado ("Pendientes", "Anuladas") suele ser una parte pequeña: se
  // toma por su índice, que además ya viene por fecha de creación.
  if (hasStatus && isCreatedAtSort(sortBy)) return InvoiceListIndex.status;
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
///
/// - Cliente: su índice va por fecha de creación; sirve si ese es el orden
///   pedido ([createdAtSort]).
/// - Estado: con un solo estado ([statusCount] = 1) el índice ya viene en
///   orden; con varios se juntan y hay que ordenar (son pocas).
bool invoiceIndexGivesOrder(
  InvoiceListIndex index, {
  bool createdAtSort = false,
  int statusCount = 1,
}) {
  switch (index) {
    case InvoiceListIndex.createdAt:
    case InvoiceListIndex.date:
    case InvoiceListIndex.dueDate:
      return true;
    case InvoiceListIndex.customer:
      return createdAtSort;
    case InvoiceListIndex.status:
      return statusCount == 1;
    case InvoiceListIndex.dateRange:
    case InvoiceListIndex.fullScan:
      return false;
  }
}

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
