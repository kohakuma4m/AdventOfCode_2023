import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day20/solution.dart';

void main() {
  late List<String> testLines1;
  late List<String> testLines2;
  late List<String> inputLines;

  setUpAll(() async {
    testLines1 = await readInputFile('20', 'test1');
    testLines2 = await readInputFile('20', 'test2');
    inputLines = await readInputFile('20', 'input');
  });

  group('part 1', () {
    test('should find right solution for first example input', () async {
      final result = await Solution(testLines1).solvePart1();

      expect(result, equals(32000000));
    });
    test('should find right solution for second example input', () async {
      final result = await Solution(testLines2).solvePart1();

      expect(result, equals(11687500));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(841763884));
    });
  });

  group('part 2', () {
    final expectedErrorMessage = 'Part 2 can only be run on real input with "rx" output module';

    test('should throw an ArgumentError with right message for first example input', () async {
      expect(() => Solution(testLines1).solvePart2(), throwsA(predicate((e) => e is ArgumentError && e.message == expectedErrorMessage)));
    });

    test('should throw an ArgumentError with right message for second example input', () async {
      expect(() => Solution(testLines2).solvePart2(), throwsA(predicate((e) => e is ArgumentError && e.message == expectedErrorMessage)));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(246006621493687));
    });
  });
}
