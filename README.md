# VenPays Flutter SDK

Hosted **card checkout** for Flutter apps on Android and iOS.

The SDK opens the VenPays hosted Mastercard checkout page inside a WebView. It does **not** collect card details, store secrets, or talk to VenPays with merchant API keys.

## Installation

```yaml
dependencies:
  venpays_flutter: ^0.1.0
```

Then:

```bash
flutter pub get
```

## Basic usage

```dart
import 'package:venpays_flutter/venpays_flutter.dart';

final result = await VenPaysCheckout.start(
  context: context,
  paymentUrl: payment.paymentUrl, // from your backend
  trackId: payment.trackId,       // from your backend
  successUrl: 'https://merchant.example/payment/success',
  failureUrl: 'https://merchant.example/payment/failure',
);

switch (result.status) {
  case PaymentStatus.success:
    // Informational only — confirm on your backend before fulfillment.
    break;
  case PaymentStatus.failed:
    break;
  case PaymentStatus.cancelled:
    break;
  case PaymentStatus.error:
    break;
}
```

## Backend flow

Your **merchant backend** holds the VenPays SECRET/LEGACY key and creates the hosted card URL:

```text
Merchant backend
    │
    │  X-API-KEY: SECRET
    ▼
POST /v1/sdk/checkout
    { "amount": 12.5, "currency": "BHD" }
    │
    │  track_id
    ▼
POST /v1/sdk/checkout/{track_id}/pay
    { "method": "card" }
    │
    │  payment_url
    ▼
Your API responds to the Flutter app
    { track_id, payment_url, amount, currency }
    │
    ▼
Flutter VenPaysCheckout.start(...)
    │
    ▼
VenPays hosted card page → MPGS → PE redirect → your HTTPS return URL
```

### Authoritative confirmation

After checkout:

1. Prefer VenPays webhooks (`PAYMENT_SUCCESS` / `PAYMENT_FAILED`), and/or
2. Call `POST /merchant/payment-status` with your SECRET key and `track_id`.

Do **not** fulfill orders based only on the Flutter `PaymentResult` or the `status` query parameter on the return URL.

## Security

| Item | Where it belongs |
|------|------------------|
| SECRET / LEGACY `X-API-KEY` | Merchant backend only |
| MPGS / acquirer credentials | VenPays / backend only |
| `track_id` + `payment_url` | Safe to send to Flutter |
| Publishable key (`pk_…`) | Not required for this Flutter card flow |

The Flutter SDK never accepts or stores VenPays API keys.

## Return URLs

VenPays redirects shoppers to **HTTPS** merchant return URLs (Profile `successUrl` / `failUrl`, or per-payment overrides on flows that support them).

Custom schemes such as `myapp://…` are **not** supported by the Payment Engine return-URL validator.

Pass the same HTTPS success/failure URLs into `VenPaysCheckout.start` so the WebView can detect completion:

```dart
successUrl: 'https://merchant.example/payment/success',
failureUrl: 'https://merchant.example/payment/failure',
```

VenPays appends `track_id` and `status` query parameters on redirect. Those values are informational.

The SDK also polls `GET /v1/sdk/checkout/{track_id}/status` on the Payment Engine host from `paymentUrl`. When that status becomes `success`, `failed`, or `cancelled`, the checkout sheet dismisses automatically — even if the Profile return URL does not match what you passed in. Closing the sheet after a finished payment reports success/failure, not cancelled. Closing while still pending calls `POST /v1/sdk/checkout/{track_id}/cancel` so the transaction is marked cancelled on VenPays.

## Sandbox and live

Environment selection is performed by your merchant backend:

- **Sandbox** — backend uses sandbox VenPays credentials / sandbox Payment Engine.
- **Live** — backend uses live VenPays credentials / live Payment Engine.

The Flutter app only opens the `payment_url` returned by your backend. It does not choose sandbox vs live from an API key.

## Error handling

| `PaymentStatus` | Meaning |
|-----------------|---------|
| `success` | Success return URL detected in the WebView |
| `failed` | Failure return URL detected in the WebView |
| `cancelled` | Shopper closed checkout (transaction marked cancelled on VenPays) |
| `error` | Validation, WebView, timeout, or unexpected failure |

Invalid inputs (empty `trackId`, non-HTTPS URLs) throw `VenPaysValidationException` before checkout opens.

## WebView requirements

- Android and iOS support via `webview_flutter`
- JavaScript enabled for the hosted checkout page
- Network access to VenPays and the payment gateway
- Merchant HTTPS return URLs reachable inside the WebView

## Example app

See [`example/`](example/):

```bash
cd example
flutter run \
  --dart-define=MERCHANT_BACKEND_URL=https://your-backend.example \
  --dart-define=SUCCESS_URL=https://merchant.example/payment/success \
  --dart-define=FAILURE_URL=https://merchant.example/payment/failure
```

Without `MERCHANT_BACKEND_URL`, the example uses a local UI mock and does not charge a real card.

### Suggested merchant backend contract

`POST /create-payment`

```json
{ "amount": 1.0, "currency": "BHD" }
```

```json
{
  "track_id": "…",
  "payment_url": "https://…/mastercard/payment?payment_id=…",
  "amount": 1.0,
  "currency": "BHD"
}
```

Implement that endpoint by calling VenPays `POST /v1/sdk/checkout` then `POST /v1/sdk/checkout/{track_id}/pay` with your SECRET key.

## Troubleshooting

| Symptom | Check |
|---------|--------|
| Validation error “must use https” | Use HTTPS for `paymentUrl`, `successUrl`, and `failureUrl` |
| Checkout never completes | Return URLs passed to the SDK must match Profile (or override) URLs VenPays redirects to |
| Success in app but order not paid | Confirm with `POST /merchant/payment-status` / webhooks |
| Blank WebView | Device network, PE/gateway reachability, invalid `payment_url` |
| Cancelled immediately | Shopper closed the sheet, or the route was popped |

## Version

`0.1.2` — card checkout only.
