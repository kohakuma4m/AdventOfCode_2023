import 'dart:io';

import 'package:args/args.dart';

import 'package:app/file.dart';
import 'package:app/day01/solution.dart' as day01;

void main(List<String> arguments) async {
  exitCode = 0; // Presume success

  final parser = ArgParser()
    ..addOption('day',
        abbr: 'd',
        mandatory: true,
        allowed:
            List<String>.generate(25, (i) => (i + 1).toString())) // [1, 25]
    ..addOption('part', abbr: 'p', allowed: ['1', '2'], defaultsTo: '');

  ArgResults argResults = parser.parse(arguments);
  final day = argResults['day'];
  final part = argResults['part'];
  final args = argResults.rest;

  if (int.tryParse(day) == null) {
    throw ArgParserException("Missing 'day' number value");
  }

  await solveDay(int.parse(day),
      part: int.tryParse(part), inputFilename: args.firstOrNull);
}

Future<void> solveDay(int day, {int? part, String? inputFilename}) async {
  // Reading input...
  final lines = await readInputFile(day, inputFilename ?? 'input');

  // Solving...
  final solution = day01.Solution(lines);

  if (part == null || part == 1) {
    final result = solution.solvePart1();
    stdout.writeln('Solution 1: $result');
  }

  if (part == null || part == 2) {
    final result = solution.solvePart2();
    stdout.writeln('Solution 2: $result');
  }

  stdout.writeln('Done !');
}
