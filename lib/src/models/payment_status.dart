/// Outcome of a hosted VenPays card checkout session.
enum PaymentStatus {
  /// Shopper completed payment successfully (client-observed).
  success,

  /// Shopper completed the flow with a failed payment (client-observed).
  failed,

  /// Shopper dismissed checkout before completion.
  cancelled,

  /// SDK or WebView error prevented a normal completion.
  error,
}
