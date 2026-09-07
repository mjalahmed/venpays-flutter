import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models/payment_status.dart';

/// Result of a public checkout status poll.
class CheckoutStatusSnapshot {
  /// Creates a status snapshot.
  const CheckoutStatusSnapshot({
    required this.trackId,
    required this.rawStatus,
    this.clientStatus,
  });

  /// Track id that was queried.
  final String trackId;

  /// Raw status string from the Payment Engine.
  final String rawStatus;

  /// Mapped client status when the payment is terminal; otherwise null.
  final PaymentStatus? clientStatus;

  /// Whether this snapshot represents a finished payment.
  bool get isTerminal => clientStatus != null;
}

/// Polls `GET /v1/sdk/checkout/{trackId}/status` (no API key).
class CheckoutStatusPoller {
  /// Creates a poller for [trackId] against [engineOrigin].
  CheckoutStatusPoller({
    required this.engineOrigin,
    required this.trackId,
    http.Client? client,
    this.interval = const Duration(milliseconds: 1500),
  }) : _client = client ?? http.Client();

  /// Payment Engine origin, e.g. `https://init-vpay.venlabs.link`.
  final Uri engineOrigin;

  /// Track id to poll.
  final String trackId;

  /// Poll interval.
  final Duration interval;

  final http.Client _client;
  Timer? _timer;
  var _stopped = false;

  /// Fetches status once.
  Future<CheckoutStatusSnapshot?> fetchOnce() async {
    final uri = engineOrigin.replace(
      path: '/v1/sdk/checkout/${Uri.encodeComponent(trackId)}/status',
    );
    try {
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }
      final raw = (body['status'] as String?)?.trim() ?? '';
      if (raw.isEmpty) {
        return null;
      }
      return CheckoutStatusSnapshot(
        trackId: (body['track_id'] as String?)?.trim().isNotEmpty == true
            ? body['track_id'] as String
            : trackId,
        rawStatus: raw,
        clientStatus: mapEngineStatus(raw),
      );
    } catch (_) {
      return null;
    }
  }

  /// Starts polling; invokes [onTerminal] once for a terminal status.
  void start({required void Function(CheckoutStatusSnapshot snapshot) onTerminal}) {
    if (_stopped) {
      return;
    }
    Future<void> tick() async {
      if (_stopped) {
        return;
      }
      final snapshot = await fetchOnce();
      if (_stopped || snapshot == null || !snapshot.isTerminal) {
        return;
      }
      stop();
      onTerminal(snapshot);
    }

    // Immediate check, then interval.
    unawaited(tick());
    _timer = Timer.periodic(interval, (_) => unawaited(tick()));
  }

  /// Stops polling and releases the HTTP client.
  void stop() {
    _stopped = true;
    _timer?.cancel();
    _timer = null;
    _client.close();
  }

  /// Maps PE status strings onto [PaymentStatus], or null if still in-flight.
  static PaymentStatus? mapEngineStatus(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'success':
      case 'successful':
      case 'captured':
      case 'paid':
        return PaymentStatus.success;
      case 'failed':
      case 'fail':
      case 'failure':
      case 'declined':
      case 'error':
        return PaymentStatus.failed;
      default:
        return null;
    }
  }
}
