import 'package:flutter_test/flutter_test.dart';
import 'package:venpays_flutter/src/checkout_status_poller.dart';
import 'package:venpays_flutter/venpays_flutter.dart';

void main() {
  group('CheckoutStatusPoller.mapEngineStatus', () {
    test('maps success variants', () {
      expect(
        CheckoutStatusPoller.mapEngineStatus('success'),
        PaymentStatus.success,
      );
    });

    test('maps failed variants', () {
      expect(
        CheckoutStatusPoller.mapEngineStatus('failed'),
        PaymentStatus.failed,
      );
      expect(
        CheckoutStatusPoller.mapEngineStatus('error'),
        PaymentStatus.failed,
      );
    });

    test('maps cancelled variants', () {
      expect(
        CheckoutStatusPoller.mapEngineStatus('cancelled'),
        PaymentStatus.cancelled,
      );
      expect(
        CheckoutStatusPoller.mapEngineStatus('canceled'),
        PaymentStatus.cancelled,
      );
    });

    test('pending is not terminal', () {
      expect(CheckoutStatusPoller.mapEngineStatus('pending'), isNull);
    });
  });
}
