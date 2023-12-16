import 'dart:math';

import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final cards = readCards(lines);
    printCards(cards);

    return cards.map((c) => c.points).sum;
  }

  Future<int> solvePart2() async {
    final cards = readCards(lines);
    final cardsMap = {for (final card in cards) card: 1};

    for (var i = 0; i < cards.length; i++) {
      final currentCard = cards[i];
      for (var j = 0; j < currentCard.matches.length; j++) {
        var k = i + j + 1;
        if (k < cards.length) {
          cardsMap.update(cards[k], (value) => value + cardsMap[currentCard]!);
        }
      }
    }

    print(cardsMap.entries.map((e) => [e.key.cardNumber, e.value]).toList().join('\n'));

    return cardsMap.values.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<Card> readCards(List<String> lines) {
    final List<Card> cards = [];

    for (final line in lines) {
      var [left, right] = line.split(':');
      final cardNumber = int.parse(left.replaceAll('Card ', ''));

      [left, right] = right.split('|');
      final winningNumbers = left.split(' ').where((n) => n.isNotEmpty).map((n) => int.parse(n)).toList();
      final numbers = right.split(' ').where((n) => n.isNotEmpty).map((n) => int.parse(n)).toList();

      cards.add(Card(cardNumber, winningNumbers, numbers));
    }

    return cards;
  }

  static void printCards(List<Card> cards) {
    final lines = cards.map((c) => c.toString());
    final separator = '-' * lines.first.length;

    print(separator);
    for (final line in lines) {
      print(line);
    }
    print(separator);
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

class Card {
  final int cardNumber;
  final List<int> winningNumbers;
  final List<int> numbers;
  late Set<int> matches = _calculateMatches();
  late int points = _calculatePoints();

  Card(this.cardNumber, this.winningNumbers, this.numbers);

  Set<int> _calculateMatches() {
    return winningNumbers.toSet().intersection(numbers.toSet());
  }

  int _calculatePoints() {
    return pow(2, matches.length - 1).toInt();
  }

  @override
  String toString() {
    final winningNumbersString = winningNumbers.map((n) => n.toString().padLeft(2)).join(', ');
    final numbersString = numbers.map((n) => n.toString().padLeft(2)).join(', ');
    return 'Card ${cardNumber.toString().padLeft(3)}: $winningNumbersString | $numbersString';
  }

  @override
  bool operator ==(Object other) {
    return other is Card && other.runtimeType == runtimeType && other.cardNumber == cardNumber;
  }

  @override
  int get hashCode => cardNumber.hashCode;
}
