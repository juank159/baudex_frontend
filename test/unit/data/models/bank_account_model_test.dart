import 'package:flutter_test/flutter_test.dart';
import 'package:baudex_desktop/features/bank_accounts/data/models/bank_account_model.dart';
import 'package:baudex_desktop/features/bank_accounts/domain/entities/bank_account.dart';

void main() {
  group('BankAccountModel', () {
    final tDateTime = DateTime(2024, 1, 1);

    final tBankAccountModel = BankAccountModel(
      id: 'bank-001',
      name: 'Test Bank Account',
      type: BankAccountType.cash,
      bankName: 'Test Bank',
      accountNumber: '1234567890',
      holderName: 'Test Holder',
      icon: 'bank',
      isActive: true,
      isDefault: false,
      sortOrder: 0,
      description: 'Test Description',
      organizationId: 'org-001',
      createdById: 'user-001',
      updatedById: 'user-001',
      createdAt: tDateTime,
      updatedAt: tDateTime,
    );

    final tJson = {
      'id': 'bank-001',
      'name': 'Test Bank Account',
      'type': 'cash',
      'bankName': 'Test Bank',
      'accountNumber': '1234567890',
      'holderName': 'Test Holder',
      'icon': 'bank',
      'isActive': true,
      'isDefault': false,
      'sortOrder': 0,
      'description': 'Test Description',
      'organizationId': 'org-001',
      'createdById': 'user-001',
      'updatedById': 'user-001',
      'createdAt': '2024-01-01T00:00:00.000',
      'updatedAt': '2024-01-01T00:00:00.000',
    };

    group('fromJson', () {
      test('should create model from complete JSON', () {
        final result = BankAccountModel.fromJson(tJson);

        expect(result.id, equals('bank-001'));
        expect(result.name, equals('Test Bank Account'));
        expect(result.type, equals(BankAccountType.cash));
        expect(result.bankName, equals('Test Bank'));
        expect(result.accountNumber, equals('1234567890'));
        expect(result.holderName, equals('Test Holder'));
        expect(result.isActive, equals(true));
        expect(result.isDefault, equals(false));
        expect(result.organizationId, equals('org-001'));
      });

      test('should handle minimal JSON with defaults', () {
        final minimalJson = {
          'id': 'bank-002',
          'name': 'Minimal Bank Account',
          'type': 'cash',
          'organizationId': 'org-001',
          'createdAt': '2024-01-01T00:00:00.000',
          'updatedAt': '2024-01-01T00:00:00.000',
        };

        final result = BankAccountModel.fromJson(minimalJson);

        expect(result.id, equals('bank-002'));
        expect(result.name, equals('Minimal Bank Account'));
        expect(result.isActive, equals(true));
        expect(result.isDefault, equals(false));
        expect(result.sortOrder, equals(0));
      });
    });

    group('toJson', () {
      test('should convert model to JSON', () {
        final result = tBankAccountModel.toJson();

        expect(result['id'], equals('bank-001'));
        expect(result['name'], equals('Test Bank Account'));
        expect(result['type'], equals('cash'));
        expect(result['bankName'], equals('Test Bank'));
        expect(result['accountNumber'], equals('1234567890'));
        expect(result['holderName'], equals('Test Holder'));
        expect(result['isActive'], equals(true));
        expect(result['isDefault'], equals(false));
        expect(result['sortOrder'], equals(0));
        expect(result['organizationId'], equals('org-001'));
      });
    });

    group('fromEntity', () {
      test('should create model from entity', () {
        final entity = BankAccount(
          id: 'bank-003',
          name: 'Entity Bank Account',
          type: BankAccountType.savings,
          isActive: true,
          isDefault: true,
          sortOrder: 1,
          organizationId: 'org-001',
          createdAt: tDateTime,
          updatedAt: tDateTime,
        );

        final result = BankAccountModel.fromEntity(entity);

        expect(result.id, equals('bank-003'));
        expect(result.name, equals('Entity Bank Account'));
        expect(result.type, equals(BankAccountType.savings));
        expect(result.isActive, equals(true));
        expect(result.isDefault, equals(true));
        expect(result.sortOrder, equals(1));
      });
    });
  });
}
