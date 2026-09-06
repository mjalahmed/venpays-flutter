/// Options for starting hosted VenPays card checkout.
class CheckoutOptions {
  /// Creates checkout options.
  const CheckoutOptions({
    required this.paymentUrl,
    required this.trackId,
    required this.successUrl,
    required this.failureUrl,
    this.timeout,
    this.title = 'Payment',
  });

  /// Hosted VenPays card checkout URL from the merchant backend.
  final String paymentUrl;

  /// Track id associated with this payment.
  final String trackId;

  /// Merchant HTTPS success return URL (Profile or initiate override).
  final String successUrl;

  /// Merchant HTTPS failure return URL (Profile or initiate override).
  final String failureUrl;

  /// Optional max duration before the SDK returns [PaymentStatus.error].
  final Duration? timeout;

  /// AppBar title shown while checkout is open.
  final String title;
}
