import 'package:get/get.dart';
import 'package:timezone/timezone.dart' as tz;

class TenantDateTimeService extends GetxService {
  late tz.Location _location;
  String _currentTimezone = 'America/Bogota';

  String get currentTimezone => _currentTimezone;

  @override
  void onInit() {
    super.onInit();
    _location = tz.getLocation(_currentTimezone);
  }

  /// Actualiza la timezone del tenant (llamado desde OrganizationController)
  void updateTimezone(String tzName) {
    try {
      _location = tz.getLocation(tzName);
      _currentTimezone = tzName;
    } catch (e) {
      // Fallback a Bogota si el timezone no es válido
      _location = tz.getLocation('America/Bogota');
      _currentTimezone = 'America/Bogota';
    }
  }

  /// Ahora en la timezone del tenant
  DateTime now() => tz.TZDateTime.now(_location);

  /// Convertir UTC → timezone del tenant (para mostrar fechas del servidor)
  DateTime toLocal(DateTime utcDateTime) {
    return tz.TZDateTime.from(utcDateTime.toUtc(), _location);
  }

  /// Hoy a las 00:00 en timezone del tenant
  DateTime startOfToday() {
    final n = tz.TZDateTime.now(_location);
    return tz.TZDateTime(_location, n.year, n.month, n.day);
  }

  /// Final de hoy (23:59:59.999) en timezone del tenant
  DateTime endOfToday() {
    final n = tz.TZDateTime.now(_location);
    return tz.TZDateTime(_location, n.year, n.month, n.day, 23, 59, 59, 999);
  }

  /// Inicio de la semana (lunes) en timezone del tenant
  DateTime startOfWeek() {
    final n = tz.TZDateTime.now(_location);
    final weekday = n.weekday; // 1=lunes, 7=domingo
    final start = n.subtract(Duration(days: weekday - 1));
    return tz.TZDateTime(_location, start.year, start.month, start.day);
  }

  /// Inicio del mes en timezone del tenant
  DateTime startOfMonth() {
    final n = tz.TZDateTime.now(_location);
    return tz.TZDateTime(_location, n.year, n.month, 1);
  }

  /// Inicio del año en timezone del tenant
  DateTime startOfYear() {
    final n = tz.TZDateTime.now(_location);
    return tz.TZDateTime(_location, n.year, 1, 1);
  }

  /// Crear un DateTime en la timezone del tenant
  DateTime dateInTenantTz(int year, int month, int day,
      [int hour = 0, int minute = 0, int second = 0]) {
    return tz.TZDateTime(_location, year, month, day, hour, minute, second);
  }
}
