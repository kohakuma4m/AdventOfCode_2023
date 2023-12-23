import 'package:test/test.dart';

import 'package:app/file.dart';
import 'package:app/day12/solution.dart';

void main() {
  late List<String> testLines;
  late List<String> inputLines;

  setUpAll(() async {
    testLines = await readInputFile('12', 'test');
    inputLines = await readInputFile('12', 'input');
  });

  group('part 1', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart1();

      expect(result, equals(21));
    });

    for (var testData in [
      (line: '??.??#?.#??#?.? 3,1,3,1', expectedResult: 2), // # 1000
      (line: '???#????????????.??. 7,1', expectedResult: 34), // # 996
      (line: '??????#??? 3,3', expectedResult: 6), // # 995
      (line: '.?.?#???#??#?.#.? 1,2,2,1,1', expectedResult: 7), // 991
      (line: '?.?.????#?.??????? 1,1,3,6', expectedResult: 16), // # 986
      (line: '.?.?#.????????.? 1,4', expectedResult: 5), // # 469
      (line: '??????#.???#?.. 1,1,5', expectedResult: 5), // # 345
      (line: '#??????###??????.??? 1,2,10,3', expectedResult: 3), // # 52
      (line: '?????.???????????? 4,1,1,6', expectedResult: 20), // # 31
    ]) {
      test('should find right solution for "${testData.line}" line', () async {
        final result = await Solution([testData.line]).solvePart1();

        expect(result, equals(testData.expectedResult));
      });
    }

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart1();

      expect(result, equals(7622));
    });
  });

  group('part 2', () {
    test('should find right solution for example input', () async {
      final result = await Solution(testLines).solvePart2();

      expect(result, equals(525152));
    });

    test('should find right solution for input', () async {
      final result = await Solution(inputLines).solvePart2();

      expect(result, equals(4964259839627));
    });
  });
}
