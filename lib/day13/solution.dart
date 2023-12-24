import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final patterns = readPatterns(lines);
    printPatterns(patterns);

    return patterns.map((pattern) => pattern.reflexionValue!).sum;
  }

  Future<int> solvePart2() async {
    final patterns = readPatterns(lines);

    // Fixing smudges...
    final List<Pattern> fixedPatterns = [];
    next:
    for (final pattern in patterns) {
      // Altering pattern one character at a time until we find new valid reflexion
      for (var y = 0; y < pattern.rows.length; y++) {
        for (var x = 0; x < pattern.columns.length; x++) {
          final invertedSymbol = pattern.rows[y][x] == mapSymbols[MapSymbol.ash] ? mapSymbols[MapSymbol.rock]! : mapSymbols[MapSymbol.ash]!;
          final newRows = [...pattern.rows];
          newRows[y] = newRows[y].replaceRange(x, x + 1, invertedSymbol);

          // Validating new symmetry axis (ignoring original one)
          final newPattern = Pattern(newRows, pattern.horizontalSymmetryAxis, pattern.verticalSymmetryAxis);
          if (newPattern.reflexionValue != null && newPattern.reflexionValue != pattern.reflexionValue) {
            // Found valid new pattern
            fixedPatterns.add(newPattern);
            continue next;
          }
        }
      }
    }
    printPatterns(fixedPatterns);

    return fixedPatterns.map((pattern) => pattern.reflexionValue!).sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<Pattern> readPatterns(List<String> lines) {
    List<List<String>> patterns = [[]];

    for (final line in lines) {
      if (line.isEmpty) {
        // New pattern
        patterns.add([]);
        continue;
      }

      patterns.last.add(line);
    }

    return patterns.map((rows) => Pattern(rows)).toList();
  }

  static void printPatterns(List<Pattern> patterns) {
    for (final (idx, pattern) in patterns.indexed) {
      print('Pattern #${idx + 1} --> $pattern');
    }
    print('-------------------');
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { ash, rock }

const mapSymbols = {MapSymbol.ash: '.', MapSymbol.rock: '#'};

class Pattern {
  List<String> rows;
  late List<String> columns;
  late int? horizontalSymmetryAxis;
  late int? verticalSymmetryAxis;
  late int? reflexionValue;

  Pattern(this.rows, [int? skipHorizontalSymmetryAxis, int? skipVerticalSymmetryAxis]) {
    columns = [];
    for (var x = 0; x < rows.first.length; x++) {
      columns.add(rows.map((row) => row[x]).join(''));
    }

    horizontalSymmetryAxis = _findSymmetryIndex(columns, skipIndex: skipHorizontalSymmetryAxis);
    verticalSymmetryAxis = _findSymmetryIndex(rows, skipIndex: skipVerticalSymmetryAxis);
    reflexionValue = _getReflexionValue();
  }

  static int? _findSymmetryIndex(List<String> lines, {int? skipIndex = -1}) {
    next:
    for (var i = 1; i < lines.length; i++) {
      if (i == skipIndex) {
        continue;
      }

      // Validating symmetry along current inbetween position
      var delta = 0;
      while (i - delta > 0 && i + delta < lines.length) {
        if (lines[i - delta - 1] != lines[i + delta]) {
          continue next; // No symmetry
        }
        delta++;
      }

      // Found valid symmetry axis
      return i;
    }

    return null;
  }

  int? _getReflexionValue() {
    if (horizontalSymmetryAxis == null && verticalSymmetryAxis == null) {
      return null;
    }

    return (horizontalSymmetryAxis ?? 0) * 1 + (verticalSymmetryAxis ?? 0) * 100;
  }

  @override
  String toString() {
    if (horizontalSymmetryAxis == null && verticalSymmetryAxis == null) {
      return 'No symmetry';
    }

    if (verticalSymmetryAxis == null) {
      return 'Horizontal symmetry (y = $horizontalSymmetryAxis) --> $reflexionValue';
    }

    if (horizontalSymmetryAxis == null) {
      return 'Vertical symmetry (x = $verticalSymmetryAxis) --> $reflexionValue';
    }

    return 'Horizontal/Vertical symmetry (y = $verticalSymmetryAxis, x = $horizontalSymmetryAxis) --> $reflexionValue';
  }
}
