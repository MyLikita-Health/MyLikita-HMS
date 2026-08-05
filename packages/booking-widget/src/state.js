/**
 * Patient-facing copy for each booking status, mirroring the "Patient-facing
 * hint" column of WEBSITE_BOOKING_API.md §3. `kind` drives the badge colour.
 */

export const STATUS_COPY = {
  pending_confirmation: {
    title: 'Request received',
    message: "We've received your booking request — we'll confirm shortly.",
    kind: 'info',
  },
  confirmed: {
    title: 'Appointment confirmed',
    message: 'Your appointment is confirmed. See you at the clinic!',
    kind: 'success',
  },
  cancelled: {
    title: 'Appointment cancelled',
    message: 'This appointment was cancelled. Please contact the clinic if this was unexpected.',
    kind: 'danger',
  },
  rescheduled: {
    title: 'Appointment rescheduled',
    message: 'This appointment was moved — the new time was sent to you.',
    kind: 'info',
  },
  no_show: {
    title: 'Missed appointment',
    message: 'This appointment was marked as missed.',
    kind: 'danger',
  },
  expired: {
    title: 'Request expired',
    message: 'This booking request expired — please call the clinic to book.',
    kind: 'danger',
  },
  // Widget-internal: the poll itself failed (network, rotated key, etc.).
  poll_error: {
    title: 'Something went wrong',
    message: 'We could not check your booking right now. Please try again shortly.',
    kind: 'danger',
  },
};

export function statusCopy(status) {
  return STATUS_COPY[status] || STATUS_COPY.pending_confirmation;
}

export const TERMINAL_STATUSES = ['confirmed', 'cancelled', 'rescheduled', 'no_show', 'expired'];
