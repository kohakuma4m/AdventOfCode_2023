import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day17/solution.dart';

void main() {
  late List<String> testLines1;
  late List<String> testLines2;
  late List<String> inputLines;

  setUpAll(() async {
    testLines1 = await readInputFile('17', 'test1');
    testLines2 = await readInputFile('17', 'test2');
    inputLines = await readInputFile('17', 'input');
  });

  group('part 1', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines1).solvePart1();

      expect(result, equals(102));
    });

    test('should find right solution for second example input', () async {
      final result = await Solution(testLines2).solvePart1();

      expect(result, equals(59));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(902));
    });
  });

  group('part 2', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines1).solvePart2();

      expect(result, equals(94));
    });

    test('should find right solution for second example input', () async {
      final result = await Solution(testLines2).solvePart2();

      expect(result, equals(71));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(1073));
    });
  });
}
