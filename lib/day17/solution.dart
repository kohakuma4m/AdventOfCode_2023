import 'package:collection/collection.dart';

import 'package:app/map.dart';
import 'package:progress_bar/progress_bar.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final map = HeatLossMap.fromLines(lines);

    final path = findOptimalPath(map)!;
    map.displayPath(path, overlay: false);
    print('Found optimal path of length ${path.length}');
    print('-------------------');

    return getPathHeatLoss(map, path);
  }

  Future<int> solvePart2() async {
    final map = HeatLossMap.fromLines(lines);

    final path = findOptimalPath(map, minNbStepsInSameDirection: 4, maxNbStepsInSameDirection: 10)!;
    map.displayPath(path, overlay: false);
    print('Found optimal path of length ${path.length}');
    print('-------------------');

    return getPathHeatLoss(map, path);
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  ///============================================================================================
  /// Dijkstra's solution priorizing paths with minimum heat loss closest to goal
  ///
  /// Returns the first optimal path found... (Finding all optimal paths does not reduce search space fast enough...)
  ///
  /// Part 1: find the optimal path in about 22 seconds
  /// Part 2: find the optimal path in about 80 seconds
  ///============================================================================================
  static Path? findOptimalPath(HeatLossMap map, {Point? start, Point? goal, int minNbStepsInSameDirection = 1, int maxNbStepsInSameDirection = 3}) {
    assert(maxNbStepsInSameDirection > minNbStepsInSameDirection, 'Invalid params: maxNbStepsInSameDirection > minNbStepsInSameDirection is not true!');

    final startingPoint = start ?? Point(0, 0);
    final destinationPoint = goal ?? Point(map.width - 1, map.height - 1);

    // Pre-computing all distances to the end for sorting
    final distancesToGoalMap = Map.fromEntries(map.grid.keys.map((point) => MapEntry(point, calculateDistanceBetweenPoints(point, destinationPoint))));

    // Priority queue to sort next paths to process more easily
    final HeapPriorityQueue<({Path path, int heatLoss})> pathsToProcess = HeapPriorityQueue((a, b) {
      if (a.heatLoss != b.heatLoss) {
        return a.heatLoss - b.heatLoss;
      }

      final distanceToGoalA = distancesToGoalMap[a.path.last.coordinate]!;
      final distanceToGoalB = distancesToGoalMap[b.path.last.coordinate]!;

      if (distanceToGoalA != distanceToGoalB) {
        return distanceToGoalA - distanceToGoalB;
      }

      return a.path.length - b.path.length;
    });
    for (final initialStep in map.getNextPossibleSteps(startingPoint, null)) {
      pathsToProcess.add((path: [(coordinate: startingPoint, direction: initialStep.direction)], heatLoss: 0));
    }

    // Visited states
    final Set<({Point coordinate, Direction direction, int nbStepsInCurrentDirection})> visistedStates = {};

    // Progress bar
    final maxNbStatesToVisit = (map.width * map.height) * 4 * maxNbStepsInSameDirection;
    final progressBar = ProgressBar('Finding optimal path... [:bar] :percent :elapsed', total: maxNbStatesToVisit, width: 100);

    Path? optimalPath;
    while (pathsToProcess.isNotEmpty) {
      final current = pathsToProcess.removeFirst();
      final currentPath = current.path;
      final previousStep = currentPath.last;
      final currentCoordinate = getAdjacentDirectionCoordinate(previousStep.coordinate, previousStep.direction);
      final currentHeatLoss = current.heatLoss + map.getHeatLoss(currentCoordinate);
      final nbStepsInCurrentDirection = getNbStepsInCurrentDirection(currentPath);

      final visistedStatesKey = (coordinate: currentCoordinate, direction: previousStep.direction, nbStepsInCurrentDirection: nbStepsInCurrentDirection);
      if (visistedStates.contains(visistedStatesKey)) {
        continue; // Already visited this node state with a better path
      } else {
        visistedStates.add(visistedStatesKey);
        progressBar.tick();
      }

      if (currentCoordinate == destinationPoint) {
        if (nbStepsInCurrentDirection < minNbStepsInSameDirection) {
          continue; // Cannot stop at the end from this path direction...
        }

        // Goal reached
        optimalPath = [...currentPath, (coordinate: currentCoordinate, direction: previousStep.direction)];
        break;
      }

      // Getting next possible steps
      final nextPossibleSteps = map.getNextPossibleSteps(currentCoordinate, previousStep.direction);
      if (nbStepsInCurrentDirection >= maxNbStepsInSameDirection) {
        // Cannot continue in current direction
        nextPossibleSteps.removeWhere((nextStep) => nextStep.direction == previousStep.direction);
      }
      if (nbStepsInCurrentDirection < minNbStepsInSameDirection) {
        // Cannot turn yet
        nextPossibleSteps.removeWhere((nextStep) => nextStep.direction != previousStep.direction);
      }

      for (final nextStep in nextPossibleSteps) {
        final newPath = [...currentPath, (coordinate: currentCoordinate, direction: nextStep.direction)];
        pathsToProcess.add((path: newPath, heatLoss: currentHeatLoss));
      }
    }

    // Progress complete
    progressBar.update(1);

    return optimalPath;
  }

  static int getPathHeatLoss(HeatLossMap map, Path path) {
    return path.sublist(1).map((step) => map.getHeatLoss(step.coordinate)).sum;
  }

  static int getNbStepsInCurrentDirection(Path currentPath) {
    return currentPath.reversed.takeWhile((step) => step.direction == currentPath.last.direction).length;
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

class HeatLossMap extends MapGrid {
  final Map<Point, int> _heatValuesMap = {};
  final Map<(Point, Direction?), List<Step>> _nextPossibleStepsMap = {};

  HeatLossMap.fromLines(super.lines) : super.fromLines() {
    // Parsing all number values
    _heatValuesMap.addEntries(super.grid.entries.map((entry) => MapEntry(entry.key, int.parse(entry.value))));

    // Mapping all next direction coordinates
    for (final current in super.grid.keys) {
      final [up, right, down, left] = getAdjacentCoordinates(current, cardinalDirections: true).take(4).toList();

      _nextPossibleStepsMap.addAll({
        (current, null): [
          (coordinate: up, direction: Direction.up),
          (coordinate: right, direction: Direction.right),
          (coordinate: down, direction: Direction.down),
          (coordinate: left, direction: Direction.left)
        ].where((nextStep) => super.isCoordinateWithinMap(nextStep.coordinate)).toList()
      });
      _nextPossibleStepsMap.addAll({
        (current, Direction.up): [
          (coordinate: up, direction: Direction.up),
          (coordinate: left, direction: Direction.left),
          (coordinate: right, direction: Direction.right)
        ].where((nextStep) => super.isCoordinateWithinMap(nextStep.coordinate)).toList()
      });
      _nextPossibleStepsMap.addAll({
        (current, Direction.right): [
          (coordinate: right, direction: Direction.right),
          (coordinate: up, direction: Direction.up),
          (coordinate: down, direction: Direction.down)
        ].where((nextStep) => super.isCoordinateWithinMap(nextStep.coordinate)).toList()
      });
      _nextPossibleStepsMap.addAll({
        (current, Direction.down): [
          (coordinate: down, direction: Direction.down),
          (coordinate: right, direction: Direction.right),
          (coordinate: left, direction: Direction.left)
        ].where((nextStep) => super.isCoordinateWithinMap(nextStep.coordinate)).toList()
      });
      _nextPossibleStepsMap.addAll({
        (current, Direction.left): [
          (coordinate: left, direction: Direction.left),
          (coordinate: down, direction: Direction.down),
          (coordinate: up, direction: Direction.up)
        ].where((nextStep) => super.isCoordinateWithinMap(nextStep.coordinate)).toList()
      });
    }
  }

  int getHeatLoss(Point coordinate) {
    return _heatValuesMap[coordinate]!;
  }

  List<Step> getNextPossibleSteps(Point coordinate, Direction? direction) {
    return [..._nextPossibleStepsMap[(coordinate, direction)]!]; // Copy to prevent modification
  }
}
