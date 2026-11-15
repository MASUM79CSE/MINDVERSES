/// Base exception thrown by game engines and puzzle validation.
class GameException implements Exception {
  final String message;
  final String? gameId;
  final int? levelNumber;

  const GameException(this.message, {this.gameId, this.levelNumber});

  @override
  String toString() {
    final context = [
      if (gameId != null) 'Game: $gameId',
      if (levelNumber != null) 'Level: $levelNumber',
    ].join(', ');
    return 'GameException: $message${context.isNotEmpty ? ' ($context)' : ''}';
  }
}

/// Thrown when a player attempts an illegal move according to the puzzle rules.
class InvalidMoveException extends GameException {
  const InvalidMoveException(super.message, {super.gameId, super.levelNumber});
}

/// Thrown when move limits or resource budgets are exceeded.
class BudgetExceededException extends GameException {
  const BudgetExceededException(super.message, {super.gameId, super.levelNumber});
}
