import 'payment_status.dart';

/// Typed result returned when hosted checkout finishes.
class PaymentResult {
  /// Creates a payment result.
  const PaymentResult({
    required this.trackId,
    required this.status,
    this.message,
    this.returnUrl,
    this.redirectStatus,
  });

  /// VenPays track id for this payment.
  final String trackId;

  /// Client-observed outcome.
  ///
  /// Redirect and status query values are informational. Confirm fulfillment
  /// with the merchant backend (`POST /merchant/payment-status`) or webhooks.
  final PaymentStatus status;

  /// Optional human-readable detail.
  final String? message;

  /// Absolute URL that completed the flow, when applicable.
  final String? returnUrl;

  /// Optional `status` query value from the merchant return URL.
  final String? redirectStatus;

  /// Whether the client observed a successful return URL.
  bool get isSuccess => status == PaymentStatus.success;

  /// Whether the client observed a failed return URL.
  bool get isFailed => status == PaymentStatus.failed;

  /// Whether the shopper cancelled checkout.
  bool get isCancelled => status == PaymentStatus.cancelled;

  /// Whether the SDK reported an error.
  bool get isError => status == PaymentStatus.error;

  @override
  String toString() {
    return 'PaymentResult(trackId: $trackId, status: $status, '
        'message: $message, redirectStatus: $redirectStatus)';
  }

  @override
  bool operator ==(Object other) {
    return other is PaymentResult &&
        other.trackId == trackId &&
        other.status == status &&
        other.message == message &&
        other.returnUrl == returnUrl &&
        other.redirectStatus == redirectStatus;
  }

  @override
  int get hashCode => Object.hash(
        trackId,
        status,
        message,
        returnUrl,
        redirectStatus,
      );
}
