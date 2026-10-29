abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage operation failed']);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'Database operation failed']);
}
