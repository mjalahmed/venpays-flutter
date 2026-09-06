import 'package:flutter_test/flutter_test.dart';
import 'package:venpays_flutter/src/return_url_matcher.dart';
import 'package:venpays_flutter/src/url_validation.dart';
import 'package:venpays_flutter/venpays.dart';

void main() {
  group('PaymentResult', () {
    test('success helpers', () {
      const result = PaymentResult(
        trackId: 'trk-1',
        status: PaymentStatus.success,
      );
      expect(result.isSuccess, isTrue);
      expect(result.isFailed, isFalse);
      expect(result.isCancelled, isFalse);
      expect(result.isError, isFalse);
    });

    test('failure helpers', () {
      const result = PaymentResult(
        trackId: 'trk-1',
        status: PaymentStatus.failed,
        message: 'declined',
      );
      expect(result.isFailed, isTrue);
      expect(result.message, 'declined');
    });

    test('cancelled helpers', () {
      const result = PaymentResult(
        trackId: 'trk-1',
        status: PaymentStatus.cancelled,
      );
      expect(result.isCancelled, isTrue);
    });

    test('error helpers', () {
      const result = PaymentResult(
        trackId: 'trk-1',
        status: PaymentStatus.error,
        message: 'timeout',
      );
      expect(result.isError, isTrue);
      expect(result.message, 'timeout');
    });

    test('equality', () {
      const a = PaymentResult(trackId: 't', status: PaymentStatus.success);
      const b = PaymentResult(trackId: 't', status: PaymentStatus.success);
      const c = PaymentResult(trackId: 't', status: PaymentStatus.failed);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('URL validation', () {
    test('accepts https payment URL', () {
      final uri = requireHttpsUrl(
        'https://merchant.venpays.com/mastercard/payment?payment_id=abc',
        fieldName: 'paymentUrl',
      );
      expect(uri.host, 'merchant.venpays.com');
    });

    test('rejects empty track id', () {
      expect(
        () => requireTrackId('  '),
        throwsA(isA<VenPaysValidationException>()),
      );
    });

    test('rejects http URL', () {
      expect(
        () => requireHttpsUrl('http://example.com/ok', fieldName: 'successUrl'),
        throwsA(isA<VenPaysValidationException>()),
      );
    });

    test('rejects custom scheme', () {
      expect(
        () => requireHttpsUrl('myapp://pay/success', fieldName: 'successUrl'),
        throwsA(isA<VenPaysValidationException>()),
      );
    });

    test('rejects malformed URL', () {
      expect(
        () => requireHttpsUrl('not a url', fieldName: 'paymentUrl'),
        throwsA(isA<VenPaysValidationException>()),
      );
    });
  });

  group('ReturnUrlMatcher', () {
    late ReturnUrlMatcher matcher;

    setUp(() {
      matcher = ReturnUrlMatcher(
        successUrl: 'https://merchant.example/payment/success',
        failureUrl: 'https://merchant.example/payment/failure',
        expectedTrackId: 'track-123',
      );
    });

    test('detects success return URL with query params', () {
      final match = matcher.match(
        'https://merchant.example/payment/success?track_id=track-123&status=success',
      );
      expect(match, isNotNull);
      expect(match!.status, PaymentStatus.success);
      expect(match.trackId, 'track-123');
      expect(match.redirectStatus, 'success');
    });

    test('detects failure return URL', () {
      final match = matcher.match(
        'https://merchant.example/payment/failure?track_id=track-123&status=failed',
      );
      expect(match, isNotNull);
      expect(match!.status, PaymentStatus.failed);
      expect(match.redirectStatus, 'failed');
    });

    test('ignores unrelated navigation', () {
      expect(
        matcher.match('https://credimax.gateway.mastercard.com/checkout'),
        isNull,
      );
    });

    test('ignores wrong track id on success URL', () {
      expect(
        matcher.match(
          'https://merchant.example/payment/success?track_id=other&status=success',
        ),
        isNull,
      );
    });

    test('allows success URL without track_id query', () {
      final match = matcher.match('https://merchant.example/payment/success');
      expect(match, isNotNull);
      expect(match!.status, PaymentStatus.success);
      expect(match.trackId, 'track-123');
    });

    test('handles URL encoding', () {
      final match = matcher.match(
        'https://merchant.example/payment/success?track_id=track-123&status=success&order=a%20b',
      );
      expect(match, isNotNull);
      expect(match!.status, PaymentStatus.success);
    });

    test('rejects http navigation even if path matches', () {
      expect(matcher.match('http://merchant.example/payment/success'), isNull);
    });
  });
}
