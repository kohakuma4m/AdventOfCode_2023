import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day11/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('11', 'test');
    inputLines = await readInputFile('11', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart1();

      expect(result, equals(374));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(10276166));
    });
  });

  group('part 2', () {
    for (var testData in [
      (spaceExpansionCoefficient: 10, expectedResult: 1030),
      (spaceExpansionCoefficient: 100, expectedResult: 8410),
    ]) {
      test('should find right solution for example input with a space expansion coefficient of ${testData.spaceExpansionCoefficient}', () async {
        final result = await Solution(testLines).solvePart2(spaceExpansionCoefficient: testData.spaceExpansionCoefficient);

        expect(result, equals(testData.expectedResult));
      });
    }

    test('should find right solution for input and space expansion coefficient of 1000000', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(598693078798));
    });
  });
}
