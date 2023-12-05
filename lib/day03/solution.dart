import 'dart:developer';

import 'package:collection/collection.dart';

class Solution {
  List<String> lines = [];

  Solution(this.lines);

  int solvePart1() {
    final schema = readSchematic(lines);
    schema.grid.display();

    final validParts = schema.parts.where((part) {
      final List<Point> pointsToCheck = [];
      final [x1, x2, y0] = [part.p1.x, part.p2.x, part.p1.y];
      for (var y = y0 - 1; y <= y0 + 1; y++) {
        final dx = y == y0 ? x2 - x1 + 2 : 1; // Excluding points overlapping with part
        for (var x = x1 - 1; x <= x2 + 1; x += dx) {
          if (x >= 0 && x < schema.grid.width && y >= 0 && y < schema.grid.heigth) {
            pointsToCheck.add((x: x, y: y));
          }
        }
      }

      return pointsToCheck.firstWhereOrNull((point) {
        final character = schema.grid.coordinates[point];
        return character != null && character != emptySymbol && int.tryParse(character) == null; // Part character
      }) != null;
    });

    return validParts.map((part) => part.number).sum;
  }

  int solvePart2() {
    final schema = readSchematic(lines);
    // schema.grid.display();

    final List<Gear> gears = schema.symbols
      .where((symbol) => symbol.value == gearSymbol)
      .map((symbol) {
        final List<Point> pointsToCheck = [];
        final [x0, y0] = [symbol.p.x, symbol.p.y];
        for (var y = y0 - 1; y <= y0 + 1; y++) {
          final dx = y == y0 ? 2 : 1; // Excluding points overlapping with symbol
          for (var x = x0 - 1; x <= x0 + 1; x += dx) {
            if (x >= 0 && x < schema.grid.width && y >= 0 && y < schema.grid.heigth) {
              pointsToCheck.add((x: x, y: y));
            }
          }
        }

        final Set<Part> adjacentParts = {};
        for (final point in pointsToCheck) {
            final character = schema.grid.coordinates[point];
            if (character != null && character != emptySymbol && int.tryParse(character) != null) {
              // Part number character
              final part = schema.parts.firstWhere((part) {
                final y = part.p1.y;
                for (var x = part.p1.x; x <= part.p2.x; x++) {
                  if (x == point.x && y == point.y) {
                    return true;
                  }
                }

                return false;
              });

              adjacentParts.add(part);
            }
        }

        return (symbol: symbol, adjacentParts: adjacentParts);
      })
      .where((gear) => gear.adjacentParts.length == 2)
      .toList();

    return gears
      .map((gear) {
        final gearRatio = gear.adjacentParts.map((part) => part.number).reduce((product, value) => product * value);
        return gearRatio;
      })
      .sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////
  
  static final RegExp lineElements = RegExp(r'(\d+|.)');
  
  static Schematic readSchematic(List<String> lines) {
    final grid = Grid(lines[0].length, lines.length, {});
    final Set<Part> parts = {};
    final Set<Character> symbols = {};

    for (var y = 0; y < lines.length; y++) {
      final line = lines[y];
      for (final match in lineElements.allMatches(line)) {
        final [x1, x2] = [match.start, match.end - 1];
        final element = match.group(match.groupCount)!;

        if (int.tryParse(element) != null) {
          // Part
          parts.add((p1: (x: x1, y: y), p2: (x: x2, y: y), number: int.parse(element)));
          for (var x = x1; x <= x2; x++) {
            grid.coordinates.addAll({ (x: x, y: y): line[x] });
          }
        } else if (element != emptySymbol) {
          // Non empty symbol
          symbols.add((p: (x: x1, y: y), value: element));
          grid.coordinates.addAll({ (x: x1, y: y): element });
        }
      }
    }

    return (grid: grid, parts: parts, symbols: symbols);
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

String emptySymbol = '.';
String gearSymbol = '*';

typedef Point = ({ int x, int y });
typedef Part = ({ Point p1, Point p2, int number });
typedef Character = ({ Point p, String value });
typedef Schematic = ({ Grid grid, Set<Part> parts, Set<Character> symbols });
typedef Gear = ({ Character symbol, Set<Part> adjacentParts });

class Grid {
  int width = 0;
  int heigth = 0;
  Map<Point, String> coordinates = {};

  Grid(this.width, this.heigth, this.coordinates);

  void display() {
    final separator = '-' * (width + 2);

    print(separator);
    for (var y = 0; y < heigth; y++) {
      var line = '';
      for (var x = 0; x < width; x++) {
        line += coordinates[(x: x, y: y)] ?? emptySymbol;
      }
      print('|$line|');
    }
    print(separator);
  }
}

