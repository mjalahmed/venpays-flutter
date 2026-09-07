# Changelog

## 0.1.1

* Poll public `GET /v1/sdk/checkout/{track_id}/status` while checkout is open and auto-dismiss on success/failure.
* On close, re-check status so a finished payment is never reported as cancelled.
* Do not block the Payment Engine Mastercard `redirect_handler` hop (required for finalization).

## 0.1.0

* Initial VenPays Flutter SDK release for hosted card checkout.
* WebView-based payment flow with HTTPS return URL detection.
* Typed payment results and validation helpers.
* Example application demonstrating merchant-backend integration.
