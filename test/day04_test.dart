import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day04/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('04', 'test');
    inputLines = await readInputFile('04', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart1();

      expect(result, equals(13));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(21105));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart2();

      expect(result, equals(30));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(5329815));
    });
  });
}
