// lib/features/settings/domain/entities/app_settings.dart
import 'package:equatable/equatable.dart';

enum ThemeMode { light, dark, system }

enum AppLanguage { spanish, english }

class AppSettings extends Equatable {
  final String id;
  final ThemeMode themeMode;
  final AppLanguage language;
  final bool enableNotifications;
  final bool enableSounds;
  final bool autoBackup;
  final int backupIntervalHours;
  final bool debugMode;
  final String companyName;
  final String companyAddress;
  final String companyPhone;
  final String companyEmail;
  final String companyTaxId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    this.themeMode = ThemeMode.system,
    this.language = AppLanguage.spanish,
    this.enableNotifications = true,
    this.enableSounds = true,
    this.autoBackup = false,
    this.backupIntervalHours = 24,
    this.debugMode = false,
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
    this.companyEmail = '',
    this.companyTaxId = '',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        themeMode,
        language,
        enableNotifications,
        enableSounds,
        autoBackup,
        backupIntervalHours,
        debugMode,
        companyName,
        companyAddress,
        companyPhone,
        companyEmail,
        companyTaxId,
        createdAt,
        updatedAt,
      ];

  AppSettings copyWith({
    String? id,
    ThemeMode? themeMode,
    AppLanguage? language,
    bool? enableNotifications,
    bool? enableSounds,
    bool? autoBackup,
    int? backupIntervalHours,
    bool? debugMode,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyEmail,
    String? companyTaxId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableSounds: enableSounds ?? this.enableSounds,
      autoBackup: autoBackup ?? this.autoBackup,
      backupIntervalHours: backupIntervalHours ?? this.backupIntervalHours,
      debugMode: debugMode ?? this.debugMode,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      companyTaxId: companyTaxId ?? this.companyTaxId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasCompanyInfo =>
      companyName.isNotEmpty &&
      companyAddress.isNotEmpty &&
      companyPhone.isNotEmpty &&
      companyEmail.isNotEmpty;

  String get languageCode {
    switch (language) {
      case AppLanguage.spanish:
        return 'es';
      case AppLanguage.english:
        return 'en';
    }
  }

  factory AppSettings.defaultSettings() {
    final now = DateTime.now();
    return AppSettings(
      id: 'default',
      createdAt: now,
      updatedAt: now,
    );
  }
}