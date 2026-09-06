import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'models/checkout_options.dart';
import 'models/payment_result.dart';
import 'models/payment_status.dart';
import 'return_url_matcher.dart';

/// Full-screen hosted checkout WebView.
class VenPaysCheckoutPage extends StatefulWidget {
  /// Creates the checkout page.
  const VenPaysCheckoutPage({
    super.key,
    required this.options,
    required this.matcher,
  });

  /// Checkout configuration.
  final CheckoutOptions options;

  /// Return URL matcher for this session.
  final ReturnUrlMatcher matcher;

  @override
  State<VenPaysCheckoutPage> createState() => _VenPaysCheckoutPageState();
}

class _VenPaysCheckoutPageState extends State<VenPaysCheckoutPage> {
  late final WebViewController _controller;
  Timer? _timeoutTimer;
  var _completed = false;
  var _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted || _completed) {
              return;
            }
            setState(() {
              _loading = true;
              _loadError = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted || _completed) {
              return;
            }
            setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (_completed) {
              return;
            }
            // Ignore sub-frame / non-main-frame noise when possible.
            if (error.isForMainFrame == false) {
              return;
            }
            _complete(
              PaymentResult(
                trackId: widget.options.trackId,
                status: PaymentStatus.error,
                message: error.description,
              ),
            );
          },
          onNavigationRequest: (request) {
            final match = widget.matcher.match(request.url);
            if (match != null) {
              _complete(
                PaymentResult(
                  trackId: widget.options.trackId,
                  status: match.status,
                  returnUrl: match.uri.toString(),
                  redirectStatus: match.redirectStatus,
                  message: match.status == PaymentStatus.success
                      ? 'Payment return URL reached.'
                      : 'Payment failure return URL reached.',
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null || _completed) {
              return;
            }
            final match = widget.matcher.match(url);
            if (match != null) {
              _complete(
                PaymentResult(
                  trackId: widget.options.trackId,
                  status: match.status,
                  returnUrl: match.uri.toString(),
                  redirectStatus: match.redirectStatus,
                  message: match.status == PaymentStatus.success
                      ? 'Payment return URL reached.'
                      : 'Payment failure return URL reached.',
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.options.paymentUrl));

    final timeout = widget.options.timeout;
    if (timeout != null) {
      _timeoutTimer = Timer(timeout, () {
        _complete(
          PaymentResult(
            trackId: widget.options.trackId,
            status: PaymentStatus.error,
            message: 'Checkout timed out.',
          ),
        );
      });
    }
  }

  void _complete(PaymentResult result) {
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(result);
  }

  void _cancel() {
    _complete(
      PaymentResult(
        trackId: widget.options.trackId,
        status: PaymentStatus.cancelled,
        message: 'Checkout was cancelled.',
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _completed) {
          return;
        }
        _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.options.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_loadError != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
