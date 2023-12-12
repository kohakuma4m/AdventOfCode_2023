import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day07/solution.dart';

final dayString = '07';

void main() {
  group('part 1', () {
    test('should find right solution for example input using non regex version', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines, false).solvePart1();

      expect(result, equals(6440));
    });

    test('should find right solution for example input using regex version', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines, true).solvePart1();

      expect(result, equals(6440));
    });
  });

  group('part 2', () {
    test('should find right solution for example input using non regex version', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines, false).solvePart2();

      expect(result, equals(5905));
    });

    test('should find right solution for example input using regex version', () async {
      final lines = await readInputFile(dayString, 'test');
      final result = Solution(lines, true).solvePart2();

      expect(result, equals(5905));
    });
  });

  test('should find right input solutions for part 1 & 2 using non regex version', () async {
    final lines = await readInputFile(dayString, 'input');

    final solution = Solution(lines);

    final result1 = solution.solvePart1();
    expect(result1, equals(248105065));

    final result2 = solution.solvePart2();
    expect(result2, equals(249515436));
  });

  test('should find right input solutions for part 1 & 2 using regex version', () async {
    final lines = await readInputFile(dayString, 'input');

    final solution = Solution(lines, true);

    final result1 = solution.solvePart1();
    expect(result1, equals(248105065));

    final result2 = solution.solvePart2();
    expect(result2, equals(249515436));
  });
}
