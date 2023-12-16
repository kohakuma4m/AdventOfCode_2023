import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day00/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('00', 'test');
    inputLines = await readInputFile('00', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart1();

      expect(result, equals(0));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(0));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart2();

      expect(result, equals(0));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(0));
    });
  });
}
