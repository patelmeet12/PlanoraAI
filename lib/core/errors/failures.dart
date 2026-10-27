abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

class AiServiceFailure extends Failure {
  const AiServiceFailure(super.message, {super.code});
}

class DependencyCycleFailure extends Failure {
  const DependencyCycleFailure(super.message, {super.code});
}
