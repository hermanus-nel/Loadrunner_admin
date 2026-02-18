// test/features/users/driver_approval_test.dart

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/features/users/domain/entities/driver_entity.dart';
import '../../../lib/features/users/domain/repositories/drivers_repository.dart';
import '../../helpers/mock_drivers_repository.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockDriversRepository mockRepo;

  setUp(() {
    mockRepo = MockDriversRepository();
  });

  group('Driver Approval Flow', () {
    group('Fetch Drivers', () {
      test('should fetch all drivers', () async {
        mockRepo.seedDrivers(TestData.createDriversList(count: 5));

        final result = await mockRepo.fetchDrivers(const DriverFilter());

        expect(result.drivers.length, equals(5));
        expect(result.totalCount, equals(5));
      });

      test('should filter by pending status', () async {
        mockRepo.seedDrivers(TestData.createDriversList(count: 6));

        final result = await mockRepo.fetchDrivers(
          const DriverFilter(status: DriverVerificationStatus.pending),
        );

        for (final driver in result.drivers) {
          expect(driver.verificationStatus, equals(DriverVerificationStatus.pending));
        }
      });

      test('should search drivers by name', () async {
        mockRepo.seedDrivers([
          TestData.createDriver(id: '1', firstName: 'Alice', lastName: 'Smith'),
          TestData.createDriver(id: '2', firstName: 'Bob', lastName: 'Jones'),
          TestData.createDriver(id: '3', firstName: 'Charlie', lastName: 'Smith'),
        ]);

        final result = await mockRepo.fetchDrivers(
          const DriverFilter(searchQuery: 'Smith'),
        );

        expect(result.drivers.length, equals(2));
        expect(result.drivers.every((d) => d.lastName == 'Smith'), isTrue);
      });

      test('should paginate results', () async {
        mockRepo.seedDrivers(TestData.createDriversList(count: 25));

        final page1 = await mockRepo.fetchDrivers(
          const DriverFilter(limit: 10, offset: 0),
        );
        final page2 = await mockRepo.fetchDrivers(
          const DriverFilter(limit: 10, offset: 10),
        );

        expect(page1.drivers.length, equals(10));
        expect(page1.hasMore, isTrue);
        expect(page2.drivers.length, equals(10));
        expect(page2.hasMore, isTrue);
      });

      test('should handle empty results', () async {
        final result = await mockRepo.fetchDrivers(const DriverFilter());

        expect(result.drivers, isEmpty);
        expect(result.totalCount, equals(0));
        expect(result.hasMore, isFalse);
      });
    });

    group('Driver Status Counts', () {
      test('should return correct counts per status', () async {
        mockRepo.seedDrivers([
          TestData.createDriver(id: '1', status: DriverVerificationStatus.pending),
          TestData.createDriver(id: '2', status: DriverVerificationStatus.pending),
          TestData.createDriver(id: '3', status: DriverVerificationStatus.approved),
          TestData.createDriver(id: '4', status: DriverVerificationStatus.rejected),
        ]);

        final counts = await mockRepo.fetchDriverCounts();

        expect(counts.total, equals(4));
        expect(counts.pending, equals(2));
        expect(counts.approved, equals(1));
        expect(counts.rejected, equals(1));
      });
    });

    group('Approve Driver', () {
      test('should approve a pending driver', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 1));

        final success = await mockRepo.approveDriver('pending-driver-0', 'admin-1');

        expect(success, isTrue);

        final driver = await mockRepo.fetchDriverById('pending-driver-0');
        expect(driver, isNotNull);
        expect(driver!.verificationStatus, equals(DriverVerificationStatus.approved));
      });

      test('should return false for non-existent driver', () async {
        final success = await mockRepo.approveDriver('non-existent', 'admin-1');
        expect(success, isFalse);
      });

      test('should handle approval failure', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 1));
        mockRepo.shouldFail = true;

        final success = await mockRepo.approveDriver('pending-driver-0', 'admin-1');
        expect(success, isFalse);
      });
    });

    group('Reject Driver', () {
      test('should reject a pending driver with reason', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 1));

        final success = await mockRepo.rejectDriver(
          'pending-driver-0',
          'admin-1',
          'Incomplete documentation',
        );

        expect(success, isTrue);

        final driver = await mockRepo.fetchDriverById('pending-driver-0');
        expect(driver, isNotNull);
        expect(driver!.verificationStatus, equals(DriverVerificationStatus.rejected));
      });

      test('should return false for non-existent driver', () async {
        final success = await mockRepo.rejectDriver(
          'non-existent',
          'admin-1',
          'Reason',
        );
        expect(success, isFalse);
      });
    });

    group('Request Documents', () {
      test('should request additional documents', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 1));

        final success = await mockRepo.requestDocuments(
          'pending-driver-0',
          'admin-1',
          ['drivers_license', 'id_document'],
          'Please upload a clearer photo',
        );

        expect(success, isTrue);
      });
    });

    group('Fetch Driver By ID', () {
      test('should return driver by ID', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 3));

        final driver = await mockRepo.fetchDriverById('pending-driver-1');

        expect(driver, isNotNull);
        expect(driver!.id, equals('pending-driver-1'));
      });

      test('should return null for non-existent ID', () async {
        mockRepo.seedDrivers(TestData.createPendingDrivers(count: 1));

        final driver = await mockRepo.fetchDriverById('non-existent');
        expect(driver, isNull);
      });
    });

    group('Search Drivers', () {
      test('should search by phone number', () async {
        mockRepo.seedDrivers([
          TestData.createDriver(id: '1', phone: '+27821111111'),
          TestData.createDriver(id: '2', phone: '+27822222222'),
        ]);

        final results = await mockRepo.searchDrivers('+27821');
        expect(results.length, equals(1));
        expect(results.first.phoneNumber, equals('+27821111111'));
      });
    });

    group('Error Handling', () {
      test('should throw on fetch when shouldFail is set', () async {
        mockRepo.shouldFail = true;

        expect(
          () => mockRepo.fetchDrivers(const DriverFilter()),
          throwsException,
        );
      });

      test('should throw on fetchDriverCounts when shouldFail is set', () async {
        mockRepo.shouldFail = true;

        expect(
          () => mockRepo.fetchDriverCounts(),
          throwsException,
        );
      });
    });
  });
}
