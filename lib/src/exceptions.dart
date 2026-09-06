/// Base type for VenPays Flutter SDK failures raised before checkout starts.
class VenPaysException implements Exception {
  /// Creates an exception with a stable [code] and [message].
  const VenPaysException(this.code, this.message);

  /// Machine-readable error code.
  final String code;

  /// Human-readable message.
  final String message;

  @override
  String toString() => 'VenPaysException($code): $message';
}

/// Thrown when checkout input fails validation.
class VenPaysValidationException extends VenPaysException {
  /// Creates a validation exception.
  const VenPaysValidationException(String message)
      : super('invalid_argument', message);
}
