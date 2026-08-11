/*! @mylikita/booking-widget-react v0.1.1 | MIT */

// src/index.jsx
import React, { forwardRef, useEffect, useImperativeHandle, useRef } from "react";
import { createBookingWidget } from "@mylikita/booking-widget";
import { createBookingWidget as createBookingWidget2 } from "@mylikita/booking-widget";
var BookingWidget = forwardRef(function BookingWidget2(props, ref) {
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
  const cbRef = useRef({ onBooking, onStatus, onError, externalRef });
  cbRef.current = { onBooking, onStatus, onError, externalRef };
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
    text
  });
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
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
      onBooking: (...args) => {
        var _a, _b;
        return (_b = (_a = cbRef.current).onBooking) == null ? void 0 : _b.call(_a, ...args);
      },
      onStatus: (...args) => {
        var _a, _b;
        return (_b = (_a = cbRef.current).onStatus) == null ? void 0 : _b.call(_a, ...args);
      },
      onError: (...args) => {
        var _a, _b;
        return (_b = (_a = cbRef.current).onError) == null ? void 0 : _b.call(_a, ...args);
      }
    });
    widgetRef.current = widget;
    return () => {
      widget.destroy();
      widgetRef.current = null;
    };
  }, [dataKey]);
  useImperativeHandle(ref, () => ({
    reset: () => {
      var _a;
      return (_a = widgetRef.current) == null ? void 0 : _a.reset();
    },
    getForm: () => {
      var _a, _b;
      return (_b = (_a = widgetRef.current) == null ? void 0 : _a.getForm()) != null ? _b : null;
    },
    destroy: () => {
      var _a;
      (_a = widgetRef.current) == null ? void 0 : _a.destroy();
      widgetRef.current = null;
    },
    getWidget: () => widgetRef.current
  }), []);
  return /* @__PURE__ */ React.createElement("div", { ref: containerRef, className, style, ...rest });
});
BookingWidget.displayName = "BookingWidget";
var index_default = BookingWidget;
export {
  BookingWidget,
  createBookingWidget2 as createBookingWidget,
  index_default as default
};
