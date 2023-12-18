import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day10/solution.dart';

void main() {
  late List<String> testLines1;
  late List<String> testLines2;
  late List<String> testLines3;
  late List<String> testLines4;
  late List<String> testLines5;
  late List<String> testLines6;
  late List<String> inputLines;

  setUpAll(() async {
    testLines1 = await readInputFile('10', 'test1');
    testLines2 = await readInputFile('10', 'test2');
    testLines3 = await readInputFile('10', 'test3');
    testLines4 = await readInputFile('10', 'test4');
    testLines5 = await readInputFile('10', 'test5');
    testLines6 = await readInputFile('10', 'test6');
    inputLines = await readInputFile('10', 'input');
  });

  group('part 1', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines1).solvePart1();

      expect(result, equals(4));
    });

    test('should find right solution for second example input', () async {
      final result = await Solution(testLines2).solvePart1();

      expect(result, equals(8));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(6968));
    });
  });

  group('part 2', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines3).solvePart2();

      expect(result, equals(4));
    });

    test('should find right solution for second example input', () async {
      final result = await Solution(testLines4).solvePart2();

      expect(result, equals(4));
    });

    test('should find right solution for third example input', () async {
      final result = await Solution(testLines5).solvePart2();

      expect(result, equals(8));
    });

    test('should find right solution for fourth example input', () async {
      final result = await Solution(testLines6).solvePart2();

      expect(result, equals(10));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(413));
    });
  });
}
