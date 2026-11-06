// Resultado sellado para operaciones (Fase 3: esqueleto, sin lógica de negocio).

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message);
  final String message;
}
