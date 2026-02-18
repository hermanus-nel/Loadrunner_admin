// test/helpers/test_data.dart

import '../../lib/features/users/domain/entities/driver_entity.dart';
import '../../lib/features/payments/domain/entities/payment_entity.dart';

/// Test data factory for creating test entities
class TestData {
  TestData._();

  // ============================
  // Driver test data
  // ============================

  static DriverEntity createDriver({
    String? id,
    String firstName = 'John',
    String lastName = 'Doe',
    String? phone,
    DriverVerificationStatus status = DriverVerificationStatus.pending,
  }) {
    return DriverEntity(
      id: id ?? 'driver-${DateTime.now().millisecondsSinceEpoch}',
      visibleId: 'VID001',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phone ?? '+27821234567',
      email: '${firstName.toLowerCase()}@test.com',
      verificationStatus: status,
      isVerified: status == DriverVerificationStatus.approved,
      vehicleCount: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    );
  }

  static List<DriverEntity> createDriversList({int count = 5}) {
    return List.generate(count, (i) {
      final statuses = DriverVerificationStatus.values;
      return createDriver(
        id: 'driver-$i',
        firstName: 'Driver',
        lastName: 'Test$i',
        phone: '+2782000000$i',
        status: statuses[i % statuses.length],
      );
    });
  }

  static List<DriverEntity> createPendingDrivers({int count = 3}) {
    return List.generate(count, (i) => createDriver(
      id: 'pending-driver-$i',
      firstName: 'Pending',
      lastName: 'Driver$i',
      status: DriverVerificationStatus.pending,
    ));
  }

  // ============================
  // Payment test data
  // ============================

  static PaymentEntity createPayment({
    String? id,
    double amount = 1000.0,
    PaymentStatus status = PaymentStatus.success,
    String? transactionId,
  }) {
    return PaymentEntity(
      id: id ?? 'payment-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      status: status,
      paymentMethod: 'card',
      paymentChannel: 'paystack',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      paidAt: status == PaymentStatus.success ? DateTime.now() : null,
      transactionId: transactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      bidAmount: amount,
      shipperCommission: amount * 0.05,
      driverCommission: amount * 0.03,
      totalCommission: amount * 0.08,
      payer: const PaymentUserInfo(
        id: 'shipper-1',
        fullName: 'Test Shipper',
        phone: '+27821111111',
      ),
    );
  }

  static List<PaymentEntity> createPaymentsList({int count = 10}) {
    final statuses = [
      PaymentStatus.success,
      PaymentStatus.success,
      PaymentStatus.success,
      PaymentStatus.failed,
      PaymentStatus.pending,
    ];

    return List.generate(count, (i) => createPayment(
      id: 'payment-$i',
      amount: 500.0 + (i * 100),
      status: statuses[i % statuses.length],
      transactionId: 'TXN_$i',
    ));
  }
}
