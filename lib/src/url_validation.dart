import 'exceptions.dart';

/// Validates HTTPS absolute URLs used by the SDK.
Uri requireHttpsUrl(String value, {required String fieldName}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw VenPaysValidationException('$fieldName must not be empty.');
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw VenPaysValidationException(
      '$fieldName must be an absolute URL with a host.',
    );
  }
  if (uri.scheme.toLowerCase() != 'https') {
    throw VenPaysValidationException('$fieldName must use https.');
  }
  return uri;
}

/// Validates a non-empty track id.
String requireTrackId(String trackId) {
  final trimmed = trackId.trim();
  if (trimmed.isEmpty) {
    throw VenPaysValidationException('trackId must not be empty.');
  }
  return trimmed;
}
