// lib/features/dashboard/data/datasources/dashboard_local_datasource.dart
import '../../../../app/core/storage/secure_storage_service.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/dashboard_stats_model.dart';
import '../models/recent_activity_model.dart';
import '../models/notification_model.dart';
import 'dart:convert';

abstract class DashboardLocalDataSource {
  Future<DashboardStatsModel?> getCachedDashboardStats();
  Future<void> cacheDashboardStats(DashboardStatsModel stats);
  
  Future<List<RecentActivityModel>?> getCachedRecentActivity();
  Future<void> cacheRecentActivity(List<RecentActivityModel> activities);
  
  Future<List<NotificationModel>?> getCachedNotifications();
  Future<void> cacheNotifications(List<NotificationModel> notifications);
  
  Future<int?> getCachedUnreadNotificationsCount();
  Future<void> cacheUnreadNotificationsCount(int count);
  
  Future<void> clearCache();
}

class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  final SecureStorageService secureStorage;
  
  static const String _dashboardStatsKey = 'dashboard_stats';
  static const String _recentActivityKey = 'recent_activity';
  static const String _notificationsKey = 'notifications';
  static const String _unreadCountKey = 'unread_notifications_count';
  static const String _cacheTimestampKey = 'dashboard_cache_timestamp';
  static const int _cacheExpirationMinutes = 5; // Cache válido por 5 minutos

  DashboardLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<DashboardStatsModel?> getCachedDashboardStats() async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final cachedData = await secureStorage.read(_dashboardStatsKey);
      if (cachedData == null) return null;

      final jsonData = json.decode(cachedData);
      return DashboardStatsModel.fromJson(jsonData);
    } catch (e) {
      throw CacheException('Error al leer estadísticas del dashboard desde cache: $e');
    }
  }

  @override
  Future<void> cacheDashboardStats(DashboardStatsModel stats) async {
    try {
      final jsonData = json.encode(stats.toJson());
      await secureStorage.write(_dashboardStatsKey, jsonData);
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar estadísticas del dashboard en cache: $e');
    }
  }

  @override
  Future<List<RecentActivityModel>?> getCachedRecentActivity() async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final cachedData = await secureStorage.read(_recentActivityKey);
      if (cachedData == null) return null;

      final List<dynamic> jsonList = json.decode(cachedData);
      return jsonList.map((item) => RecentActivityModel.fromJson(item)).toList();
    } catch (e) {
      throw CacheException('Error al leer actividad reciente desde cache: $e');
    }
  }

  @override
  Future<void> cacheRecentActivity(List<RecentActivityModel> activities) async {
    try {
      final jsonList = activities.map((activity) => activity.toJson()).toList();
      final jsonData = json.encode(jsonList);
      await secureStorage.write(_recentActivityKey, jsonData);
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar actividad reciente en cache: $e');
    }
  }

  @override
  Future<List<NotificationModel>?> getCachedNotifications() async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final cachedData = await secureStorage.read(_notificationsKey);
      if (cachedData == null) return null;

      final List<dynamic> jsonList = json.decode(cachedData);
      return jsonList.map((item) => NotificationModel.fromJson(item)).toList();
    } catch (e) {
      throw CacheException('Error al leer notificaciones desde cache: $e');
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications) async {
    try {
      final jsonList = notifications.map((notification) => notification.toJson()).toList();
      final jsonData = json.encode(jsonList);
      await secureStorage.write(_notificationsKey, jsonData);
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar notificaciones en cache: $e');
    }
  }

  @override
  Future<int?> getCachedUnreadNotificationsCount() async {
    try {
      if (!await _isCacheValid()) {
        return null;
      }

      final cachedData = await secureStorage.read(_unreadCountKey);
      if (cachedData == null) return null;

      return int.tryParse(cachedData);
    } catch (e) {
      throw CacheException('Error al leer conteo de notificaciones desde cache: $e');
    }
  }

  @override
  Future<void> cacheUnreadNotificationsCount(int count) async {
    try {
      await secureStorage.write(_unreadCountKey, count.toString());
      await _updateCacheTimestamp();
    } catch (e) {
      throw CacheException('Error al guardar conteo de notificaciones en cache: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await Future.wait([
        secureStorage.delete(_dashboardStatsKey),
        secureStorage.delete(_recentActivityKey),
        secureStorage.delete(_notificationsKey),
        secureStorage.delete(_unreadCountKey),
        secureStorage.delete(_cacheTimestampKey),
      ]);
    } catch (e) {
      throw CacheException('Error al limpiar cache del dashboard: $e');
    }
  }

  Future<bool> _isCacheValid() async {
    try {
      final timestampStr = await secureStorage.read(_cacheTimestampKey);
      if (timestampStr == null) return false;

      final timestamp = DateTime.tryParse(timestampStr);
      if (timestamp == null) return false;

      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      return difference.inMinutes < _cacheExpirationMinutes;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateCacheTimestamp() async {
    try {
      final now = DateTime.now().toIso8601String();
      await secureStorage.write(_cacheTimestampKey, now);
    } catch (e) {
      // Error silencioso para timestamp
    }
  }
}