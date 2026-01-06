// test/fixtures/settings_fixtures.dart
import 'package:baudex_desktop/features/settings/domain/entities/app_settings.dart';
import 'package:baudex_desktop/features/settings/domain/entities/invoice_settings.dart';
import 'package:baudex_desktop/features/settings/domain/entities/organization.dart';
import 'package:baudex_desktop/features/settings/domain/entities/printer_settings.dart';
import 'package:baudex_desktop/features/settings/domain/entities/user_preferences.dart';

/// Test fixtures for Settings module
class SettingsFixtures {
  // ============================================================================
  // ORGANIZATION FIXTURES
  // ============================================================================

  /// Creates a single organization entity with default test data
  static Organization createOrganizationEntity({
    String id = 'org-001',
    String name = 'Test Organization',
    String slug = 'test-organization',
    String? domain = 'test.com',
    String? logo = 'https://example.com/logo.png',
    Map<String, dynamic>? settings,
    SubscriptionPlan subscriptionPlan = SubscriptionPlan.trial,
    SubscriptionStatus subscriptionStatus = SubscriptionStatus.active,
    bool isActive = true,
    String currency = 'EUR',
    String locale = 'es',
    String timezone = 'Europe/Madrid',
    double? defaultProfitMarginPercentage = 20.0,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    bool? hasValidSubscription = true,
    bool? isTrialExpired = false,
    int? daysUntilExpiration = 30,
    bool? isActivePlan = true,
  }) {
    return Organization(
      id: id,
      name: name,
      slug: slug,
      domain: domain,
      logo: logo,
      settings: settings ?? {'key': 'value'},
      subscriptionPlan: subscriptionPlan,
      subscriptionStatus: subscriptionStatus,
      isActive: isActive,
      currency: currency,
      locale: locale,
      timezone: timezone,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      defaultProfitMarginPercentage: defaultProfitMarginPercentage,
      subscriptionStartDate: subscriptionStartDate ?? DateTime(2024, 1, 1),
      subscriptionEndDate: subscriptionEndDate ?? DateTime(2024, 12, 31),
      trialStartDate: trialStartDate ?? DateTime(2024, 1, 1),
      trialEndDate: trialEndDate ?? DateTime(2024, 2, 1),
      hasValidSubscription: hasValidSubscription,
      isTrialExpired: isTrialExpired,
      daysUntilExpiration: daysUntilExpiration,
      isActivePlan: isActivePlan,
    );
  }

  /// Creates organization with premium subscription
  static Organization createPremiumOrganization({
    String id = 'org-premium',
  }) {
    return createOrganizationEntity(
      id: id,
      name: 'Premium Organization',
      slug: 'premium-organization',
      subscriptionPlan: SubscriptionPlan.premium,
      subscriptionStatus: SubscriptionStatus.active,
      hasValidSubscription: true,
      isTrialExpired: false,
      daysUntilExpiration: 365,
    );
  }

  /// Creates organization with expired trial
  static Organization createExpiredTrialOrganization({
    String id = 'org-expired',
  }) {
    return createOrganizationEntity(
      id: id,
      name: 'Expired Trial Organization',
      slug: 'expired-trial',
      subscriptionPlan: SubscriptionPlan.trial,
      subscriptionStatus: SubscriptionStatus.expired,
      hasValidSubscription: false,
      isTrialExpired: true,
      daysUntilExpiration: 0,
      trialEndDate: DateTime(2024, 1, 1),
    );
  }

  /// Creates organization with suspended subscription
  static Organization createSuspendedOrganization({
    String id = 'org-suspended',
  }) {
    return createOrganizationEntity(
      id: id,
      name: 'Suspended Organization',
      slug: 'suspended-org',
      subscriptionStatus: SubscriptionStatus.suspended,
      isActive: false,
      hasValidSubscription: false,
    );
  }

  // ============================================================================
  // APP SETTINGS FIXTURES
  // ============================================================================

  /// Creates a single app settings entity with default test data
  static AppSettings createAppSettingsEntity({
    String id = 'settings-001',
    ThemeMode themeMode = ThemeMode.system,
    AppLanguage language = AppLanguage.spanish,
    bool enableNotifications = true,
    bool enableSounds = true,
    bool autoBackup = false,
    int backupIntervalHours = 24,
    bool debugMode = false,
    String companyName = 'Test Company',
    String companyAddress = '123 Test Street',
    String companyPhone = '+34 123 456 789',
    String companyEmail = 'test@company.com',
    String companyTaxId = 'B12345678',
  }) {
    return AppSettings(
      id: id,
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
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates app settings with dark mode
  static AppSettings createDarkModeSettings({
    String id = 'settings-dark',
  }) {
    return createAppSettingsEntity(
      id: id,
      themeMode: ThemeMode.dark,
    );
  }

  /// Creates app settings with auto backup enabled
  static AppSettings createAutoBackupSettings({
    String id = 'settings-backup',
  }) {
    return createAppSettingsEntity(
      id: id,
      autoBackup: true,
      backupIntervalHours: 12,
    );
  }

  // ============================================================================
  // INVOICE SETTINGS FIXTURES
  // ============================================================================

  /// Creates a single invoice settings entity with default test data
  static InvoiceSettings createInvoiceSettingsEntity({
    String id = 'invoice-settings-001',
    String invoicePrefix = 'FACT-',
    int initialInvoiceNumber = 1,
    InvoiceNumberFormat numberFormat = InvoiceNumberFormat.sequential,
    double defaultTaxPercentage = 19.0,
    CurrencyFormat currencyFormat = CurrencyFormat.cop,
    DateFormat dateFormat = DateFormat.ddMMyyyy,
    LanguageOption language = LanguageOption.spanish,
    String defaultTermsAndConditions = 'Standard terms and conditions',
    String defaultNotes = 'Thank you for your business',
    bool includeQrCode = true,
    bool includeCompanyLogo = true,
    bool autoCalculateTax = true,
    bool requireCustomerInfo = false,
    int paymentTermsDays = 30,
  }) {
    return InvoiceSettings(
      id: id,
      invoicePrefix: invoicePrefix,
      initialInvoiceNumber: initialInvoiceNumber,
      numberFormat: numberFormat,
      defaultTaxPercentage: defaultTaxPercentage,
      currencyFormat: currencyFormat,
      dateFormat: dateFormat,
      language: language,
      defaultTermsAndConditions: defaultTermsAndConditions,
      defaultNotes: defaultNotes,
      includeQrCode: includeQrCode,
      includeCompanyLogo: includeCompanyLogo,
      autoCalculateTax: autoCalculateTax,
      requireCustomerInfo: requireCustomerInfo,
      paymentTermsDays: paymentTermsDays,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates invoice settings with year-month format
  static InvoiceSettings createYearMonthInvoiceSettings({
    String id = 'invoice-settings-ym',
  }) {
    return createInvoiceSettingsEntity(
      id: id,
      numberFormat: InvoiceNumberFormat.yearMonth,
      invoicePrefix: 'INV-',
    );
  }

  /// Creates invoice settings with USD currency
  static InvoiceSettings createUSDInvoiceSettings({
    String id = 'invoice-settings-usd',
  }) {
    return createInvoiceSettingsEntity(
      id: id,
      currencyFormat: CurrencyFormat.usd,
    );
  }

  // ============================================================================
  // PRINTER SETTINGS FIXTURES
  // ============================================================================

  /// Creates a single printer settings entity with default test data
  static PrinterSettings createPrinterSettingsEntity({
    String id = 'printer-001',
    String name = 'Test Printer',
    PrinterConnectionType connectionType = PrinterConnectionType.network,
    String? ipAddress = '192.168.1.100',
    int? port = 9100,
    String? usbPath,
    PaperSize paperSize = PaperSize.mm80,
    bool autoCut = true,
    bool cashDrawer = false,
    bool isDefault = false,
    bool isActive = true,
  }) {
    return PrinterSettings(
      id: id,
      name: name,
      connectionType: connectionType,
      ipAddress: ipAddress,
      port: port,
      usbPath: usbPath,
      paperSize: paperSize,
      autoCut: autoCut,
      cashDrawer: cashDrawer,
      isDefault: isDefault,
      isActive: isActive,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates a network printer
  static PrinterSettings createNetworkPrinter({
    String id = 'printer-network',
    String ipAddress = '192.168.1.100',
    bool isDefault = false,
  }) {
    return createPrinterSettingsEntity(
      id: id,
      name: 'Network Printer',
      connectionType: PrinterConnectionType.network,
      ipAddress: ipAddress,
      port: 9100,
      isDefault: isDefault,
    );
  }

  /// Creates a USB printer
  static PrinterSettings createUSBPrinter({
    String id = 'printer-usb',
    String usbPath = '/dev/usb/lp0',
    bool isDefault = false,
  }) {
    return createPrinterSettingsEntity(
      id: id,
      name: 'USB Printer',
      connectionType: PrinterConnectionType.usb,
      ipAddress: null,
      port: null,
      usbPath: usbPath,
      isDefault: isDefault,
    );
  }

  /// Creates a default printer
  static PrinterSettings createDefaultPrinter({
    String id = 'printer-default',
  }) {
    return createNetworkPrinter(
      id: id,
      isDefault: true,
    );
  }

  /// Creates a list of printer settings
  static List<PrinterSettings> createPrinterSettingsList(int count) {
    return List.generate(count, (index) {
      return createPrinterSettingsEntity(
        id: 'printer-${(index + 1).toString().padLeft(3, '0')}',
        name: 'Printer ${index + 1}',
        ipAddress: '192.168.1.${100 + index}',
        isDefault: index == 0,
      );
    });
  }

  // ============================================================================
  // USER PREFERENCES FIXTURES
  // ============================================================================

  /// Creates a single user preferences entity with default test data
  static UserPreferences createUserPreferencesEntity({
    String id = 'pref-001',
    String userId = 'user-001',
    String organizationId = 'org-001',
    bool autoDeductInventory = true,
    bool useFifoCosting = true,
    bool validateStockBeforeInvoice = true,
    bool allowOverselling = false,
    bool showStockWarnings = true,
    bool showConfirmationDialogs = true,
    bool useCompactMode = false,
    bool enableExpiryNotifications = true,
    bool enableLowStockNotifications = true,
    String? defaultWarehouseId = 'warehouse-001',
    Map<String, dynamic>? additionalSettings,
  }) {
    return UserPreferences(
      id: id,
      userId: userId,
      organizationId: organizationId,
      autoDeductInventory: autoDeductInventory,
      useFifoCosting: useFifoCosting,
      validateStockBeforeInvoice: validateStockBeforeInvoice,
      allowOverselling: allowOverselling,
      showStockWarnings: showStockWarnings,
      showConfirmationDialogs: showConfirmationDialogs,
      useCompactMode: useCompactMode,
      enableExpiryNotifications: enableExpiryNotifications,
      enableLowStockNotifications: enableLowStockNotifications,
      defaultWarehouseId: defaultWarehouseId,
      additionalSettings: additionalSettings ?? {'custom': 'value'},
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  /// Creates user preferences with overselling allowed
  static UserPreferences createOversellingPreferences({
    String id = 'pref-overselling',
  }) {
    return createUserPreferencesEntity(
      id: id,
      allowOverselling: true,
      validateStockBeforeInvoice: false,
    );
  }

  /// Creates user preferences with compact mode
  static UserPreferences createCompactModePreferences({
    String id = 'pref-compact',
  }) {
    return createUserPreferencesEntity(
      id: id,
      useCompactMode: true,
      showConfirmationDialogs: false,
    );
  }
}
