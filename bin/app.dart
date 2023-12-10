import 'dart:io';
import 'dart:mirrors';

import 'package:args/args.dart';
import 'package:collection/collection.dart';

import 'package:app/file.dart';

// Importing solutions (TODO: import dynamically at runtime ???)
import 'package:app/day01/solution.dart' as day01; // ignore: unused_import
import 'package:app/day02/solution.dart' as day02; // ignore: unused_import
import 'package:app/day03/solution.dart' as day03; // ignore: unused_import
import 'package:app/day04/solution.dart' as day04; // ignore: unused_import
import 'package:app/day05/solution.dart' as day05; // ignore: unused_import

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
    throw ArgParserException('Missing "day" number value');
  }

  await solveDay(int.parse(day),
      part: int.tryParse(part), inputFilename: args.firstOrNull);
}

Future<void> solveDay(int day, {int? part, String? inputFilename}) async {
  // Reading input...
  final dayString = day.toString().padLeft(2, '0');
  final lines = await readInputFile(dayString, inputFilename ?? 'input');

  // Finding current day solution class to use
  final solutionPath = 'package:app/day$dayString/solution.dart';
  final solutionLibrary = currentMirrorSystem()
      .libraries
      .values
      .firstWhere((l) => l.uri.toString() == solutionPath);
  final solutionClass = solutionLibrary.declarations.values
      .firstWhere((d) => d.simpleName == Symbol('Solution')) as ClassMirror;

  // Solving...
  final solutionInstance = solutionClass.newInstance(Symbol(''), [lines]);

  if (part == null || part == 1) {
    final result = solutionInstance.invoke(Symbol('solvePart1'), []).reflectee;
    stdout.writeln('Solution 1: $result');
  }

  if (part == null || part == 2) {
    final result = solutionInstance.invoke(Symbol('solvePart2'), []).reflectee;
    stdout.writeln('Solution 2: $result');
  }

  stdout.writeln('Done !');
}
