import 'models/payment_status.dart';

/// Match result for a merchant return URL navigation.
class ReturnUrlMatch {
  /// Creates a return URL match.
  const ReturnUrlMatch({
    required this.status,
    required this.uri,
    this.redirectStatus,
    this.trackId,
  });

  /// Mapped client payment status.
  final PaymentStatus status;

  /// Matched navigation URI.
  final Uri uri;

  /// Optional `status` query parameter from the return URL.
  final String? redirectStatus;

  /// Optional `track_id` query parameter from the return URL.
  final String? trackId;
}

/// Parses and matches merchant HTTPS return URLs.
class ReturnUrlMatcher {
  /// Creates a matcher for [successUrl] and [failureUrl].
  ReturnUrlMatcher({
    required String successUrl,
    required String failureUrl,
    required this.expectedTrackId,
  })  : successBase = _normalizeBase(Uri.parse(successUrl.trim())),
        failureBase = _normalizeBase(Uri.parse(failureUrl.trim()));

  /// Expected track id for this checkout.
  final String expectedTrackId;

  /// Normalized success base (scheme/host/path, no query/fragment).
  final Uri successBase;

  /// Normalized failure base (scheme/host/path, no query/fragment).
  final Uri failureBase;

  /// Attempts to match [url] against configured return URLs.
  ///
  /// Returns `null` when the navigation is unrelated to payment completion.
  ReturnUrlMatch? match(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    final base = _normalizeBase(uri);
    final trackId = _queryValue(uri, 'track_id');
    final redirectStatus = _queryValue(uri, 'status');

    if (_basesEqual(base, successBase)) {
      if (trackId != null && trackId != expectedTrackId) {
        return null;
      }
      return ReturnUrlMatch(
        status: PaymentStatus.success,
        uri: uri,
        redirectStatus: redirectStatus,
        trackId: trackId ?? expectedTrackId,
      );
    }

    if (_basesEqual(base, failureBase)) {
      if (trackId != null && trackId != expectedTrackId) {
        return null;
      }
      return ReturnUrlMatch(
        status: PaymentStatus.failed,
        uri: uri,
        redirectStatus: redirectStatus,
        trackId: trackId ?? expectedTrackId,
      );
    }

    return null;
  }

  static Uri _normalizeBase(Uri uri) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    return Uri(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      port: uri.hasPort ? uri.port : null,
      path: path.endsWith('/') && path.length > 1
          ? path.substring(0, path.length - 1)
          : path,
    );
  }

  static bool _basesEqual(Uri a, Uri b) {
    return a.scheme == b.scheme &&
        a.host == b.host &&
        a.port == b.port &&
        a.path == b.path;
  }

  static String? _queryValue(Uri uri, String key) {
    final values = uri.queryParametersAll[key];
    if (values == null || values.isEmpty) {
      return null;
    }
    final value = values.first.trim();
    return value.isEmpty ? null : value;
  }
}
