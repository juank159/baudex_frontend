// lib/features/dashboard/data/datasources/dashboard_remote_datasource_extensions.dart
import 'package:dio/dio.dart';
import '../models/recent_activity_advanced_model.dart';
import '../models/smart_notification_model.dart';

extension DashboardRemoteDataSourceExtensions on Object {
  // Extension para agregar métodos de actividades y notificaciones
}

class DashboardActivitiesDataSource {
  final Dio dio;

  DashboardActivitiesDataSource({required this.dio});

  Future<List<RecentActivityAdvancedModel>> getRecentActivities({
    int limit = 20,
    String? category,
    String? priority,
    String? timeFilter,
  }) async {
    final response = await dio.get(
      '/dashboard/activities/recent',
      queryParameters: {
        'limit': limit,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (timeFilter != null) 'timeFilter': timeFilter,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final activities = (data['activities'] as List)
          .map((json) => RecentActivityAdvancedModel.fromJson(json))
          .toList();
      return activities;
    } else {
      throw Exception('Failed to load recent activities');
    }
  }
}

class DashboardNotificationsDataSource {
  final Dio dio;

  DashboardNotificationsDataSource({required this.dio});

  Future<List<SmartNotificationModel>> getNotifications({
    int limit = 50,
    List<String>? priorities,
    List<String>? types,
    bool includeRead = false,
  }) async {
    final response = await dio.get(
      '/dashboard/notifications',
      queryParameters: {
        'limit': limit,
        if (priorities != null) 'priorities': priorities.join(','),
        if (types != null) 'types': types.join(','),
        'includeRead': includeRead,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'];
      final notifications = (data['notifications'] as List)
          .map((json) => SmartNotificationModel.fromJson(json))
          .toList();
      return notifications;
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<int> getUnreadNotificationsCount() async {
    final response = await dio.get('/dashboard/notifications/unread-count');

    if (response.statusCode == 200) {
      final data = response.data['data'];
      return data['unreadCount'] as int;
    } else {
      throw Exception('Failed to load unread notifications count');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await dio.patch('/dashboard/notifications/$notificationId/read');

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markMultipleAsRead(List<String> notificationIds) async {
    final response = await dio.patch(
      '/dashboard/notifications/mark-multiple-read',
      data: {'notificationIds': notificationIds},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }
}