import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day07/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('07', 'test');
    inputLines = await readInputFile('07', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input using non regex version', () async {
      final result = await Solution(testLines, false).solvePart1();

      expect(result, equals(6440));
    });

    test('should find right solution for example input using regex version', () async {
      final result = await Solution(testLines, true).solvePart1();

      expect(result, equals(6440));
    });

    test('should find right solution for input using non regex version', () async {
      final result = await Solution(inputLines, false).solvePart1();

      expect(result, equals(248105065));
    });

    test('should find right solution for input using regex version', () async {
      final result = await Solution(inputLines, true).solvePart1();

      expect(result, equals(248105065));
    });
  });

  group('part 2', () {
    test('should find right solution for example input using non regex version', () async {
      final result = await Solution(testLines, false).solvePart2();

      expect(result, equals(5905));
    });

    test('should find right solution for example input using regex version', () async {
      final result = await Solution(testLines, true).solvePart2();

      expect(result, equals(5905));
    });

    test('should find right solution for input using non regex version', () async {
      final result = await Solution(inputLines, true).solvePart2();

      expect(result, equals(249515436));
    });

    test('should find right solution for input using regex version', () async {
      final result = await Solution(inputLines, true).solvePart2();

      expect(result, equals(249515436));
    });
  });
}
