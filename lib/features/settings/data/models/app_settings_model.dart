// lib/features/settings/data/models/app_settings_model.dart
import 'package:isar/isar.dart';
import '../../domain/entities/app_settings.dart';

part 'app_settings_model.g.dart';

@collection
class AppSettingsModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String settingsId;
  @Enumerated(EnumType.name)
  late ThemeMode themeMode;
  @Enumerated(EnumType.name)
  late AppLanguage language;
  late bool enableNotifications;
  late bool enableSounds;
  late bool autoBackup;
  late int backupIntervalHours;
  late bool debugMode;
  late String companyName;
  late String companyAddress;
  late String companyPhone;
  late String companyEmail;
  late String companyTaxId;
  late DateTime createdAt;
  late DateTime updatedAt;

  AppSettingsModel();

  AppSettingsModel.fromEntity(AppSettings entity) {
    settingsId = entity.id;
    themeMode = entity.themeMode;
    language = entity.language;
    enableNotifications = entity.enableNotifications;
    enableSounds = entity.enableSounds;
    autoBackup = entity.autoBackup;
    backupIntervalHours = entity.backupIntervalHours;
    debugMode = entity.debugMode;
    companyName = entity.companyName;
    companyAddress = entity.companyAddress;
    companyPhone = entity.companyPhone;
    companyEmail = entity.companyEmail;
    companyTaxId = entity.companyTaxId;
    createdAt = entity.createdAt;
    updatedAt = entity.updatedAt;
  }

  AppSettings toEntity() {
    return AppSettings(
      id: settingsId,
      themeMode: themeMode,
      language: language,
      enableNotifications: enableNotifications,
      enableSounds: enableSounds,
      autoBackup: autoBackup,
      backupIntervalHours: backupIntervalHours,
      debugMode: debugMode,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      companyEmail: companyEmail,
      companyTaxId: companyTaxId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void updateFromEntity(AppSettings entity) {
    settingsId = entity.id;
    themeMode = entity.themeMode;
    language = entity.language;
    enableNotifications = entity.enableNotifications;
    enableSounds = entity.enableSounds;
    autoBackup = entity.autoBackup;
    backupIntervalHours = entity.backupIntervalHours;
    debugMode = entity.debugMode;
    companyName = entity.companyName;
    companyAddress = entity.companyAddress;
    companyPhone = entity.companyPhone;
    companyEmail = entity.companyEmail;
    companyTaxId = entity.companyTaxId;
    updatedAt = DateTime.now();
  }
}