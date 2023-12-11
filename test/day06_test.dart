import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day06/solution.dart';

final dayString = '06';

void main() {
  group('part 1', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines).solvePart1();

      expect(result, equals(288));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines).solvePart2();

      expect(result, equals(71503));
    });
  });

  test('should find right input solutions for part 1 & 2', () async {
    final lines = await readInputFile(dayString, 'input');

    final solution = Solution(lines);

    final result1 = solution.solvePart1();
    expect(result1, equals(1660968));

    final result2 = solution.solvePart2();
    expect(result2, equals(26499773));
  });
}
