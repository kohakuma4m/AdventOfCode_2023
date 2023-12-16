import 'dart:async';
import 'package:collection/collection.dart';
import 'package:dart_numerics/dart_numerics.dart';
import 'package:qbcps_flutter/qbcps_flutter.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final (navigationInputs, desertMap) = readMapData(lines);

    final path = ['AAA'];
    final navigationInputsIterator = navigationInputs.iterator;

    do {
      final current = path.last;
      final nextDirection = navigationInputsIterator.current;
      path.add(desertMap[current]![nextDirection]);
    } while (path.last != 'ZZZ' && navigationInputsIterator.moveNext());

    print(path.join(' --> '));
    print('-------------------');

    return path.length - 1;
  }

  Future<int> solvePart2() async {
    final (navigationInputs, desertMap) = readMapData(lines);

    final startingNodes = desertMap.keys.where(isStartingNode);
    print('Number of starting nodes: ${startingNodes.length}');

    final List<Iterator<int>> pathIterators = startingNodes.map((_) => navigationInputs.iterator).toList();
    final List<List<(int, String)>> pathsIntervals = startingNodes.map((node) => [(0, node)]).toList();

    var nbIntervals = 1;
    do {
      nbIntervals++;

      // Moving to next end node in all paths at the same time
      final List<Future<void>> promises = [];
      for (final (idx, intervals) in pathsIntervals.indexed) {
        promise() async {
          var (nbMoves, current) = intervals.last;

          do {
            nbMoves++;
            final nextDirection = pathIterators[idx].current;
            current = desertMap[current]![nextDirection];
            pathIterators[idx].moveNext();
          } while (!isEndingNode(current));

          pathsIntervals[idx].add((nbMoves, current));
        }

        promises.add(promise());
      }

      await Future.wait(promises);
    } while (nbIntervals <= 3); // Enough iterations to make sure we have a cycle...

    print('-------------------');
    for (final (idx, intervals) in pathsIntervals.indexed) {
      print('#$idx --> $intervals');
    }
    print('-------------------');

    final firstPeriods = pathsIntervals.map((intervals) => intervals[1].$1 - intervals.first.$1).toList();
    final lastPeriods = pathsIntervals.map((intervals) => intervals.last.$1 - intervals[intervals.length - 2].$1).toList();
    final nbEndingNodes = pathsIntervals.map((intervals) => intervals.sublist(1).map((interval) => interval.$2).toSet().length);
    if (lastPeriods.indexed.any((item) => item.$2 != firstPeriods[item.$1]) || nbEndingNodes.any((n) => n > 2)) {
      throw 'No cyclic pattern !';
    }
    final periods = lastPeriods.sorted((a, b) => a - b);

    print('Periods: $periods');
    print('-------------------');

    // Min number of moves before all periods align (i.e: least common multiple)
    final minNbMoves = periods.reduce((lcm, current) => leastCommonMultiple(lcm, current));

    return minNbMoves;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static final RegExp mapLineDataRegex = RegExp(r'(?<current>\w{3}) = \((?<left>\w{3}), (?<right>\w{3})\)');

  static (NavigationInputs, DesertMap) readMapData(List<String> lines) {
    final navigationInputs = CircularArray(lines.first.split('').map((input) => inputTypes.indexOf(input)));

    final DesertMap desertMap = {};
    for (final line in lines.sublist(2)) {
      final match = mapLineDataRegex.allMatches(line).first;
      desertMap.addAll({
        match.namedGroup('current')!: [match.namedGroup('left')!, match.namedGroup('right')!]
      });
    }

    return (navigationInputs, desertMap);
  }

  static bool isStartingNode(String node) {
    return node.endsWith('A');
  }

  static bool isEndingNode(String node) {
    return node.endsWith('Z');
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

const inputTypes = ['L', 'R'];

typedef NavigationInputs = CircularArray<int>;
typedef DesertMap = Map<String, List<String>>;
