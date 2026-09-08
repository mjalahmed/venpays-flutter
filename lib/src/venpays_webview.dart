import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'checkout_status_poller.dart';
import 'engine_url.dart';
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
  CheckoutStatusPoller? _statusPoller;
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
          onPageStarted: (url) {
            if (!mounted || _completed) {
              return;
            }
            setState(() {
              _loading = true;
              _loadError = null;
            });
            _handlePossibleReturnUrl(url);
          },
          onPageFinished: (url) {
            if (!mounted || _completed) {
              return;
            }
            setState(() => _loading = false);
            _handlePossibleReturnUrl(url);
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
              // Never block the PE Mastercard callback hop — the engine must
              // run that request to finalize status / webhooks.
              if (isPaymentEngineMastercardCallback(request.url)) {
                return NavigationDecision.navigate;
              }
              _completeFromMatch(match);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url == null || _completed) {
              return;
            }
            _handlePossibleReturnUrl(url);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.options.paymentUrl));

    _startStatusPolling();

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

  void _startStatusPolling() {
    final origin = engineOriginFromPaymentUrl(widget.options.paymentUrl);
    if (origin == null) {
      return;
    }
    final poller = CheckoutStatusPoller(
      engineOrigin: origin,
      trackId: widget.options.trackId,
    );
    _statusPoller = poller;
    poller.start(
      onTerminal: (snapshot) {
        final status = snapshot.clientStatus;
        if (status == null || _completed) {
          return;
        }
        _complete(
          PaymentResult(
            trackId: widget.options.trackId,
            status: status,
            redirectStatus: snapshot.rawStatus,
            message: status == PaymentStatus.success
                ? 'Payment completed.'
                : status == PaymentStatus.cancelled
                    ? 'Checkout was cancelled.'
                    : 'Payment failed.',
          ),
        );
      },
    );
  }

  void _handlePossibleReturnUrl(String url) {
    final match = widget.matcher.match(url);
    if (match == null) {
      return;
    }
    // For PE callback URLs, let navigation proceed; polling will complete.
    if (isPaymentEngineMastercardCallback(url)) {
      return;
    }
    _completeFromMatch(match);
  }

  void _completeFromMatch(ReturnUrlMatch match) {
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

  void _complete(PaymentResult result) {
    if (_completed || !mounted) {
      return;
    }
    _completed = true;
    _timeoutTimer?.cancel();
    _statusPoller?.stop();
    _statusPoller = null;
    Navigator.of(context).pop(result);
  }

  Future<void> _onUserClose() async {
    if (_completed) {
      return;
    }
    // Independent probe so we still detect success if the sheet is closed
    // right after VenPays finalizes payment.
    final origin = engineOriginFromPaymentUrl(widget.options.paymentUrl);
    PaymentStatus? terminal;
    String? rawStatus;
    if (origin != null) {
      final probe = CheckoutStatusPoller(
        engineOrigin: origin,
        trackId: widget.options.trackId,
      );
      final snapshot = await probe.fetchOnce();
      terminal = snapshot?.clientStatus;
      rawStatus = snapshot?.rawStatus;
      if (terminal == null) {
        // Persist abandonment on the Payment Engine transaction.
        final cancelled = await probe.cancelOnce();
        terminal = cancelled?.clientStatus;
        rawStatus = cancelled?.rawStatus ?? rawStatus;
      }
      probe.stop();
    }
    if (terminal == PaymentStatus.success || terminal == PaymentStatus.failed) {
      _complete(
        PaymentResult(
          trackId: widget.options.trackId,
          status: terminal!,
          redirectStatus: rawStatus,
          message: terminal == PaymentStatus.success
              ? 'Payment completed.'
              : 'Payment failed.',
        ),
      );
      return;
    }
    _complete(
      PaymentResult(
        trackId: widget.options.trackId,
        status: PaymentStatus.cancelled,
        redirectStatus: rawStatus,
        message: 'Checkout was cancelled.',
      ),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _statusPoller?.stop();
    _statusPoller = null;
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
        unawaited(_onUserClose());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.options.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => unawaited(_onUserClose()),
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
