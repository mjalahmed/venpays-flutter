import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:venpays_flutter/venpays_flutter.dart';

void main() {
  runApp(const VenPaysExampleApp());
}

class VenPaysExampleApp extends StatelessWidget {
  const VenPaysExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VenPays Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const CheckoutDemoPage(),
    );
  }
}

/// Demonstrates merchant-backend → VenPays hosted card checkout.
///
/// Configure [merchantBackendBaseUrl] to point at your backend. The example
/// never holds a VenPays SECRET or LEGACY API key.
class CheckoutDemoPage extends StatefulWidget {
  const CheckoutDemoPage({super.key});

  @override
  State<CheckoutDemoPage> createState() => _CheckoutDemoPageState();
}

class _CheckoutDemoPageState extends State<CheckoutDemoPage> {
  /// Base URL of the merchant backend that creates the VenPays checkout.
  ///
  /// Expected endpoints:
  /// - POST /create-payment  → { track_id, payment_url, amount, currency }
  ///
  /// Leave empty to use the local mock path in this example.
  static const merchantBackendBaseUrl = String.fromEnvironment(
    'MERCHANT_BACKEND_URL',
    defaultValue: '',
  );

  static const successReturnUrl = String.fromEnvironment(
    'SUCCESS_URL',
    defaultValue: 'https://example.com/payment/success',
  );

  static const failureReturnUrl = String.fromEnvironment(
    'FAILURE_URL',
    defaultValue: 'https://example.com/payment/failure',
  );

  final _amountController = TextEditingController(text: '1.000');
  String _currency = 'BHD';
  var _loading = false;
  String? _statusMessage;
  PaymentResult? _lastResult;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startCheckout() async {
    setState(() {
      _loading = true;
      _statusMessage = 'Creating payment with merchant backend…';
      _lastResult = null;
    });

    try {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) {
        throw const FormatException('Enter a valid amount greater than zero.');
      }

      final payment = await _createPayment(amount: amount, currency: _currency);

      if (!mounted) {
        return;
      }

      setState(() => _statusMessage = 'Opening VenPays hosted checkout…');

      final result = await VenPaysCheckout.start(
        context: context,
        paymentUrl: payment.paymentUrl,
        trackId: payment.trackId,
        successUrl: successReturnUrl,
        failureUrl: failureReturnUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastResult = result;
        _statusMessage = _describe(result);
      });
    } on VenPaysValidationException catch (error) {
      setState(() => _statusMessage = 'Validation error: ${error.message}');
    } catch (error) {
      setState(() => _statusMessage = 'Error: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<_BackendPayment> _createPayment({
    required double amount,
    required String currency,
  }) async {
    if (merchantBackendBaseUrl.trim().isEmpty) {
      // Local mock for UI development only. Replace with a real merchant
      // backend that calls VenPays with a SECRET key server-side.
      return _BackendPayment(
        trackId: 'demo-track-${DateTime.now().millisecondsSinceEpoch}',
        paymentUrl:
            'https://example.com/venpays-hosted-checkout-placeholder?amount=$amount&currency=$currency',
        amount: amount,
        currency: currency,
      );
    }

    final uri = Uri.parse(
      '${merchantBackendBaseUrl.replaceAll(RegExp(r'/+$'), '')}/create-payment',
    );
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'amount': amount, 'currency': currency}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Merchant backend returned HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return _BackendPayment(
      trackId: body['track_id'] as String,
      paymentUrl: body['payment_url'] as String,
      amount: (body['amount'] as num?)?.toDouble() ?? amount,
      currency: body['currency'] as String? ?? currency,
    );
  }

  String _describe(PaymentResult result) {
    switch (result.status) {
      case PaymentStatus.success:
        return 'Client observed success for ${result.trackId}. '
            'Confirm with your backend before fulfilling.';
      case PaymentStatus.failed:
        return 'Client observed failure for ${result.trackId}.';
      case PaymentStatus.cancelled:
        return 'Checkout cancelled for ${result.trackId}.';
      case PaymentStatus.error:
        return 'Checkout error for ${result.trackId}: ${result.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VenPays Card Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'This example calls a merchant backend for track_id + payment_url. '
            'VenPays SECRET keys never enter the Flutter app.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currency,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'BHD', child: Text('BHD')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                ],
                onChanged: _loading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _currency = value);
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loading ? null : _startCheckout,
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Pay with card'),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 20),
            Text(_statusMessage!),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: Text(_lastResult!.status.name.toUpperCase()),
                subtitle: Text(
                  'trackId: ${_lastResult!.trackId}\n'
                  'redirectStatus: ${_lastResult!.redirectStatus ?? '—'}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackendPayment {
  const _BackendPayment({
    required this.trackId,
    required this.paymentUrl,
    required this.amount,
    required this.currency,
  });

  final String trackId;
  final String paymentUrl;
  final double amount;
  final String currency;
}
