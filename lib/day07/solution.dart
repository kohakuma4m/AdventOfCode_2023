import 'dart:collection';
import 'package:collection/collection.dart';

class Solution {
  List<String> lines;
  bool useRegexVersion;

  Solution(this.lines, [this.useRegexVersion = false]);

  int solvePart1() {
    return solve(false);
  }

  int solvePart2() {
    return solve(true);
  }

  int solve(bool jokerRule) {
    final data = readCamelCardsData(lines);
    final sortedData = SplayTreeMap<Hand, Bid>.from(data, (a, b) {
      return compareCamelCardHands(b, a, jokerRule: jokerRule, useRegexVersion: useRegexVersion); // Sorting in reverse so rank = index + 1
    });
    printCamelCardsData(sortedData, jokerRule: jokerRule, useRegexVersion: useRegexVersion);
    print('-------------------');

    return sortedData.keys.indexed.fold(0, (total, current) {
      final (rank, bid) = (current.$1 + 1, sortedData[current.$2]!);
      return total + rank * bid;
    });
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static Map<Hand, Bid> readCamelCardsData(List<String> lines) {
    final Map<Hand, Bid> map = {};

    for (final line in lines) {
      final [hand, bid] = line.split(' ');
      map.addAll({ hand: int.parse(bid) });
    }

    return map;
  }

  static void printCamelCardsData(Map<Hand, Bid> data, {bool jokerRule = false, bool useRegexVersion = false}) {
    for (final entry in data.entries) {
      final cardHandType = getCamelCardHandType(entry.key, jokerRule: jokerRule, useRegexVersion: useRegexVersion);
      print('${entry.key} (${cardHandType.name})--> ${entry.value}\$');
    }
  }

  static int compareCamelCardHands(Hand a, Hand b, {bool jokerRule = false, bool useRegexVersion = false}) {
    if (a == b) {
      return 0; // Equality
    }

    final handTypeIndexA = getCamelCardHandType(a, jokerRule: jokerRule, useRegexVersion: useRegexVersion).index;
    final handTypeIndexB = getCamelCardHandType(b, jokerRule: jokerRule, useRegexVersion: useRegexVersion).index;

    if (handTypeIndexA != handTypeIndexB) {
      // Sorting by hand types
      return handTypeIndexA - handTypeIndexB;
    }

    // Sorting by matching card from the left
    for (var i = 0; i < a.length; i++) {
      final cardIndexA = jokerRule ? camelCardRuleValuesWithJoker.indexOf(a[i]) : camelCardValues.indexOf(a[i]);
      final cardIndexB = jokerRule ? camelCardRuleValuesWithJoker.indexOf(b[i]) : camelCardValues.indexOf(b[i]);

      if (cardIndexA != cardIndexB) {
        // Sorting by card value
        return cardIndexA - cardIndexB;
      }
    }

    return 0; // Equality
  }

  static CamelCardHandType getCamelCardHandType(Hand hand, {bool jokerRule = false, bool useRegexVersion = false}) {
    return useRegexVersion ? getCamelCardHandTypeWithRegex(hand, jokerRule: jokerRule) : getCamelCardHandTypeWithoutRegex(hand, jokerRule : jokerRule);
  }
}

////////////////////////////////
/// Custom types and functions
////////////////////////////////

typedef Hand = String;
typedef Bid = int;

enum CamelCardHandType { fiveOfAKind, fourOfAKind, fullHouse, threeOfAKind, twoPair, onePair, highCard }
const camelCardValues = ['A', 'K', 'Q', 'J', 'T', '9', '8', '7', '6', '5', '4', '3', '2'];
const camelCardJoker = 'J';
const camelCardRuleValuesWithJoker = ['A', 'K', 'Q', 'T', '9', '8', '7', '6', '5', '4', '3', '2', camelCardJoker];

/// Poker hand regex (adapted from https://stackoverflow.com/questions/58845139/using-regex-to-calculate-poker-hands-part-1)
///
/// Notes:
///   1) Group can't be reference by name in ECMA Scripts because of no recursion implementation (referenced by order instead)
///   2) The two pair part had a missing ".*" in 2nd positive lookahead, preventing matching some valid two pairs (e.g: AKQAQ)
final camelCardHandRegex = RegExp([
  r'^(?=.{5}$)',
  r'.*?',
  r'(', // 1st capturing group
  r'(?<five_of_a_kind>.)(?:.*(?<k5_card>\2)){4}|', // 2nd and 3rd capturing groups
  r'(?<four_of_a_kind>.)(?:.*(?<k4_card>\4)){3}|', // 4th and 5th capturing groups
  r'(?<full_house>(?=.*(?<fh_card1>.)(?=(?:.*(\7)){2}))(?=.*(?<fh_card2>(?!(\7)).)(?=.*(\9))).+)|', // 6th to 11th capturing groups
  r'(?<three_of_a_kind>.)(?:.*(?<k3_card>\12)){2}|', // 12th and 13th capturing group
  r'(?<two_pair>(?=.*(?<tp_card1>.)(?=.*(\15)))(?=.*(?<tp_card2>(?!(\15)).)(?=.*(\17))).+)|', // 14th to 19th capturing groups
  r'(?<one_pair>.).*(?<op_card>\20)', // 20th and 21 capturing groups
  r')'
].join(''));

// Regex version
CamelCardHandType getCamelCardHandTypeWithRegex(Hand hand, {bool jokerRule = false}) {
  final match = camelCardHandRegex.allMatches(hand).firstOrNull;
  final nbJokers = jokerRule ? camelCardJoker.allMatches(hand).length : 0;

  if (match?.namedGroup('five_of_a_kind') != null) {
    // [5]
    return CamelCardHandType.fiveOfAKind;
  }

  if (match?.namedGroup('four_of_a_kind') != null) {
    // [4, 1]
    switch (nbJokers) {
      case 4:
      case 1: {
        return CamelCardHandType.fiveOfAKind;
      }
      case 0: {
        return CamelCardHandType.fourOfAKind;
      }
    }
  }

  if (match?.namedGroup('full_house') != null) {
    // [3, 2]
    switch (nbJokers) {
      case 3:
      case 2: {
        return CamelCardHandType.fiveOfAKind;
      }
      case 0: {
        return CamelCardHandType.fullHouse;
      }
    }
  }

  if (match?.namedGroup('three_of_a_kind') != null) {
    // [3, 1, 1]
    switch (nbJokers) {
      case 3:
      case 1: {
        return CamelCardHandType.fourOfAKind;
      }
      case 0: {
        return CamelCardHandType.threeOfAKind;
      }
    }
  }

  if (match?.namedGroup('two_pair') != null) {
    // [2, 2, 1]
    switch (nbJokers) {
      case 2: {
        return CamelCardHandType.fourOfAKind;
      }
      case 1: {
        return CamelCardHandType.fullHouse;
      }
      case 0: {
        return CamelCardHandType.twoPair;
      }
    }
  }

  if (match?.namedGroup('one_pair') != null) {
    // [2, 1, 1, 1]
    switch (nbJokers) {
      case 2:
      case 1: {
        return CamelCardHandType.threeOfAKind;
      }
      case 0: {
        return CamelCardHandType.onePair;
      }
    }
  }

  // [1, 1, 1, 1, 1]
  switch (nbJokers) {
    case 1: {
      return CamelCardHandType.onePair;
    }
    case 0: {
      return CamelCardHandType.highCard;
    }
    default: {
      throw 'Missing uncovered case ! $hand (#J = $nbJokers)';
    }
  }
}

// Non regex version with single switch for variety
CamelCardHandType getCamelCardHandTypeWithoutRegex(Hand hand, {bool jokerRule = false}) {
  final cardCounts = hand.split('').fold({}, (map, card) {
    map.update(card, (value) => value + 1, ifAbsent: () => 1);
    return map;
  });

  final nbJokers = jokerRule ? cardCounts.remove(camelCardJoker) ?? 0 : 0;
  final counts = cardCounts.values.sorted((a, b) => b - a); // Higher counts first

  switch ([nbJokers, ...counts]) {
    case [0, 5]:
    case [1, 4]:
    case [2, 3]:
    case [3, 2]:
    case [4, 1]:
    case [5]: {
      return CamelCardHandType.fiveOfAKind;
    }
    case [0, 4, 1]:
    case [1, 3, 1]:
    case [2, 2, 1]:
    case [3, 1, 1]: {
      return CamelCardHandType.fourOfAKind;
    }
    case [0, 3, 2]:
    case [1, 2, 2]: {
      return CamelCardHandType.fullHouse;
    }
    case [0, 3, 1, 1]:
    case [1, 2, 1, 1]:
    case [2, 1, 1, 1]: {
      return CamelCardHandType.threeOfAKind;
    }
    case [0, 2, 2, 1]: {
      return CamelCardHandType.twoPair;
    }
    case [0, 2, 1, 1, 1]:
    case [1, 1, 1, 1, 1]: {
      return CamelCardHandType.onePair;
    }
    case [0, 1, 1, 1, 1, 1]: {
      return CamelCardHandType.highCard;
    }
    default: {
      throw 'Missing uncovered case ! $hand (#J = $nbJokers)';
    }
  }
}
