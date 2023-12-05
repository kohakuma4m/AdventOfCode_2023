import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day00/solution.dart';

final day = 0;

void main() {
  group('part 1', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(day, 'test1');
      final result = Solution(lines).solvePart1();

      expect(result, equals(0));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(day, 'test2');
      final result = Solution(lines).solvePart2();

      expect(result, equals(0));
    });
  });    

  test('should find right input solutions for part 1 & 2', () async {
    final lines = await readInputFile(day, 'input');

    final solution = Solution(lines);

    final result1 = solution.solvePart1();
    expect(result1, equals(0));

    final result2 = solution.solvePart2();
    expect(result2, equals(0));
  });
}