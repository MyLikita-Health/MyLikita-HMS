/**
 * @mylikita/booking-widget
 *
 * Drop-in appointment booking for MyLikita hospital websites. Mounts a
 * self-contained booking form into any element; submissions go through the
 * MyLikita relay (POST /v1/bookings) and the widget polls the booking until
 * the hospital confirms, cancels, reschedules, no-shows or the request
 * expires (GET /v1/bookings/:ref).
 *
 * Usage:
 *
 *   <div id="booking"></div>
 *   <script src="mylikita-booking-widget.min.js"></script>
 *   <script>
 *     MyLikitaBookingWidget.createBookingWidget(document.getElementById('booking'), {
 *       relayUrl: 'https://api.mylikita.clinic',
 *       websiteKey: 'wk_...',       // public client id — not a secret
 *       facilityId: 'F1',
 *       providers: [{ external_id: 'dr-khalil', label: 'Dr. Khalil' }],
 *       theme: { primary: '#0d6efd' },
 *     });
 *   </script>
 *
 * See README.md for the full option reference and theming guide.
 */

export { createBookingWidget } from './widget.js';
export { createBooking, fetchStatus, pollStatus, newExternalRef, fetchProviders } from './client.js';
export { STATUS_COPY, statusCopy, TERMINAL_STATUSES } from './state.js';
export { DEFAULT_THEME, resolveTheme } from './theme.js';
