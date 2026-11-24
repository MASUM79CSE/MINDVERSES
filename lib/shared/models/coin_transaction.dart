import 'package:flutter/foundation.dart';

enum CoinTransactionType {
  earnLevelClear,
  earnLevel3Star,
  earnDailyChallenge,
  earnAchievement,
  earnRewardedAd,
  spendHint,
  spendCosmetic,
  openingBalance,
  balanceReconciliation,
}

/// Immutable record of a verified coin transaction.
@immutable
class CoinTransaction {
  final String transactionId;
  final DateTime timestamp;
  final CoinTransactionType type;
  final int amount; // Positive for earnings, negative for expenditures
  final int balanceAfter;
  final String referenceId;

  const CoinTransaction({
    required this.transactionId,
    required this.timestamp,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.referenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
    };
  }

  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      transactionId: json['transactionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: CoinTransactionType.values.byName(json['type'] as String),
      amount: json['amount'] as int,
      balanceAfter: json['balanceAfter'] as int,
      referenceId: json['referenceId'] as String,
    );
  }
}
