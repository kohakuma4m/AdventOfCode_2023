import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day01/solution.dart';

final dayString = '01';

void main() {
  group('part 1', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(dayString, 'test1');
      final result = Solution(lines).solvePart1();

      expect(result, equals(142));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(dayString, 'test2');
      final result = Solution(lines).solvePart2();

      expect(result, equals(281));
    });

    for (var testData in [
      (line: '39eightwo', expectedResult: 32),
    ]) {
      test('should find right solution for "${testData.line}" line', () async {
        final result = Solution([testData.line]).solvePart2();

        expect(result, equals(testData.expectedResult));
      });
    }
  });

  test('should find right input solutions for part 1 & 2', () async {
    final lines = await readInputFile(dayString, 'input');

    final solution = Solution(lines);

    final result1 = solution.solvePart1();
    expect(result1, equals(54159));

    final result2 = solution.solvePart2();
    expect(result2, equals(53866));
  });
}
