/// Base failure representation for application domain errors.
abstract class AppFailure {
  final String message;
  final dynamic cause;

  const AppFailure(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Storage read/write failure.
class StorageFailure extends AppFailure {
  const StorageFailure(super.message, [super.cause]);
}

/// Checksum or data integrity failure.
class IntegrityFailure extends AppFailure {
  const IntegrityFailure(super.message, [super.cause]);
}

/// Economy or transaction failure.
class EconomyFailure extends AppFailure {
  const EconomyFailure(super.message, [super.cause]);
}

/// Network or remote service failure.
class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, [super.cause]);
}
