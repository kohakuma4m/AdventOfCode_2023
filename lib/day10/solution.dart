import 'package:app/map.dart';
import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final map = MapGrid.fromLines(lines, emptySymbol: mapSymbols[MapSymbol.emptyTile]!);
    map.display();

    final startPosition = map.findSymbolCoordinates(mapSymbols[MapSymbol.start]!).first;
    final halfLoopPaths = getHalfLoopPaths(startPosition, map);

    return halfLoopPaths.firstHalf.length - 1; // Ignoring starting node
  }

  Future<int> solvePart2() async {
    final map = MapGrid.fromLines(lines);

    final startPosition = map.findSymbolCoordinates(mapSymbols[MapSymbol.start]!).first;
    final halfLoopPaths = getHalfLoopPaths(startPosition, map);

    // Cleaning up map by removing all junk pipes not part of loop
    final nbSteps = halfLoopPaths.firstHalf.length - 1; // Ignoring starting node
    final fullLoopPath = [...halfLoopPaths.firstHalf, ...halfLoopPaths.secondHalf.reversed.toList().sublist(1, nbSteps)];
    map.grid.removeWhere((point, symbol) => !fullLoopPath.contains(point));
    map.display();

    // All regions enclosed by pipes
    final (enclosedRegions, _) = map.getEmptyRegions();
    print('Number of enclosed regions in normal coordinates system: ${enclosedRegions.length}');

    //==============================================================================================================================
    // Zooming in by doubling coordinates system so we can squeeze through pipes and validate if enclosed region is inside the loop
    //
    // There should be only one connected region enclosed by loop since we have a single loop
    //
    // If we search all zoomed in map (N2 number of points to search through), it takes about 00:30 (mm:ss) to run
    // If we only search for empty spaces inside enclosed regions and inbetween pipes, it takes about 00:08 (mm:ss) to run
    //==============================================================================================================================
    final zoomedInMap = getZoomedInMap(map, emptyPoints: enclosedRegions.flattened.toSet());
    final emptyPoints = zoomedInMap.findSymbolCoordinates(mapSymbols[MapSymbol.emptyTile]!).toSet();

    final (zoomedInRegions, _) = zoomedInMap.getEmptyRegions(emptyCoordinates: emptyPoints);
    print('Number of enclosed regions in zoomed in coordinates system: ${zoomedInRegions.length}');

    // Removing outer regions (i.e: next to an unmapped value)
    final enclosedLoopRegions = zoomedInRegions.where((region) {
      return region.every((coordinate) => zoomedInMap.getAdjacentSymbolCoordinates(coordinate).length == 8);
    }).toList();
    assert(enclosedLoopRegions.length == 1, 'Loop should contain a single enclosed connected region');

    final enclosedPoints = enclosedLoopRegions.flattened
        .where((coordinate) => coordinate.x % 2 == 0 && coordinate.y % 2 == 0) // Removing added extra space inbetween pipes
        .toList();
    print('-------');

    return enclosedPoints.length;
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { verticalPipe, horizontalPipe, upRightPipe, upLeftPipe, downLeftPipe, downRightPipe, emptyTile, start }

const mapSymbols = {
  MapSymbol.verticalPipe: '|',
  MapSymbol.horizontalPipe: '-',
  MapSymbol.downRightPipe: 'L',
  MapSymbol.downLeftPipe: 'J',
  MapSymbol.upLeftPipe: '7',
  MapSymbol.upRightPipe: 'F',
  MapSymbol.emptyTile: '.',
  MapSymbol.start: 'S'
};

MapSymbol getMapSymbol(String? symbol) {
  return mapSymbols.keys.firstWhereOrNull((key) => mapSymbols[key] == symbol) ?? MapSymbol.emptyTile;
}

List<Point> getAdjacentPipesCoordinates(Point current, MapGrid map) {
  final currentSymbol = getMapSymbol(map.grid[current]);
  final adjacentCoordinates = map.getAdjacentSymbolCoordinates(current, diagonalDirections: false);

  final List<Point> adjacentPipeCoordinates = [];
  for (final coordinate in adjacentCoordinates) {
    final direction = current.getDirectionTo(coordinate);
    final symbol = getMapSymbol(map.grid[coordinate]);
    switch ((direction, symbol)) {
      case (Direction.up, MapSymbol.verticalPipe):
      case (Direction.up, MapSymbol.upRightPipe):
      case (Direction.up, MapSymbol.upLeftPipe):
        {
          if ([MapSymbol.start, MapSymbol.verticalPipe, MapSymbol.downRightPipe, MapSymbol.downLeftPipe].contains(currentSymbol)) {
            adjacentPipeCoordinates.add(coordinate);
          }
        }
      case (Direction.right, MapSymbol.horizontalPipe):
      case (Direction.right, MapSymbol.upLeftPipe):
      case (Direction.right, MapSymbol.downLeftPipe):
        {
          if ([MapSymbol.start, MapSymbol.horizontalPipe, MapSymbol.upRightPipe, MapSymbol.downRightPipe].contains(currentSymbol)) {
            adjacentPipeCoordinates.add(coordinate);
          }
        }
      case (Direction.down, MapSymbol.verticalPipe):
      case (Direction.down, MapSymbol.downRightPipe):
      case (Direction.down, MapSymbol.downLeftPipe):
        {
          if ([MapSymbol.start, MapSymbol.verticalPipe, MapSymbol.upRightPipe, MapSymbol.upLeftPipe].contains(currentSymbol)) {
            adjacentPipeCoordinates.add(coordinate);
          }
        }
      case (Direction.left, MapSymbol.horizontalPipe):
      case (Direction.left, MapSymbol.upRightPipe):
      case (Direction.left, MapSymbol.downRightPipe):
        {
          if ([MapSymbol.start, MapSymbol.horizontalPipe, MapSymbol.upLeftPipe, MapSymbol.downLeftPipe].contains(currentSymbol)) {
            adjacentPipeCoordinates.add(coordinate);
          }
        }
      default:
        {
          // Not a connected pipe
        }
    }
  }

  return adjacentPipeCoordinates;
}

({List<Point> firstHalf, List<Point> secondHalf}) getHalfLoopPaths(Point startPosition, MapGrid map) {
  // Going in both directions at the same time
  final adjacentPipeCoordinates = getAdjacentPipesCoordinates(startPosition, map);
  final halfLoopPaths = (firstHalf: [startPosition, adjacentPipeCoordinates.first], secondHalf: [startPosition, adjacentPipeCoordinates.last]);
  do {
    // First half
    final nextPipeCoordinates1 = getAdjacentPipesCoordinates(halfLoopPaths.firstHalf.last, map).firstWhere((c) {
      return c != halfLoopPaths.firstHalf[halfLoopPaths.firstHalf.length - 2];
    });
    halfLoopPaths.firstHalf.add(nextPipeCoordinates1);

    // Second half
    final nextPipeCoordinates2 = getAdjacentPipesCoordinates(halfLoopPaths.secondHalf.last, map).firstWhere((c) {
      return c != halfLoopPaths.secondHalf[halfLoopPaths.secondHalf.length - 2];
    });
    halfLoopPaths.secondHalf.add(nextPipeCoordinates2);
  } while (halfLoopPaths.firstHalf.last != halfLoopPaths.secondHalf.last);

  return halfLoopPaths;
}

MapGrid getZoomedInMap(MapGrid map, {Set<Point>? emptyPoints}) {
  final newEntries = map.grid.entries.map((entry) => MapEntry(entry.key * 2, entry.value)).toList();
  final zoomedInMap = MapGrid(map.width * 2, map.height * 2, Map.fromEntries(newEntries));

  // Adding connecting pipes and new empty space inbetween
  for (final coordinate in map.grid.keys) {
    switch (getMapSymbol(map.grid[coordinate])) {
      case MapSymbol.upRightPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.right): mapSymbols[MapSymbol.horizontalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.down): mapSymbols[MapSymbol.verticalPipe]!,
          });
        }
      case MapSymbol.downRightPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.right): mapSymbols[MapSymbol.horizontalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.up): mapSymbols[MapSymbol.verticalPipe]!,
          });
        }
      case MapSymbol.downLeftPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.left): mapSymbols[MapSymbol.horizontalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.up): mapSymbols[MapSymbol.verticalPipe]!,
          });
        }
      case MapSymbol.upLeftPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.left): mapSymbols[MapSymbol.horizontalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.down): mapSymbols[MapSymbol.verticalPipe]!,
          });
        }
      case MapSymbol.horizontalPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.left): mapSymbols[MapSymbol.horizontalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.right): mapSymbols[MapSymbol.horizontalPipe]!,
          });
        }
      case MapSymbol.verticalPipe:
        {
          zoomedInMap.grid.addAll({
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.up): mapSymbols[MapSymbol.verticalPipe]!,
            getAdjacentDirectionCoordinate(coordinate * 2, Direction.down): mapSymbols[MapSymbol.verticalPipe]!,
          });
        }
      default:
        {
          // No connecting pipe
        }
    }
  }

  // Also adding empty points and new empty space inbetween original coordinates
  if (emptyPoints != null) {
    for (final coordinate in emptyPoints) {
      zoomedInMap.grid.putIfAbsent(coordinate * 2, () => mapSymbols[MapSymbol.emptyTile]!);
    }
    for (final coordinate in [...map.grid.keys, ...emptyPoints]) {
      zoomedInMap.grid.putIfAbsent(getAdjacentDirectionCoordinate(coordinate * 2, Direction.right), () => mapSymbols[MapSymbol.emptyTile]!);
      zoomedInMap.grid.putIfAbsent(getAdjacentDirectionCoordinate(coordinate * 2, Direction.downRight), () => mapSymbols[MapSymbol.emptyTile]!);
      zoomedInMap.grid.putIfAbsent(getAdjacentDirectionCoordinate(coordinate * 2, Direction.down), () => mapSymbols[MapSymbol.emptyTile]!);
    }
  }

  return zoomedInMap;
}
