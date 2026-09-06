# Merchant backend integration (Flutter card checkout)

Your mobile app must never hold a VenPays SECRET or LEGACY API key.

## Required server steps

1. Authenticate your shopper in your own system.
2. Create a VenPays checkout session:

```http
POST /v1/sdk/checkout
X-API-KEY: <SECRET>
Content-Type: application/json

{ "amount": 12.5, "currency": "BHD" }
```

3. Start card payment:

```http
POST /v1/sdk/checkout/{track_id}/pay
Content-Type: application/json

{ "method": "card" }
```

4. Return to the Flutter app only:

```json
{
  "track_id": "…",
  "payment_url": "…",
  "amount": 12.5,
  "currency": "BHD"
}
```

5. After the app reports completion (or on webhook), confirm:

```http
POST /merchant/payment-status
X-API-KEY: <SECRET>

{ "track_id": "…" }
```

Fulfill only after authoritative success.

## Return URLs

Configure HTTPS Profile `successUrl` / `failUrl` (or supported per-payment overrides). Pass the same HTTPS URLs into `VenPaysCheckout.start` so the WebView can detect completion.

## Environments

- Sandbox credentials → sandbox Payment Engine URLs in `payment_url`
- Live credentials → live Payment Engine URLs in `payment_url`

The Flutter SDK does not select the environment.
