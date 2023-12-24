import 'package:ansicolor/ansicolor.dart';
import 'package:collection/collection.dart';

import 'package:app/map.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final map = TiltMap.fromLines(lines);

    // Tilting north
    map.tiltNorth();
    map.display(symbolsColorsMap: mapColors);

    return map.getRoundRockCoordinates().map((coordinate) => map.height - coordinate.y).sum;
  }

  Future<int> solvePart2({int nbSpinCycles = 1000000000}) async {
    final map = TiltMap.fromLines(lines);

    var i = 0;
    var positionsHistory = [map.getRoundRockCoordinates()];
    var fastForward = false;
    while (i < nbSpinCycles) {
      // Spin cycle
      map.tiltNorth();
      map.tiltWest();
      map.tiltSouth();
      map.tiltEast();

      i++;
      if (fastForward) {
        continue;
      }

      final newPositions = map.getRoundRockCoordinates();
      for (final (idx, previousPositions) in positionsHistory.indexed) {
        if (newPositions.indexed.every((e) => e.$2 == previousPositions[e.$1])) {
          // Found repeating cycle --> fast forward to last cycle
          fastForward = true;
          final period = i - idx;
          final lastSpinCycleIndex = nbSpinCycles - 1;
          i = lastSpinCycleIndex - ((lastSpinCycleIndex - i) % period);
          print('Repeating cycle with period $period detected after $i spin cycles --> fast forward to spin cycle #$i');
          break;
        }
      }
      positionsHistory.add(newPositions);
    }

    map.display(symbolsColorsMap: mapColors);

    return map.getRoundRockCoordinates().map((coordinate) => map.height - coordinate.y).sum;
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { roundRock, cubeRock, emptySpace }

const mapSymbols = {MapSymbol.emptySpace: '.', MapSymbol.roundRock: 'O', MapSymbol.cubeRock: '#'};

MapSymbol getMapSymbol(String symbol) {
  return mapSymbols.keys.firstWhere((key) => mapSymbols[key] == symbol);
}

final mapColors = {
  mapSymbols[MapSymbol.emptySpace]!: AnsiPen()..gray(level: 0.5),
  mapSymbols[MapSymbol.roundRock]!: AnsiPen()..blue(bold: true),
  mapSymbols[MapSymbol.cubeRock]!: AnsiPen()..white(bold: true)
};

class TiltMap extends MapGrid {
  TiltMap.fromLines(super.lines) : super.fromLines(emptySymbol: mapSymbols[MapSymbol.emptySpace]!);

  List<Point> getRoundRockCoordinates() {
    return super.findSymbolCoordinates(mapSymbols[MapSymbol.roundRock]!).sorted();
  }

  void tiltNorth() {
    for (final coordinate in getRoundRockCoordinates()) {
      var y = coordinate.y;
      while (y > 0 && [null, mapSymbols[MapSymbol.emptySpace]!].contains(super.grid[Point(coordinate.x, y - 1)])) {
        y--;
      }

      super.grid.remove(coordinate);
      super.grid.addAll({Point(coordinate.x, y): mapSymbols[MapSymbol.roundRock]!});
    }
  }

  void tiltWest() {
    for (final coordinate in getRoundRockCoordinates()) {
      var x = coordinate.x;
      while (x > 0 && [null, mapSymbols[MapSymbol.emptySpace]!].contains(super.grid[Point(x - 1, coordinate.y)])) {
        x--;
      }

      super.grid.remove(coordinate);
      super.grid.addAll({Point(x, coordinate.y): mapSymbols[MapSymbol.roundRock]!});
    }
  }

  void tiltSouth() {
    for (final coordinate in getRoundRockCoordinates().reversed) {
      var y = coordinate.y;
      while (y < super.height - 1 && [null, mapSymbols[MapSymbol.emptySpace]!].contains(super.grid[Point(coordinate.x, y + 1)])) {
        y++;
      }

      super.grid.remove(coordinate);
      super.grid.addAll({Point(coordinate.x, y): mapSymbols[MapSymbol.roundRock]!});
    }
  }

  void tiltEast() {
    for (final coordinate in getRoundRockCoordinates().reversed) {
      var x = coordinate.x;
      while (x < super.width - 1 && [null, mapSymbols[MapSymbol.emptySpace]!].contains(super.grid[Point(x + 1, coordinate.y)])) {
        x++;
      }

      super.grid.remove(coordinate);
      super.grid.addAll({Point(x, coordinate.y): mapSymbols[MapSymbol.roundRock]!});
    }
  }
}
