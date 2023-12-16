import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day08/solution.dart';

void main() {
  late List<String> testLines1;
  late List<String> testLines2;
  late List<String> testLines3;
  late List<String> inputLines;

  setUpAll(() async {
    testLines1 = await readInputFile('08', 'test1');
    testLines2 = await readInputFile('08', 'test2');
    testLines3 = await readInputFile('08', 'test3');
    inputLines = await readInputFile('08', 'input');
  });

  group('part 1', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines1).solvePart1();

      expect(result, equals(2));
    });

    test('should find right solution for second example input', () async {
      final result = await Solution(testLines2).solvePart1();

      expect(result, equals(6));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(18673));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines3).solvePart2();

      expect(result, equals(6));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(17972669116327));
    });
  });
}
