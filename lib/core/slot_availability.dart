import '../data/demo_data.dart';
import '../models.dart';
import 'clinic.dart';
import 'saturday_schedule.dart';

/// A specialist visit is booked per Saturday, not per time slot. A date is
/// bookable when the doctor is scheduled that day and the clinic day has not
/// already ended.
bool isDateBookable({
  required Doctor doctor,
  required DateTime date,
  DateTime? now,
}) {
  if (!doctorScheduledOn(doctor, date)) return false;
  final current = now ?? DateTime.now();
  final day = dateOnly(date);
  final today = dateOnly(current);
  if (day.isBefore(today)) return false;
  if (day == today && current.hour >= Clinic.closeHour) return false;
  return true;
}

/// True when a booked appointment already exists for the doctor on that date.
bool hasBookingOn({
  required List<Appointment> appointments,
  required String? doctorId,
  required DateTime date,
  String? excludingAppointmentId,
}) {
  final day = dateOnly(date);
  for (final appointment in appointments) {
    if (appointment.status != AppointmentStatus.booked) continue;
    if (appointment.id == excludingAppointmentId) continue;
    if (appointment.doctorId != doctorId) continue;
    if (dateOnly(appointment.date) == day) return true;
  }
  return false;
}
