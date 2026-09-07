/// Helpers for Payment Engine base URLs.
library;

/// Derives the Payment Engine origin from a hosted [paymentUrl].
///
/// Example:
/// `https://init-vpay.venlabs.link/mastercard/payment?payment_id=…`
/// → `https://init-vpay.venlabs.link`
Uri? engineOriginFromPaymentUrl(String paymentUrl) {
  final uri = Uri.tryParse(paymentUrl.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return null;
  }
  if (uri.scheme.toLowerCase() != 'https') {
    return null;
  }
  return Uri(
    scheme: uri.scheme.toLowerCase(),
    host: uri.host.toLowerCase(),
    port: uri.hasPort ? uri.port : null,
  );
}

/// True when [url] is the VenPays Mastercard browser return callback.
///
/// That hop must be allowed to load so the Payment Engine can finalize the
/// payment before redirecting to the merchant return URL.
bool isPaymentEngineMastercardCallback(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  final path = uri.path.toLowerCase();
  return path.contains('/mastercard/') && path.contains('redirect');
}
