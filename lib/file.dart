import 'dart:convert';
import 'dart:io';

Future<List<String>> readInputFile(String day, String inputFilename) async {
  final solutionFolder = 'lib/day$day';

  final fileStream = utf8.decoder
      .bind(File('$solutionFolder/$inputFilename.txt').openRead())
      .transform(const LineSplitter());

  final List<String> lines = [];

  try {
    await for (final line in fileStream) {
      lines.add(line);
    }
  } catch (error) {
    stderr.writeln(error);
    exitCode = 2;
  }

  stdout.writeln('Input file $solutionFolder/$inputFilename.txt read');
  stdout.writeln('==================================');

  return lines;
}
