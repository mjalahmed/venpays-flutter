# VenPays Flutter example

Demonstrates hosted card checkout with `venpays_flutter`.

## Run

```bash
flutter pub get
flutter run
```

With a real merchant backend:

```bash
flutter run \
  --dart-define=MERCHANT_BACKEND_URL=https://your-backend.example \
  --dart-define=SUCCESS_URL=https://merchant.example/payment/success \
  --dart-define=FAILURE_URL=https://merchant.example/payment/failure
```

## Security

This app never embeds VenPays SECRET or LEGACY API keys. Create checkout sessions on your server.
