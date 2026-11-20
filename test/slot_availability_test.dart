import 'package:battar_sanjibani/core/clinic.dart';
import 'package:battar_sanjibani/core/slot_availability.dart';
import 'package:battar_sanjibani/data/catalog.dart';
import 'package:battar_sanjibani/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Nov 2026: 21 Nov is the third Saturday — Dr. Rajan's only clinic day.
  final rajan = doctorById('rajan')!;
  final thirdSat = DateTime(2026, 11, 21);
  final secondSat = DateTime(2026, 11, 14);

  Appointment appointment({
    required String id,
    required String? doctorId,
    required DateTime date,
    AppointmentStatus status = AppointmentStatus.booked,
  }) {
    return Appointment(
      id: id,
      departmentId: 'ortho',
      departmentName: 'Orthopaedics',
      doctorId: doctorId,
      doctorName: 'Dr. Rajan',
      date: date,
      slot: '10:00',
      patientName: 'क',
      phone: '9800000000',
      fee: 800,
      status: status,
      createdAt: DateTime(2026, 11, 1),
    );
  }

  group('isDateBookable', () {
    test('a specialist is bookable on their own Saturday', () {
      expect(
        isDateBookable(doctor: rajan, date: thirdSat, now: DateTime(2026, 11, 1)),
        isTrue,
      );
    });

    test('another Saturday in the same month is not their day', () {
      expect(
        isDateBookable(
          doctor: rajan,
          date: secondSat,
          now: DateTime(2026, 11, 1),
        ),
        isFalse,
      );
    });

    test('a date that has already passed is not bookable', () {
      expect(
        isDateBookable(doctor: rajan, date: thirdSat, now: DateTime(2026, 11, 30)),
        isFalse,
      );
    });

    test('same-day booking stops when the clinic closes', () {
      expect(Clinic.closeHour, 20);
      expect(
        isDateBookable(
          doctor: rajan,
          date: thirdSat,
          now: DateTime(2026, 11, 21, 19, 59),
        ),
        isTrue,
      );
      expect(
        isDateBookable(doctor: rajan, date: thirdSat, now: DateTime(2026, 11, 21, 20)),
        isFalse,
      );
    });

    test('a time on the requested date is ignored', () {
      expect(
        isDateBookable(
          doctor: rajan,
          date: DateTime(2026, 11, 21, 18),
          now: DateTime(2026, 11, 1),
        ),
        isTrue,
      );
    });
  });

  group('hasBookingOn', () {
    test('an empty schedule has nothing booked', () {
      expect(
        hasBookingOn(appointments: [], doctorId: 'rajan', date: thirdSat),
        isFalse,
      );
    });

    test('finds a booked visit for the same doctor on the same date', () {
      final list = [appointment(id: 'a', doctorId: 'rajan', date: thirdSat)];
      expect(
        hasBookingOn(appointments: list, doctorId: 'rajan', date: thirdSat),
        isTrue,
      );
    });

    test('another doctor on that date does not count', () {
      final list = [appointment(id: 'a', doctorId: 'suman', date: thirdSat)];
      expect(
        hasBookingOn(appointments: list, doctorId: 'rajan', date: thirdSat),
        isFalse,
      );
    });

    test('the same doctor on another date does not count', () {
      final list = [appointment(id: 'a', doctorId: 'rajan', date: secondSat)];
      expect(
        hasBookingOn(appointments: list, doctorId: 'rajan', date: thirdSat),
        isFalse,
      );
    });

    test('only a booked status holds the slot', () {
      for (final status in [
        AppointmentStatus.cancelled,
        AppointmentStatus.completed,
      ]) {
        final list = [
          appointment(
            id: 'a',
            doctorId: 'rajan',
            date: thirdSat,
            status: status,
          ),
        ];
        expect(
          hasBookingOn(appointments: list, doctorId: 'rajan', date: thirdSat),
          isFalse,
          reason: '$status should leave the date open',
        );
      }
    });

    test('a time on the stored appointment still matches', () {
      final list = [
        appointment(id: 'a', doctorId: 'rajan', date: DateTime(2026, 11, 21, 22, 15)),
      ];
      expect(
        hasBookingOn(appointments: list, doctorId: 'rajan', date: thirdSat),
        isTrue,
      );
    });

    test('excludingAppointmentId ignores the patient\'s own booking', () {
      final list = [appointment(id: 'a', doctorId: 'rajan', date: thirdSat)];
      expect(
        hasBookingOn(
          appointments: list,
          doctorId: 'rajan',
          date: thirdSat,
          excludingAppointmentId: 'a',
        ),
        isFalse,
      );
    });
  });
}
