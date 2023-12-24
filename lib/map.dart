import 'package:ansicolor/ansicolor.dart';
import 'package:collection/collection.dart';

/// Number extensions
extension NumRange on num {
  /// Check is number is within inclusive interval [min, max]
  bool isBetweenInclusive(num min, num max) {
    return min <= this && this <= max;
  }

  /// Check is number is within exclusive interval ]min, max[
  bool isBetweenExclusive(num min, num max) {
    return min < this && this < max;
  }
}

/// 2D point
class Point implements Comparable<Point> {
  final int x;
  final int y;

  /// Constant constructor
  const Point(this.x, this.y);

  /// Get direction of other point
  Direction? getDirectionTo(Point other) {
    final (dx, dy) = (other.x - x, other.y - y);

    if (dx == 0 && dy == 0) return null;
    if (dy == 0) return dx > 0 ? Direction.right : Direction.left;
    if (dx == 0) return dy > 0 ? Direction.down : Direction.up;
    if (dx > 0 && dy > 0) return Direction.downRight;
    if (dx < 0 && dy > 0) return Direction.downLeft;
    if (dx > 0 && dy < 0) return Direction.upRight;
    if (dx < 0 && dy < 0) return Direction.upLeft;

    return null;
  }

  @override
  String toString() {
    return '($x, $y)';
  }

  // Equality

  @override
  bool operator ==(Object other) {
    return other is Point && other.x == x && other.y == y;
  }

  @override
  int get hashCode => '($x, $y)'.hashCode;

  // Sorting

  @override
  int compareTo(Point other) {
    if (this == other) {
      return 0;
    }

    if (x == other.x) {
      return y - other.y;
    }

    return x - other.x;
  }

  // Operators

  bool operator >=(Object other) {
    return other is Point && other.x <= x && other.y <= y;
  }

  bool operator <=(Object other) {
    return other is Point && other.x >= x && other.y >= y;
  }

  bool operator >(Object other) {
    return other is Point && other.x < x && other.y < y;
  }

  bool operator <(Object other) {
    return other is Point && other.x > x && other.y > y;
  }

  Point operator +(Point other) {
    return Point(x + other.x, y + other.y);
  }

  Point operator -(Point other) {
    return Point(x - other.x, y - other.y);
  }

  Point operator *(int value) {
    return Point(x * value, y * value);
  }

  Point operator /(int value) {
    return Point((x / value).floor(), (y / value).floor());
  }
}

/// Get Manhathan distance between 2 points
int calculateDistanceBetweenPoints(Point p1, Point p2) {
  final difference = p2 - p1;
  return difference.x.abs() + difference.y.abs();
}

/// 2D Directions
enum Direction { up, upRight, right, downRight, down, downLeft, left, upLeft }

/// Get adjacent coordinates
List<Point> getAdjacentCoordinates(Point p, {bool cardinalDirections = true, bool diagonalDirections = true}) {
  final List<Point> points = [];

  // Cardinal directions
  if (cardinalDirections) {
    points.addAll([
      getAdjacentDirectionCoordinate(p, Direction.up),
      getAdjacentDirectionCoordinate(p, Direction.right),
      getAdjacentDirectionCoordinate(p, Direction.down),
      getAdjacentDirectionCoordinate(p, Direction.left),
    ]);
  }

  // Diagonal directions
  if (diagonalDirections) {
    points.addAll([
      getAdjacentDirectionCoordinate(p, Direction.upRight),
      getAdjacentDirectionCoordinate(p, Direction.downRight),
      getAdjacentDirectionCoordinate(p, Direction.downLeft),
      getAdjacentDirectionCoordinate(p, Direction.upLeft),
    ]);
  }

  return points;
}

/// Get adjacent coordinate in direction
Point getAdjacentDirectionCoordinate(Point p, Direction direction) {
  switch (direction) {
    case Direction.up:
      {
        return Point(p.x, p.y - 1);
      }
    case Direction.upRight:
      {
        return Point(p.x + 1, p.y - 1);
      }
    case Direction.right:
      {
        return Point(p.x + 1, p.y);
      }
    case Direction.downRight:
      {
        return Point(p.x + 1, p.y + 1);
      }
    case Direction.down:
      {
        return Point(p.x, p.y + 1);
      }
    case Direction.downLeft:
      {
        return Point(p.x - 1, p.y + 1);
      }
    case Direction.left:
      {
        return Point(p.x - 1, p.y);
      }
    case Direction.upLeft:
      {
        return Point(p.x - 1, p.y - 1);
      }
  }
}

/// 2D region
typedef Region = Set<Point>;

/// 2D map
class MapGrid {
  late final int width;
  late final int height;
  late final Map<Point, String> grid;

  /// Generic constructor
  MapGrid(this.width, this.height, this.grid);

  /// Constructor to generate map from lines of characters
  MapGrid.fromLines(List<String> lines, {String emptySymbol = ''}) {
    height = lines.length;
    width = lines.first.length;
    grid = {};

    for (var y = 0; y < height; y++) {
      final line = lines[y];

      for (var x = 0; x < width; x++) {
        final symbol = line[x];
        if (symbol != emptySymbol) {
          grid.addAll({Point(x, y): symbol});
        }
      }
    }
  }

  /// Print map (should only be used with a Map of single character symbols)
  void display(
      {bool showBorder = true,
      String emptySymbol = '.',
      String borderXSymbol = '-',
      String borderYSymbol = '|',
      Map<String, AnsiPen> symbolsColorsMap = const {},
      Map<Point, AnsiPen> coordinatesColorsMap = const {}}) {
    final separatorLine = showBorder ? borderXSymbol * (width + 2) : null;

    if (showBorder) {
      print(separatorLine);
    }

    for (var y = 0; y < height; y++) {
      var line = '';

      for (var x = 0; x < width; x++) {
        final symbol = grid[Point(x, y)]?.toString() ?? emptySymbol;
        if (coordinatesColorsMap.containsKey(Point(x, y))) {
          line += coordinatesColorsMap[Point(x, y)]!(symbol);
        } else if (symbolsColorsMap.containsKey(symbol)) {
          line += symbolsColorsMap[symbol]!(symbol);
        } else {
          line += symbol;
        }
      }

      print(showBorder ? '$borderYSymbol$line$borderYSymbol' : line);
    }

    if (showBorder) {
      print(separatorLine);
    }
  }

  /// Check if coordinate is within map
  bool isCoordinateWithinMap(Point point) {
    return point >= Point(0, 0) && point < Point(width, height);
  }

  /// Check if coordinate is unmapped
  bool isEmptyCoordinate(Point point) {
    return grid[point] == null;
  }

  /// Find all the coordinates matching map symbol (excluding empty coordinates by default)
  List<Point> findSymbolCoordinates(String symbol, {bool includeEmptyCoordinates = false}) {
    if (!includeEmptyCoordinates) {
      return grid.entries.where((entry) => entry.value == symbol).map((entry) => entry.key).toList();
    }

    final List<Point> coordinates = [];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (grid[Point(x, y)] == symbol || isEmptyCoordinate(Point(x, y))) {
          coordinates.add(Point(x, y));
        }
      }
    }

    return coordinates;
  }

  /// Get all adjacent non empty coordinates
  List<Point> getAdjacentSymbolCoordinates(Point point, {bool cardinalDirections = true, bool diagonalDirections = true}) {
    return getAdjacentCoordinates(point, cardinalDirections: cardinalDirections, diagonalDirections: diagonalDirections)
        .whereNot((p) => isEmptyCoordinate(p))
        .toList();
  }

  /// Find all inner and outer regions for empty space
  ///
  /// Parameters:
  /// emptySymbols (optional): list of symbols considered empty in addition to unmapped coordinates
  /// emptyCoordinates (optional): list of coordinates to validate (instead of all coordinates for empty symbols)
  (List<Region>, List<Region>) findEmptyRegions({Set<String> emptySymbols = const {}, Set<Point>? emptyCoordinates}) {
    final unmappedTiles = findSymbolCoordinates('', includeEmptyCoordinates: true);
    final emptyTiles = emptySymbols.map((symbol) => findSymbolCoordinates(symbol)).flattened.toSet();
    emptyTiles.addAll(unmappedTiles);

    final tiles = emptyCoordinates ?? emptyTiles;
    final edgeTiles = emptyTiles.where((coordinate) {
      return (coordinate.x == 0 || coordinate.x == width - 1 || coordinate.y == 0 || coordinate.y == height - 1);
    }).toSet();

    final List<Region> tileRegions = [];
    while (tiles.isNotEmpty) {
      final currentTile = tiles.first;
      tiles.remove(currentTile);

      final Region newRegion = {currentTile};
      bool isRegionCompleted = false;
      while (!isRegionCompleted) {
        final initialRegionSize = newRegion.length;

        for (final regionTile in newRegion.toList()) {
          final adjacentTiles = getAdjacentCoordinates(regionTile).where((point) => tiles.contains(point)).toList();

          tiles.removeAll(adjacentTiles);
          newRegion.addAll(adjacentTiles);
        }

        if (newRegion.length == initialRegionSize) {
          isRegionCompleted = true;
        }
      }

      tileRegions.add(newRegion);
    }

    final innerRegions = tileRegions.where((region) => region.intersection(edgeTiles).isEmpty).toList();
    final outerRegions = tileRegions.where((region) => region.intersection(edgeTiles).isNotEmpty).toList();

    return (innerRegions, outerRegions);
  }
}
