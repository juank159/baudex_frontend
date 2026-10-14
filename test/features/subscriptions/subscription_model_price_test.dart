import 'package:baudex_desktop/features/subscriptions/data/models/subscription_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _base(dynamic price, dynamic progress) => {
      'id': 'sub-1',
      'organizationId': 'org-1',
      'plan': 'premium',
      'planDisplayName': 'Premium',
      'status': 'active',
      'type': 'paid',
      'startDate': '2026-04-22T00:00:00.000Z',
      'endDate': '2027-04-22T00:00:00.000Z',
      'isActive': true,
      'isExpired': false,
      'isTrial': false,
      'daysUntilExpiration': 191,
      'subscriptionProgress': progress,
      'remainingDays': 191,
      'maxUsers': 5,
      'autoRenew': false,
      'price': price,
    };

void main() {
  test('precio que el servidor envía como texto ("59.99", caso Mercaexpress)', () {
    final sub = SubscriptionModel.fromJson(_base('59.99', 0.47));
    expect(sub.price, 59.99);
  });

  test('precio como número y sin precio', () {
    expect(SubscriptionModel.fromJson(_base(59.99, 0.47)).price, 59.99);
    expect(SubscriptionModel.fromJson(_base(null, 0.47)).price, isNull);
  });

  test('progreso como texto o número', () {
    expect(SubscriptionModel.fromJson(_base(null, '0.47')).subscriptionProgress, 0.47);
    expect(SubscriptionModel.fromJson(_base(null, 1)).subscriptionProgress, 1.0);
  });
}
