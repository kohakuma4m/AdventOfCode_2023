import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day01/solution.dart';

void main() {
  late List<String> testLines1;
  late List<String> testLines2;
  late List<String> inputLines;

  setUpAll(() async {
    testLines1 = await readInputFile('01', 'test1');
    testLines2 = await readInputFile('01', 'test2');
    inputLines = await readInputFile('01', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines1).solvePart1();

      expect(result, equals(142));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(54159));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines2).solvePart2();

      expect(result, equals(281));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(53866));
    });

    for (var testData in [
      (line: '39eightwo', expectedResult: 32),
    ]) {
      test('should find right solution for "${testData.line}" line', () async {
        final result = await Solution([testData.line]).solvePart2();

        expect(result, equals(testData.expectedResult));
      });
    }
  });
}
