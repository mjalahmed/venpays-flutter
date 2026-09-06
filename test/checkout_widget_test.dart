import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venpays_flutter/venpays.dart';

void main() {
  testWidgets('invalid payment URL is rejected before checkout opens', (tester) async {
    Object? caught;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  try {
                    await VenPaysCheckout.start(
                      context: context,
                      paymentUrl: 'not-https',
                      trackId: 'track-1',
                      successUrl: 'https://merchant.example/ok',
                      failureUrl: 'https://merchant.example/fail',
                    );
                  } catch (error) {
                    caught = error;
                  }
                },
                child: const Text('Pay'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Pay'));
    await tester.pump();
    expect(caught, isA<VenPaysValidationException>());
    expect(
      (caught! as VenPaysValidationException).code,
      'invalid_argument',
    );
  });

  testWidgets('empty track id is rejected', (tester) async {
    Object? caught;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  try {
                    await VenPaysCheckout.start(
                      context: context,
                      paymentUrl: 'https://merchant.venpays.com/pay',
                      trackId: ' ',
                      successUrl: 'https://merchant.example/ok',
                      failureUrl: 'https://merchant.example/fail',
                    );
                  } catch (error) {
                    caught = error;
                  }
                },
                child: const Text('Pay'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Pay'));
    await tester.pump();
    expect(caught, isA<VenPaysValidationException>());
  });
}
