import 'package:collection/collection.dart';
import 'package:memoized/memoized.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final damagedRecords = readDamagedRecords(lines);

    final List<List<String>> possibleRecordArrangements = [];

    final paddingIndex = damagedRecords.length.toString().length;
    for (final (idx, springRecord) in damagedRecords.indexed) {
      final arrangements = findPossibleRecordArrangements(springRecord);

      print('Record #${(idx + 1).toString().padLeft(paddingIndex)}: ${arrangements.length}');

      possibleRecordArrangements.add(arrangements);
    }
    print('-------------------');

    return possibleRecordArrangements.fold<int>(0, (total, arrangements) => total + arrangements.length);
  }

  Future<int> solvePart2() async {
    final damagedRecords = readDamagedRecords(lines, unfold: true);

    final List<int> nbPossibleRecordArrangements = [];

    final paddingIndex = damagedRecords.length.toString().length;
    for (final (idx, springRecord) in damagedRecords.indexed) {
      final nbArrangements = findNbPossibleRecordArrangements(springRecord);

      print('Record #${(idx + 1).toString().padLeft(paddingIndex)}: $nbArrangements');

      nbPossibleRecordArrangements.add(nbArrangements);
    }
    print('-------------------');

    return nbPossibleRecordArrangements.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<SpringRecord> readDamagedRecords(List<String> lines, {bool unfold = false}) {
    final springRecords = lines.map((line) {
      final [record, damagedGroups] = line.split(' ');
      return SpringRecord(record, damagedGroups.split(',').map((g) => int.parse(g)).toList());
    });

    if (!unfold) {
      return springRecords.toList();
    }

    return springRecords.map((item) => SpringRecord(
      List.filled(5, item.record).join(springSymbols[SpringState.unknown]!),
      List.filled(5, item.groups).flattened.toList()
    )).toList();
  }

  ///============================================================================================
  /// Iterative solution without cache that find all possible arrangements
  ///
  /// Part 1: solve input in about 1 second
  /// Part 2: solve example input in around 10 seconds, but far too slow for real input
  ///
  /// Note: Using DFS with List.removeLast() [O(1)] instead of BFS with List.removeAt(0) [O(n)]
  ///       (with BFS, even example input is far too slow for part 2...)
  ///============================================================================================
  static List<String> findPossibleRecordArrangements(SpringRecord springRecord) {
    final List<String> arrangements = [];

    // Finding all possible arrangements with a recursive loop
    final arrangementsToValidate = [(record: springRecord.record, start: 0, groups: springRecord.groups)];
    while (arrangementsToValidate.isNotEmpty) {
      final (:record, :start, :groups) = arrangementsToValidate.removeLast();
      final currentRecord = record.substring(start);

      if (groups.isEmpty) {
        // Valid only if there is no remaining unmatched damaged spring...
        if (!currentRecord.contains(springSymbols[SpringState.damaged]!)) {
          arrangements.add(record.replaceAll(springSymbols[SpringState.unknown]!, springSymbols[SpringState.operational]!));
        }

        continue;
      }

      final remainingGroups = currentRecord.split(springSymbols[SpringState.operational]!).where((group) => group.isNotEmpty).toList();
      if (remainingGroups.fold(0, (total, group) => total + group.length) < groups.sum) {
        // Invalid since there is not enough space left for all damaged springs
        continue;
      }

      // Looking at next character
      switch (getSprintState(record[start])) {
        case SpringState.operational: {
          // Skipping to next group directly
          final nextGroupStartIndex = start + currentRecord.indexOf(remainingGroups.first);
          arrangementsToValidate.add((record: record, start: nextGroupStartIndex, groups: groups));
          continue;
        }
        case SpringState.unknown: {
          // Trying both possibilities in next iterations
          arrangementsToValidate.addAll([
            (record: record.replaceRange(start, start + 1, springSymbols[SpringState.damaged]!), start: start, groups: groups),
            (record: record.replaceRange(start, start + 1, springSymbols[SpringState.operational]!), start: start, groups: groups),
          ]);
          continue;
        }
        case SpringState.damaged: {
          final groupLengthToMatch = groups.first;
          if (remainingGroups.first.length < groupLengthToMatch) {
            // Not enough space left to fit damaged springs group in record remaining group
            continue;
          }

          if (start + groupLengthToMatch < record.length && record[start + groupLengthToMatch] == springSymbols[SpringState.damaged]!) {
            // Can't fit damaged springs group before next damaged springs group
            continue;
          }

          // Skipping to next damaged group
          if (start + groupLengthToMatch == record.length) {
            final updatedRecord = record
              .replaceRange(start, start + groupLengthToMatch, springSymbols[SpringState.damaged]! * groupLengthToMatch);
            arrangementsToValidate.add((record: updatedRecord, start: start + groupLengthToMatch, groups: groups.slice(1)));
          } else {
            final updatedRecord = record
              .replaceRange(start, start + groupLengthToMatch, springSymbols[SpringState.damaged]! * groupLengthToMatch)
              .replaceRange(start + groupLengthToMatch, start + groupLengthToMatch + 1, springSymbols[SpringState.operational]!);
            arrangementsToValidate.add((record: updatedRecord, start: start + groupLengthToMatch + 1, groups: groups.slice(1)));
          }
        }
      }
    }

    return arrangements;
  }

  ///============================================================================================
  /// Recursive solution with cache that only find number of possible arrangements
  ///
  /// Solve part 1 in about 1 second
  /// Solve part 2 in about 7 seconds (far too slow without cache...)
  ///============================================================================================
  static int findNbPossibleRecordArrangements(SpringRecord springRecord, {int cacheSize = 256}) {
    // Cache
    late final Memoized1<int, SpringRecord> findNbPossibleRecordArrangementsWithCache;
    findNbPossibleRecordArrangementsWithCache = Memoized1((SpringRecord springRecord) {
      final (record, groups) = (springRecord.record, springRecord.groups);

      if (groups.isEmpty) {
        // Valid only if there is no remaining unmatched damaged spring...
        return !record.contains(springSymbols[SpringState.damaged]!) ? 1 : 0;
      }

      final remainingGroups = record.split(springSymbols[SpringState.operational]!).where((group) => group.isNotEmpty).toList();
      if (remainingGroups.fold(0, (total, group) => total + group.length) < groups.sum) {
        // Invalid since there is not enough space left for all damaged springs
        return 0;
      }

      // Looking at next character
      switch (getSprintState(record[0])) {
        case SpringState.operational: {
          // Skipping to next group directly
          final nextGroupStart = record.indexOf(remainingGroups.first);
          return findNbPossibleRecordArrangementsWithCache(SpringRecord(record.substring(nextGroupStart), groups));
        }
        case SpringState.unknown: {
          // Adding number of arrangements for both possibilities
          return findNbPossibleRecordArrangementsWithCache(SpringRecord(record.replaceRange(0, 1, springSymbols[SpringState.operational]!), groups))
            + findNbPossibleRecordArrangementsWithCache(SpringRecord(record.replaceRange(0, 1, springSymbols[SpringState.damaged]!), groups));
        }
        case SpringState.damaged: {
          final groupLengthToMatch = groups.first;
          if (remainingGroups.first.length < groupLengthToMatch) {
            // Not enough space left to fit damaged springs group in record remaining group
            return 0;
          }

          if (groupLengthToMatch < record.length && record[groupLengthToMatch] == springSymbols[SpringState.damaged]!) {
            // Can't fit damaged springs group before next damaged springs group
            return 0;
          }

          // Skipping to next damaged group
          return groupLengthToMatch == record.length
            ? findNbPossibleRecordArrangementsWithCache(SpringRecord(record.substring(groupLengthToMatch), groups.slice(1)))
            : findNbPossibleRecordArrangementsWithCache(SpringRecord(record.substring(groupLengthToMatch + 1), groups.slice(1)));
        }
      }
    }, capacity: cacheSize);

    return findNbPossibleRecordArrangementsWithCache(springRecord);
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum SpringState { operational, damaged, unknown }

const springSymbols = {
  SpringState.operational: '.',
  SpringState.damaged: '#',
  SpringState.unknown: '?'
};

SpringState getSprintState(String symbol) {
  return springSymbols.keys.firstWhere((key) => springSymbols[key] == symbol);
}

class SpringRecord {
  String record;
  List<int> groups;

  SpringRecord(this.record, this.groups);

  @override
  String toString() {
    return '$record [${groups.join(',')}]';
  }

  @override
  bool operator ==(Object other) {
    return other is SpringRecord
      && other.record == record
      && other.groups.join(',') == groups.join(',');
  }

  @override
  int get hashCode => toString().hashCode;
}

