import 'package:ansicolor/ansicolor.dart';

import 'package:app/map.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final map = MapGrid.fromLines(lines);

    final energizedTiles = getEnergizedTiles(map);
    displayEnergizedTiles(map, energizedTiles);

    return energizedTiles.length;
  }

  Future<int> solvePart2() async {
    final map = MapGrid.fromLines(lines);

    // Generating all possible starting beams
    final List<Step> startingBeams = [];
    for (var x = 0; x < map.width; x++) {
      startingBeams.addAll([
        (coordinate: Point(x, 0), direction: Direction.down),
        (coordinate: Point(x, map.height - 1), direction: Direction.up),
      ]);
    }
    for (var y = 0; y < map.height; y++) {
      startingBeams.addAll([
        (coordinate: Point(0, y), direction: Direction.right),
        (coordinate: Point(map.width - 1, y), direction: Direction.left),
      ]);
    }
    startingBeams.sort((a, b) {
      final value = compareDirection(a.direction, b.direction);
      return value == 0 ? a.coordinate.compareTo(b.coordinate) : value;
    });

    var bestConfiguration = (startingBeam: startingBeams.first, energizedTiles: {Point(0, 0)});
    for (final startingBeam in startingBeams) {
      final energizedTiles = getEnergizedTiles(map, startingBeam: startingBeam);
      print('Beam ${startingBeam.coordinate.toString().padRight(10)} --> ${startingBeam.direction.name.padRight(5)}: ${energizedTiles.length}');

      if (energizedTiles.length > bestConfiguration.energizedTiles.length) {
        bestConfiguration = (startingBeam: startingBeam, energizedTiles: energizedTiles);
      }
    }

    displayEnergizedTiles(map, bestConfiguration.energizedTiles, startingBeam: bestConfiguration.startingBeam);

    final (:coordinate, :direction) = bestConfiguration.startingBeam;
    print('Optimal beam ${coordinate.toString().padRight(10)} --> ${direction.name.padRight(5)}');
    print('----------------------------------');

    return bestConfiguration.energizedTiles.length;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  ///============================================================================================
  /// Iterative DFS solution
  ///============================================================================================
  static Set<Point> getEnergizedTiles(MapGrid map, {Step startingBeam = (coordinate: const Point(0, 0), direction: Direction.right)}) {
    final Set<Point> energizedTiles = {};

    final Set<Step> visitedLightBeams = {};
    final List<Step> lightsBeamsToProcess = [startingBeam];
    while (lightsBeamsToProcess.isNotEmpty) {
      final lightPath = lightsBeamsToProcess.removeLast();
      final (:coordinate, :direction) = lightPath;

      if (!map.isCoordinateWithinMap(coordinate) || visitedLightBeams.contains(lightPath)) {
        continue; // End of ligth path
      }

      energizedTiles.add(coordinate);
      visitedLightBeams.add(lightPath);

      final currentTile = getMapSymbol(map.grid[coordinate]);
      switch ((currentTile, direction)) {
        case (MapSymbol.emptySpace, _):
          {
            // Continue in current direction
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, direction), direction: direction));
            continue;
          }
        case (MapSymbol.horizontalSplitter, Direction.right):
        case (MapSymbol.horizontalSplitter, Direction.left):
        case (MapSymbol.verticalSplitter, Direction.up):
        case (MapSymbol.verticalSplitter, Direction.down):
          {
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, direction), direction: direction));
            continue;
          }
        case (MapSymbol.horizontalSplitter, Direction.up):
        case (MapSymbol.horizontalSplitter, Direction.down):
          {
            // Splitting in both directions perdendicular to splitter
            lightsBeamsToProcess.addAll([
              (coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.left), direction: Direction.left),
              (coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.right), direction: Direction.right)
            ]);
            continue;
          }
        case (MapSymbol.verticalSplitter, Direction.right):
        case (MapSymbol.verticalSplitter, Direction.left):
          {
            // Splitting in both directions perdendicular to splitter
            lightsBeamsToProcess.addAll([
              (coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.up), direction: Direction.up),
              (coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.down), direction: Direction.down)
            ]);
            continue;
          }
        case (MapSymbol.rightMirror, Direction.right):
        case (MapSymbol.leftMirror, Direction.left):
          {
            // Bouncing up
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.up), direction: Direction.up));
            continue;
          }
        case (MapSymbol.rightMirror, Direction.left):
        case (MapSymbol.leftMirror, Direction.right):
          {
            // Bouncing down
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.down), direction: Direction.down));
            continue;
          }
        case (MapSymbol.rightMirror, Direction.up):
        case (MapSymbol.leftMirror, Direction.down):
          {
            // Bouncing right
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.right), direction: Direction.right));
            continue;
          }
        case (MapSymbol.rightMirror, Direction.down):
        case (MapSymbol.leftMirror, Direction.up):
          {
            // Bouncing left
            lightsBeamsToProcess.add((coordinate: getAdjacentDirectionCoordinate(coordinate, Direction.left), direction: Direction.left));
            continue;
          }
        default:
          {
            // No other cases
          }
      }
    }

    return energizedTiles;
  }

  static displayEnergizedTiles(MapGrid map, Set<Point> energizedTiles, {Step? startingBeam}) {
    final Map<Point, AnsiPen> coordinateColors = {};
    final energizedTilesMap = MapGrid(map.width, map.height, Map.fromEntries(map.grid.entries));

    for (final tile in energizedTiles) {
      energizedTilesMap.grid.update(tile, (value) {
        return getMapSymbol(value) == MapSymbol.emptySpace ? mapSymbols[MapSymbol.energizedTile]! : value;
      });
      coordinateColors.addAll({tile: mapColors[mapSymbols[MapSymbol.energizedTile]]!});
    }

    if (startingBeam != null) {
      energizedTilesMap.grid.update(startingBeam.coordinate, (_) => directionSymbols[startingBeam.direction]!);
      coordinateColors.addAll({startingBeam.coordinate: startColor});
    }

    energizedTilesMap.display(symbolsColorsMap: mapColors, coordinatesColorsMap: coordinateColors);
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { emptySpace, rightMirror, leftMirror, verticalSplitter, horizontalSplitter, energizedTile }

const mapSymbols = {
  MapSymbol.emptySpace: '.',
  MapSymbol.rightMirror: '/',
  MapSymbol.leftMirror: '\\',
  MapSymbol.verticalSplitter: '|',
  MapSymbol.horizontalSplitter: '-',
  MapSymbol.energizedTile: '#'
};

MapSymbol getMapSymbol(String? symbol) {
  return symbol != null ? mapSymbols.keys.firstWhere((key) => mapSymbols[key] == symbol) : MapSymbol.emptySpace;
}

bool isSplitter(String symbol) {
  return [MapSymbol.verticalSplitter, MapSymbol.horizontalSplitter].contains(getMapSymbol(symbol));
}

bool isMirror(String symbol) {
  return [MapSymbol.rightMirror, MapSymbol.leftMirror].contains(getMapSymbol(symbol));
}

final mapColors = {
  mapSymbols[MapSymbol.emptySpace]!: AnsiPen()..gray(level: 0.5),
  mapSymbols[MapSymbol.rightMirror]!: AnsiPen()..white(bold: true),
  mapSymbols[MapSymbol.leftMirror]!: AnsiPen()..white(bold: true),
  mapSymbols[MapSymbol.verticalSplitter]!: AnsiPen()..white(bold: true),
  mapSymbols[MapSymbol.horizontalSplitter]!: AnsiPen()..white(bold: true),
  mapSymbols[MapSymbol.energizedTile]!: AnsiPen()..yellow(bold: true)
};

final startColor = AnsiPen()..red(bold: true);
