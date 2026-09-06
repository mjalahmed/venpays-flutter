import 'package:flutter/material.dart';

import 'exceptions.dart';
import 'models/checkout_options.dart';
import 'models/payment_result.dart';
import 'models/payment_status.dart';
import 'return_url_matcher.dart';
import 'url_validation.dart';
import 'venpays_webview.dart';

/// Entry point for VenPays hosted card checkout.
class VenPaysCheckout {
  VenPaysCheckout._();

  /// Opens hosted VenPays card checkout and returns a [PaymentResult].
  ///
  /// [paymentUrl] must be the HTTPS hosted card URL from the merchant backend
  /// (`POST /v1/sdk/checkout/{track_id}/pay` with `method: card`).
  ///
  /// [successUrl] and [failureUrl] must be the merchant HTTPS return URLs
  /// configured for this payment (Profile URLs or initiate overrides).
  ///
  /// The returned [PaymentResult.status] is client-observed only. Confirm
  /// payment on the merchant backend before fulfilling the order.
  static Future<PaymentResult> start({
    required BuildContext context,
    required String paymentUrl,
    required String trackId,
    required String successUrl,
    required String failureUrl,
    Duration? timeout,
    String title = 'Payment',
  }) async {
    final options = CheckoutOptions(
      paymentUrl: paymentUrl,
      trackId: trackId,
      successUrl: successUrl,
      failureUrl: failureUrl,
      timeout: timeout,
      title: title,
    );
    return startWithOptions(context: context, options: options);
  }

  /// Opens checkout using a [CheckoutOptions] object.
  static Future<PaymentResult> startWithOptions({
    required BuildContext context,
    required CheckoutOptions options,
  }) async {
    final normalizedTrackId = requireTrackId(options.trackId);
    requireHttpsUrl(options.paymentUrl, fieldName: 'paymentUrl');
    requireHttpsUrl(options.successUrl, fieldName: 'successUrl');
    requireHttpsUrl(options.failureUrl, fieldName: 'failureUrl');

    if (!context.mounted) {
      return PaymentResult(
        trackId: normalizedTrackId,
        status: PaymentStatus.error,
        message: 'Checkout context is no longer mounted.',
      );
    }

    final matcher = ReturnUrlMatcher(
      successUrl: options.successUrl,
      failureUrl: options.failureUrl,
      expectedTrackId: normalizedTrackId,
    );

    final normalizedOptions = CheckoutOptions(
      paymentUrl: options.paymentUrl.trim(),
      trackId: normalizedTrackId,
      successUrl: options.successUrl.trim(),
      failureUrl: options.failureUrl.trim(),
      timeout: options.timeout,
      title: options.title,
    );

    try {
      final result = await Navigator.of(context).push<PaymentResult>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => VenPaysCheckoutPage(
            options: normalizedOptions,
            matcher: matcher,
          ),
        ),
      );

      return result ??
          PaymentResult(
            trackId: normalizedTrackId,
            status: PaymentStatus.cancelled,
            message: 'Checkout was dismissed.',
          );
    } on VenPaysException {
      rethrow;
    } catch (error) {
      return PaymentResult(
        trackId: normalizedTrackId,
        status: PaymentStatus.error,
        message: error.toString(),
      );
    }
  }
}
