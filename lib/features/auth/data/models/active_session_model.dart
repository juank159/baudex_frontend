import 'package:flutter/material.dart';

class ActiveSessionModel {
  final String id;
  final String userId;
  final String organizationId;
  final String deviceInfo;
  final String? ipAddress;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final bool isActive;

  const ActiveSessionModel({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.deviceInfo,
    this.ipAddress,
    required this.lastActivityAt,
    required this.expiresAt,
    required this.isActive,
  });

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) {
    return ActiveSessionModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? json['organization_id'] as String? ?? '',
      deviceInfo: json['deviceInfo'] as String? ?? json['device_info'] as String? ?? 'Desconocido',
      ipAddress: json['ipAddress'] as String? ?? json['ip_address'] as String?,
      lastActivityAt: DateTime.parse(
        json['lastActivityAt'] as String? ?? json['last_activity_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        json['expiresAt'] as String? ?? json['expires_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  /// Whether the session had activity in the last 5 minutes
  bool get isRecentlyActive {
    return isActive && DateTime.now().difference(lastActivityAt).inMinutes < 5;
  }

  String get deviceDisplayName {
    final info = deviceInfo.toLowerCase();
    // Formato nuevo: "Baudex/Desktop (macOS; ...)" o "Baudex/Mobile (Android; ...)"
    if (info.contains('baudex/desktop')) {
      if (info.contains('macos')) return 'Computador macOS';
      if (info.contains('windows')) return 'Computador Windows';
      if (info.contains('linux')) return 'Computador Linux';
      return 'Computador';
    }
    if (info.contains('baudex/mobile')) {
      if (info.contains('android')) return 'Celular Android';
      if (info.contains('ios')) return 'iPhone/iPad';
      return 'Celular';
    }
    // Formato legacy: user-agent estándar
    if (info.contains('windows')) return 'Windows PC';
    if (info.contains('macintosh') || info.contains('mac os')) return 'macOS';
    if (info.contains('linux')) return 'Linux PC';
    if (info.contains('android')) return 'Android';
    if (info.contains('iphone')) return 'iPhone';
    if (info.contains('ipad')) return 'iPad';
    // Dart/3.x genérico (antes del fix de User-Agent)
    if (info.contains('dart')) return 'Escritorio';
    return 'Dispositivo';
  }

  IconData get deviceIcon {
    final info = deviceInfo.toLowerCase();
    // Formato nuevo
    if (info.contains('baudex/desktop')) {
      if (info.contains('macos')) return Icons.laptop_mac;
      if (info.contains('windows')) return Icons.desktop_windows;
      return Icons.computer;
    }
    if (info.contains('baudex/mobile')) {
      if (info.contains('android')) return Icons.phone_android;
      if (info.contains('ios')) return Icons.phone_iphone;
      return Icons.smartphone;
    }
    // Formato legacy
    if (info.contains('desktop')) return Icons.computer;
    if (info.contains('mobile')) return Icons.smartphone;
    if (info.contains('windows')) return Icons.desktop_windows;
    if (info.contains('macintosh') || info.contains('mac os') || info.contains('macos')) return Icons.laptop_mac;
    if (info.contains('linux')) return Icons.computer;
    if (info.contains('android')) return Icons.phone_android;
    if (info.contains('iphone') || info.contains('ipad') || info.contains('ios')) return Icons.phone_iphone;
    if (info.contains('dart')) return Icons.computer;
    return Icons.devices;
  }

  /// Extract OS version from user-agent string
  String? get osVersion {
    // Formato nuevo: "Baudex/Desktop (macOS; Version 14.6.1 ...)"
    final match = RegExp(r'\([^;]+;\s*(.+?)\)').firstMatch(deviceInfo);
    if (match != null) {
      final version = match.group(1)?.trim();
      if (version != null && version.isNotEmpty) {
        return version.length > 45 ? '${version.substring(0, 42)}...' : version;
      }
    }
    return null;
  }

  /// Subtitle combining OS version and IP
  String get deviceSubtitle {
    final parts = <String>[];
    final version = osVersion;
    if (version != null) {
      parts.add(version);
    }
    if (ipAddress != null && ipAddress!.isNotEmpty) {
      parts.add(ipAddress!);
    }
    if (parts.isEmpty) {
      return shortDeviceInfo;
    }
    return parts.join(' · ');
  }

  /// Activity status text - distinguishes active from idle sessions
  String get activityStatusText {
    if (!isActive) return 'Sesión expirada';
    final diff = DateTime.now().difference(lastActivityAt);
    if (diff.inMinutes < 5) return 'Activo ahora';
    if (diff.inMinutes < 60) return 'Inactivo · ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Inactivo · ${diff.inHours}h';
    if (diff.inDays < 7) return 'Inactivo · ${diff.inDays}d';
    return 'Inactivo · +7d';
  }

  /// Color representing activity status
  Color get activityStatusColor {
    if (!isActive) return const Color(0xFF9E9E9E);
    final diff = DateTime.now().difference(lastActivityAt);
    if (diff.inMinutes < 5) return const Color(0xFF4CAF50);
    if (diff.inHours < 1) return const Color(0xFFFFA726);
    return const Color(0xFF9E9E9E);
  }

  String get lastActivityDisplay {
    final diff = DateTime.now().difference(lastActivityAt);
    if (diff.inMinutes < 5) return 'Activo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return 'Hace más de una semana';
  }

  String get shortDeviceInfo {
    if (deviceInfo.length > 60) {
      return '${deviceInfo.substring(0, 57)}...';
    }
    return deviceInfo;
  }
}
