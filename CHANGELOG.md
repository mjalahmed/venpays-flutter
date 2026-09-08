# Changelog

## 0.1.2

* On shopper cancel/close, call `POST /v1/sdk/checkout/{track_id}/cancel` so the Payment Engine transaction is marked `cancelled` (not left pending).
* Treat engine `cancelled` as a terminal poll status.
* Expand the pubspec package description to meet pub.dev validation (50–180 characters).

## 0.1.1

* Poll public `GET /v1/sdk/checkout/{track_id}/status` while checkout is open and auto-dismiss on success/failure.
* On close, re-check status so a finished payment is never reported as cancelled.
* Do not block the Payment Engine Mastercard `redirect_handler` hop (required for finalization).

## 0.1.0

* Initial VenPays Flutter SDK release for hosted card checkout.
* WebView-based payment flow with HTTPS return URL detection.
* Typed payment results and validation helpers.
* Example application demonstrating merchant-backend integration.
