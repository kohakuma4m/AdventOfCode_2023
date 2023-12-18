import 'dart:async';
import 'dart:isolate';

import 'package:ansicolor/ansicolor.dart';
import 'package:collection/collection.dart';
import 'package:trotter/trotter.dart';

import 'package:app/map.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1({int spaceExpansionCoefficient = 2}) async {
    final map = MapGrid.fromLines(lines, emptySymbol: mapSymbols[MapSymbol.emptySpace]!);
    map.display(symbolsColorsMap: mapColors);

    final (emptyRows, emptyColumns) = findExpandingEmptySpace(map);
    print('Empty rows: $emptyRows');
    print('Empty columns: $emptyColumns');
    print('-------------------');

    final galaxies = map.findSymbolCoordinates(mapSymbols[MapSymbol.galaxy]!);
    final galaxyPairs = Combinations(2, galaxies);
    print('Number of galaxies: ${galaxies.length}');
    print('Number of galaxy pairs: ${galaxyPairs.length}');
    print('-------------------');

    final galaxyDistances = await calculateDistanceBetweenAllGalaxyPairs(galaxyPairs, (rows: emptyRows, columns: emptyColumns), spaceExpansionCoefficient);
    print('-------------------');

    return galaxyDistances.values.sum;
  }

  Future<int> solvePart2({int spaceExpansionCoefficient = 1000000}) async {
    return solvePart1(spaceExpansionCoefficient: spaceExpansionCoefficient);
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { emptySpace, galaxy }

const mapSymbols = {MapSymbol.emptySpace: '.', MapSymbol.galaxy: '#'};

final mapColors = {'.': AnsiPen()..gray(level: 0.5), '#': AnsiPen()..yellow(bold: true)};

(List<int>, List<int>) findExpandingEmptySpace(MapGrid map) {
  final List<int> emptyRowIndexes = [];
  for (var y = 0; y < map.height; y++) {
    final rowGalaxies = map.grid.keys.where((coordinate) => coordinate.y == y);
    if (rowGalaxies.isEmpty) {
      emptyRowIndexes.add(y);
    }
  }

  final List<int> emptyColumnsIndexes = [];
  for (var x = 0; x < map.width; x++) {
    final columnGalaxies = map.grid.keys.where((coordinate) => coordinate.x == x);
    if (columnGalaxies.isEmpty) {
      emptyColumnsIndexes.add(x);
    }
  }

  return (emptyRowIndexes, emptyColumnsIndexes);
}

typedef ExpandingSpace = ({List<int> rows, List<int> columns});
typedef GalaxyDistancesMap = Map<List<Point>, int>;

Future<GalaxyDistancesMap> calculateDistanceBetweenAllGalaxyPairs(
    Combinations<Point> galaxyPairs, ExpandingSpace expandingSpace, int spaceExpansionCoefficient) async {
  final nbGalaxyPairs = galaxyPairs.length.toInt();
  final Map<List<Point>, int> galaxyDistances = {};

  // Wrapping calculations in promises to save time (improves calculation from about 1 minute to around 40 seconds)
  final List<Future<void>> promises = [];

  for (final (idx, galaxyPair) in galaxyPairs().indexed) {
    if (idx % (nbGalaxyPairs / 10).round() == 0) {
      print('Galaxy pair #${idx + 1}');
    }

    final completer = Completer<int>();

    calculateDistanceBetweenGalaxyPair(galaxyPair, expandingSpace, spaceExpansionCoefficient).then((distance) {
      galaxyDistances.addAll({galaxyPair: distance});
      completer.complete(distance);
    });

    promises.add(completer.future);
  }

  // Waiting for all calculations to complete
  await Future.wait(promises);

  return galaxyDistances;
}

Future<int> calculateDistanceBetweenGalaxyPair(List<Point> galaxyPair, ExpandingSpace expandingSpace, int spaceExpansionCoefficient) async {
  final [coordinate1, coordinate2] = galaxyPair;
  final distance = calculateDistanceBetweenPoints(coordinate1, coordinate2);

  // Accounting for expanding space
  // Since we read galaxies vertically from top to bottom, combinations ensure second galaxy in pair is always on the same row or lower
  final nbExpandingRows = expandingSpace.rows.where((idx) => idx.isBetweenExclusive(coordinate1.y, coordinate2.y)).length;
  final nbExpandingColumns = coordinate2.x > coordinate1.x
      ? expandingSpace.columns.where((idx) => idx.isBetweenExclusive(coordinate1.x, coordinate2.x)).length
      : expandingSpace.columns.where((idx) => idx.isBetweenExclusive(coordinate2.x, coordinate1.x)).length;
  final extraDistancesForExpandingSpace = (spaceExpansionCoefficient - 1) * (nbExpandingRows + nbExpandingColumns);

  return distance + extraDistancesForExpandingSpace;
}
