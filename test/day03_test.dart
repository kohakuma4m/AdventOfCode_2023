import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day03/solution.dart';

final day = 3;

void main() {
  group('part 1', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(day, 'test');
      final result = Solution(lines).solvePart1();

      expect(result, equals(4361));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final lines = await readInputFile(day, 'test');
      final result = Solution(lines).solvePart2();

      expect(result, equals(467835));
    });
  });    

  test('should find right input solutions for part 1 & 2', () async {
    final lines = await readInputFile(day, 'input');

    final solution = Solution(lines);

    final result1 = solution.solvePart1();
    expect(result1, equals(514969));

    final result2 = solution.solvePart2();
    expect(result2, equals(78915902));
  });
}
