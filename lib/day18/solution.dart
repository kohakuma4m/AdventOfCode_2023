import 'package:ansicolor/ansicolor.dart';
import 'package:collection/collection.dart';

import 'package:app/map.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    print('Digging trenches...');
    final digInstructions = readDigInstructions(lines);
    final map = DigPlanMap.fromDigInstructions(digInstructions);

    print('Digging interior...');
    map.digInterior();
    map.display();

    return map.findSymbolCoordinates(mapSymbols[MapSymbol.trench]!).length;
  }

  Future<int> solvePart2() async {
    final digInstructions = readDigInstructions(lines, colorSwap: true);

    print('Mapping vertices...');
    final List<Point> vertices = [];
    var current = Point(0, 0); // Start
    for (final (direction, nbSteps) in digInstructions) {
      current = getAdjacentDirectionCoordinate(current, direction, distance: nbSteps);
      vertices.add(current);
    }

    print('Calculating perimeter and area...');
    final perimeter = calculatePolygonPerimeter(vertices);
    final area = calculatePolygonArea(vertices);

    print('-------------------');
    print('Vertices: ${vertices.length}');
    print('Perimeter: $perimeter');
    print('Area: $area');
    print('-------------------');

    return perimeter + calculateNbInteriorPoints(area, perimeter);
  }

  ///==========================================================
  /// Calculate polygon perimeter
  ///
  /// vertices: the list of vertices coordinates
  ///==========================================================
  static int calculatePolygonPerimeter(List<Point> vertices) {
    var perimeter = calculateDistanceBetweenPoints(vertices.last, vertices.first);
    for (var i = 1; i < vertices.length; i++) {
      perimeter += calculateDistanceBetweenPoints(vertices[i], vertices[i - 1]);
    }

    return perimeter;
  }

  ///================================================================
  /// Calculate polygon area using Shoelace formula
  /// https://en.wikipedia.org/wiki/Shoelace_formula
  ///
  /// vertices: the list of vertices coordinates
  ///================================================================
  static int calculatePolygonArea(List<Point> vertices) {
    var area = 0.0;

    var j = vertices.length - 1;
    for (var i = 0; i < vertices.length; i++) {
      area += (vertices[j].x + vertices[i].x) * (vertices[j].y - vertices[i].y);
      j = i;
    }

    return (area / 2.0).abs().round();
  }

  ///================================================================
  /// Calculate number of points inside polygon using Pick's theorem
  /// https://en.wikipedia.org/wiki/Pick%27s_theorem
  ///
  /// area      : polygon area
  /// perimeter : polygon perimeter
  ///================================================================
  static int calculateNbInteriorPoints(int area, int perimeter) {
    return (area + 1 - perimeter / 2).toInt();
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum MapSymbol { groundLevelTerrain, trench }

const mapSymbols = {MapSymbol.groundLevelTerrain: '.', MapSymbol.trench: '#'};

final mapColors = {
  mapSymbols[MapSymbol.groundLevelTerrain]!: AnsiPen()..gray(level: 0.5),
  mapSymbols[MapSymbol.trench]!: AnsiPen()..cyan(bold: true),
};

final RegExp digInstructionRegex = RegExp(r'(?<direction>U|R|D|L) (?<nb_steps>\d+) \((?<trench_hex_color>.+)\)');
const Map<dynamic, Direction> directionsMap = {
  'U': Direction.up,
  'R': Direction.right,
  'D': Direction.down,
  'L': Direction.left,
  '0': Direction.right,
  '1': Direction.down,
  '2': Direction.left,
  '3': Direction.up
};

typedef DigInstruction = (Direction, int);

List<DigInstruction> readDigInstructions(List<String> lines, {bool colorSwap = false}) {
  return lines.map((line) {
    final match = digInstructionRegex.allMatches(line).first;
    final trenchColor = match.namedGroup('trench_hex_color')!;

    final direction = directionsMap[colorSwap ? trenchColor[trenchColor.length - 1] : match.namedGroup('direction')]!;
    final nbSteps = colorSwap ? int.parse(trenchColor.substring(1, trenchColor.length - 1), radix: 16) : int.parse(match.namedGroup('nb_steps')!);

    return (direction, nbSteps);
  }).toList();
}

class DigPlanMap extends MapGrid {
  final Set<Point> interiorHoles = {};
  final Point start;

  // Default constructor with extra param...
  DigPlanMap(super.width, super.height, super.grid, this.start) : super();

  // Factory constructor
  factory DigPlanMap.fromDigInstructions(List<DigInstruction> digInstructions) {
    var current = Point(0, 0); // Start
    final Set<Point> trenchCoordinates = {current};
    for (final (direction, nbSteps) in digInstructions) {
      for (var i = 0; i < nbSteps; i++) {
        current = getAdjacentDirectionCoordinate(current, direction);
        trenchCoordinates.add(current);
      }
    }

    // Finding map boundaries
    final xValues = trenchCoordinates.map((p) => p.x).sorted((a, b) => a - b);
    final yValues = trenchCoordinates.map((p) => p.y).sorted((a, b) => a - b);
    final (xMin, xMax) = (xValues.first, xValues.last);
    final (yMin, yMax) = (yValues.first, yValues.last);

    // Transposing all map coordinates to positive values
    final (dx, dy) = (xMin < 0 ? -xMin : 0, yMin < 0 ? -yMin : 0);
    final start = Point(dx, dy);
    if (dx > 0 || dy > 0) {
      final transposedCoordinates = trenchCoordinates.map((p) => Point(p.x + dx, p.y + dy)).toSet();
      trenchCoordinates.clear();
      trenchCoordinates.addAll(transposedCoordinates);
    }

    final mapEntries = trenchCoordinates.map((point) => MapEntry(point, mapSymbols[MapSymbol.trench]!));

    return DigPlanMap(xMax - xMin + 1, yMax - yMin + 1, Map.fromEntries(mapEntries), start);
  }

  void digInterior() {
    // Finding interior tile around starting corner for digging region starting point (to avoid mapping all outer region...)
    final adjacentTiles = super.getAdjacentSymbolCoordinates(start);
    final adjacentDirections =
        adjacentTiles.map((tile) => start.getDirectionTo(tile)!).sorted((a, b) => Direction.values.indexOf(a) - Direction.values.indexOf(b));

    switch (adjacentDirections) {
      case [Direction.up, Direction.right]:
        {
          interiorHoles.add(Point(start.x + 1, start.y - 1));
        }
      case [Direction.up, Direction.left]:
        {
          interiorHoles.add(Point(start.x - 1, start.y - 1));
        }
      case [Direction.right, Direction.down]:
        {
          interiorHoles.add(Point(start.x + 1, start.y + 1));
        }
      case [Direction.down, Direction.left]:
        {
          interiorHoles.add(Point(start.x - 1, start.y + 1));
        }
      default:
        {
          throw Exception('Uncovered case ! $adjacentDirections');
        }
    }

    final (enclosedRegions, _) = super.findEmptyRegions(emptyCoordinates: interiorHoles, includeUnmappedRegionCoordinates: true);
    for (final coordinate in enclosedRegions.first) {
      interiorHoles.add(coordinate);
      super.grid.addAll({coordinate: mapSymbols[MapSymbol.trench]!});
    }
  }

  @override
  display(
      {bool showBorder = true,
      String? emptySymbol,
      String borderXSymbol = '-',
      String borderYSymbol = '|',
      Map<String, AnsiPen>? symbolsColorsMap,
      Map<Point, AnsiPen> coordinatesColorsMap = const {},
      bool showInterior = true,
      AnsiPen? interiorColor}) {
    final Map<Point, AnsiPen> coordinateColors = Map.from(coordinatesColorsMap);
    if (showInterior) {
      final interiorPenColor = interiorColor ?? (AnsiPen()..red(bold: true));
      coordinateColors.addEntries(interiorHoles.map((point) => MapEntry(point, interiorPenColor)));
    }

    super.display(
        showBorder: showBorder,
        emptySymbol: emptySymbol ?? mapSymbols[MapSymbol.groundLevelTerrain]!,
        borderXSymbol: borderXSymbol,
        borderYSymbol: borderYSymbol,
        symbolsColorsMap: symbolsColorsMap ?? mapColors,
        coordinatesColorsMap: showInterior ? coordinateColors : coordinatesColorsMap);
  }
}
