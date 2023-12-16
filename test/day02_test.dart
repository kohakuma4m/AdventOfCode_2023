import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day02/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('02', 'test');
    inputLines = await readInputFile('02', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart1();

      expect(result, equals(8));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(2593));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart2();

      expect(result, equals(2286));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(54699));
    });
  });
}
