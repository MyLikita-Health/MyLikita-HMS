/*! @mylikita/booking-widget-react v0.1.1 | MIT */
var __create = Object.create;
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __getProtoOf = Object.getPrototypeOf;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
  // If the importer is in node compatibility mode or this is not an ESM
  // file that has been converted to a CommonJS file using a Babel-
  // compatible transform (i.e. "__esModule" has not been set), then set
  // "default" to the CommonJS "module.exports" for node compatibility.
  isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
  mod
));
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.jsx
var index_exports = {};
__export(index_exports, {
  BookingWidget: () => BookingWidget,
  createBookingWidget: () => import_booking_widget2.createBookingWidget,
  default: () => index_default
});
module.exports = __toCommonJS(index_exports);
var import_react = __toESM(require("react"), 1);
var import_booking_widget = require("@mylikita/booking-widget");
var import_booking_widget2 = require("@mylikita/booking-widget");
var BookingWidget = (0, import_react.forwardRef)(function BookingWidget2(props, ref) {
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
  const containerRef = (0, import_react.useRef)(null);
  const widgetRef = (0, import_react.useRef)(null);
  const cbRef = (0, import_react.useRef)({ onBooking, onStatus, onError, externalRef });
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
    theme,
    text
  });
  (0, import_react.useEffect)(() => {
    const el = containerRef.current;
    if (!el) return;
    if (!relayUrl || !websiteKey || !facilityId) return;
    const widget = (0, import_booking_widget.createBookingWidget)(el, {
      relayUrl,
      websiteKey,
      facilityId,
      providers,
      loadProviders,
      services,
      durationMins,
      pollIntervalMs,
      maxTries,
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
  (0, import_react.useImperativeHandle)(ref, () => ({
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
  return /* @__PURE__ */ import_react.default.createElement("div", { ref: containerRef, className, style, ...rest });
});
BookingWidget.displayName = "BookingWidget";
var index_default = BookingWidget;
