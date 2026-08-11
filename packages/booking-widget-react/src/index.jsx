/**
 * @mylikita/booking-widget-react
 *
 * React component wrapper around @mylikita/booking-widget. Renders the same
 * self-contained booking form, submits through the MyLikita relay
 * (POST /v1/bookings) and polls the booking until the hospital confirms,
 * cancels, reschedules, no-shows or the request expires
 * (GET /v1/bookings/:ref).
 *
 * Usage:
 *
 *   import BookingWidget from '@mylikita/booking-widget-react';
 *
 *   <BookingWidget
 *     relayUrl="https://api.mylikita.com"
 *     websiteKey="wk_…"
 *     facilityId="F1"
 *     loadProviders
 *     onBooking={(b) => console.log('booked', b.booking_ref)}
 *   />
 *
 * All option props map 1:1 onto the vanilla widget options (see the vanilla
 * package README for the full reference). Callback props may change identity
 * freely — only the data options (relayUrl, websiteKey, facilityId, providers,
 * services, durationMins, pollIntervalMs, maxTries, showBrand, theme, text)
 * tear down and recreate the underlying widget.
 *
 * The component is SSR-safe: nothing touches the DOM until the browser effect
 * runs, so it renders an empty container on the server.
 */

import React, { forwardRef, useEffect, useImperativeHandle, useRef } from 'react';
import { createBookingWidget } from '@mylikita/booking-widget';

const BookingWidget = forwardRef(function BookingWidget(props, ref) {
  const {
    relayUrl,
    websiteKey,
    facilityId,
    providers,
    loadProviders,
    services,
    durationMins,
    pollIntervalMs,
    maxTries,
    showBrand,
    theme,
    text,
    externalRef,
    onBooking,
    onStatus,
    onError,
    className,
    style,
    ...rest
  } = props;

  const containerRef = useRef(null);
  const widgetRef = useRef(null);

  // Keep the latest callbacks in a ref so a re-render with a new callback
  // identity does NOT recreate the widget (only the data options do). Without
  // this, a parent passing an inline arrow each render would rebuild the whole
  // form on every keystroke.
  const cbRef = useRef({ onBooking, onStatus, onError, externalRef });
  cbRef.current = { onBooking, onStatus, onError, externalRef };

  // JSON-stable key of the data options. Providers/services/theme/text are
  // objects — comparing identity would recreate the widget on every parent
  // render even when nothing changed.
  const dataKey = JSON.stringify({
    relayUrl,
    websiteKey,
    facilityId,
    providers,
    loadProviders,
    services,
    durationMins,
    pollIntervalMs,
    maxTries,
    showBrand,
    theme,
    text,
  });

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    // Missing required props → render an empty container instead of throwing,
    // so parents can pass config asynchronously without crash loops.
    if (!relayUrl || !websiteKey || !facilityId) return;

    const widget = createBookingWidget(el, {
      relayUrl,
      websiteKey,
      facilityId,
      providers,
      loadProviders,
      services,
      durationMins,
      pollIntervalMs,
      maxTries,
      showBrand,
      theme,
      text,
      // externalRef is a function — routed through a ref like the callbacks so
      // an identity change is picked up without tearing down the widget.
      externalRef: cbRef.current.externalRef,
      onBooking: (...args) => cbRef.current.onBooking?.(...args),
      onStatus: (...args) => cbRef.current.onStatus?.(...args),
      onError: (...args) => cbRef.current.onError?.(...args),
    });
    widgetRef.current = widget;
    return () => {
      widget.destroy();
      widgetRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dataKey]);

  useImperativeHandle(ref, () => ({
    reset: () => widgetRef.current?.reset(),
    getForm: () => widgetRef.current?.getForm() ?? null,
    destroy: () => {
      widgetRef.current?.destroy();
      widgetRef.current = null;
    },
    getWidget: () => widgetRef.current,
  }), []);

  return (
    <div ref={containerRef} className={className} style={style} {...rest} />
  );
});

BookingWidget.displayName = 'BookingWidget';

export default BookingWidget;
export { BookingWidget };
export { createBookingWidget } from '@mylikita/booking-widget';
