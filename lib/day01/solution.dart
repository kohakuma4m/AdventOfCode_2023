import 'package:collection/collection.dart';

class Solution {
  List<String> lines = [];

  Solution(this.lines);

  int solvePart1() {
    final List<int> values = lines.map((line) => getLineValue(line)).toList();

    return values.sum;
  }

  int solvePart2() {
    final List<int> values = lines
        .map((line) => replaceRelevantDigitWords(line))
        .map((line) => getLineValue(line))
        .toList();

    return values.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static final RegExp nonDigitCharacter = RegExp(r'[^0-9]+');

  static int getLineValue(String line) {
    final digits = line.replaceAll(nonDigitCharacter, '');
    final [firstDigit, lastDigit] =
        digits.isNotEmpty ? [digits[0], digits[digits.length - 1]] : [0, 0];

    return int.parse('$firstDigit$lastDigit');
  }

  static final List<String> digitWords = [
    'one',
    'two',
    'three',
    'four',
    'five',
    'six',
    'seven',
    'eight',
    'nine'
  ];
  static final RegExp firstDigitWord = RegExp(
      '^([^0-9]*?)(${digitWords.join('|')})(.*)\$'); // Only if no digits before
  static final RegExp lastDigitWord = RegExp(
      '^(.*)(${digitWords.join('|')})([^0-9]*?)\$'); // Only if no digits after

  static String replaceRelevantDigitWords(String line) {
    return line
        .replaceAllMapped(
            firstDigitWord,
            (match) =>
                '${match[1]}${digitWords.indexOf(match[2] as String) + 1}${match[3]}')
        .replaceAllMapped(
            lastDigitWord,
            (match) =>
                '${match[1]}${digitWords.indexOf(match[2] as String) + 1}${match[3]}');
  }
}
