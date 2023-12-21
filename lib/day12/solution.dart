import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final damagedRecords = readDamagedRecords(lines);

    return solve(damagedRecords);
  }

  Future<int> solvePart2() async {
    final damagedRecords = readDamagedRecords(lines, unfold: true);

    return solve(damagedRecords);
  }

  Future<int> solve(List<SpringRecord> damagedRecords) async {
    final paddingIndex = damagedRecords.length.toString().length;
    final List<List<String>> possibleRecordArrangements = [];
    for (final (idx, springRecord) in damagedRecords.indexed) {
      final arrangements = findPossibleRecordArrangements(springRecord);

      final recordString = '${springRecord.record} ${springRecord.damagedGroups}';
      print('Record #${(idx + 1).toString().padLeft(paddingIndex)}: ${arrangements.length.toString().padRight(4)} --> $recordString');

      possibleRecordArrangements.add(arrangements);
    }
    print('-------------------');

    return possibleRecordArrangements.fold<int>(0, (total, arrangements) => total + arrangements.length);
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<SpringRecord> readDamagedRecords(List<String> lines, {bool unfold = false}) {
    final springRecords = lines.map((line) {
      final [record, damagedGroups] = line.split(' ');
      return (record: record, damagedGroups: damagedGroups.split(',').map((g) => int.parse(g)).toList());
    });

    if (!unfold) {
      return springRecords.toList();
    }

    return springRecords.map((item) => (
      record: List.filled(5, item.record).join(springSymbols[SpringState.unknown]!),
      damagedGroups: List.filled(5, item.damagedGroups).flattened.toList()
    )).toList();
  }

  ///=====================================================================================
  /// Iterative solution without cache
  ///
  /// Solve part 1 in about 3 seconds, but cannot even solve example input for part 2...
  ///=====================================================================================
  static List<String> findPossibleRecordArrangements(SpringRecord damagedRecord) {
    final List<String> arrangements = [];

    // Finding all possible arrangements with a recursive loop
    final arrangementsToValidate = [(current: damagedRecord.record, startIndex: 0, remainingGroupLengths: damagedRecord.damagedGroups)];
    while (arrangementsToValidate.isNotEmpty) {
      final (:current, :startIndex, :remainingGroupLengths) = arrangementsToValidate.removeAt(0);

      final remainingSeparateGroups = current.substring(startIndex).split(springSymbols[SpringState.operational]!).where((group) => group.isNotEmpty).toList();
      if (remainingSeparateGroups.fold(0, (total, group) => total + group.length) < remainingGroupLengths.sum) {
        // Invalid arrangement (not enough unknown left for all damaged spring)
        continue;
      }

      if (remainingGroupLengths.isEmpty || !current.contains(springSymbols[SpringState.unknown]!)) {
        // No remaining groups to assign or no symbol left to decode...
        final updatedRecord = current.replaceAll(springSymbols[SpringState.unknown]!, springSymbols[SpringState.operational]!);
        final separateGroups = updatedRecord.split(springSymbols[SpringState.operational]!).where((group) => group.isNotEmpty).toList();
        if (
          separateGroups.length == damagedRecord.damagedGroups.length
          && separateGroups.indexed.every((element) => element.$2.length == damagedRecord.damagedGroups[element.$1])
        ) {
          // Valid arrangement (invalid otherwise)
          arrangements.add(updatedRecord);
        }
        continue;
      }

      final groupLengthToMatch = remainingGroupLengths.first;

      searchLoop: // Loop to find first non operational symbol
      for (var i = startIndex; i < current.length; i++) {
        switch (getSprintState(current[i])) {
          case SpringState.operational: {
            continue; // Skipping
          }
          case SpringState.damaged: {
            final start = i;
            final end = i + groupLengthToMatch;
            if (
              end > current.length
              || current.substring(start, end).contains(springSymbols[SpringState.operational]!)
              || (end < current.length && getSprintState(current[end]) == SpringState.damaged)
            ) {
              // Invalid arrangement (not enough space left for damaged group in current separate group)
              break searchLoop;
            }

            var match = current[start];
            while (match.length < groupLengthToMatch) {
              match += springSymbols[SpringState.damaged]!;
            }
            if (end + 1 < current.length) {
              // Adding delimiter with next group
              match += springSymbols[SpringState.operational]!;

              if (current[end] == springSymbols[SpringState.unknown] && remainingGroupLengths.length == 1) {
                // Filling in remaining connected unknowns in current group...
                while (start + match.length < current.length && current[start + match.length] == springSymbols[SpringState.unknown]) {
                  match += springSymbols[SpringState.operational]!;
                }
              }
            }

            // Updating record for next iteration
            var updatedRecord = current.replaceRange(start, start + match.length, match);
            arrangementsToValidate.add((current: updatedRecord, startIndex: start + match.length, remainingGroupLengths: remainingGroupLengths.slice(1)));
            break searchLoop;
          }
          case SpringState.unknown: {
            final start = i;
            final currentGroupLength = current.substring(start).indexOf(springSymbols[SpringState.operational]!);
            if (
              currentGroupLength > 0
              && currentGroupLength < remainingGroupLengths.first
              && !current.substring(start, start + currentGroupLength).contains(springSymbols[SpringState.damaged]!)
            ) {
              // Not enough room to fit next damaged group of springs
              final updatedRecord = current.replaceRange(start, start + currentGroupLength, springSymbols[SpringState.operational]! * currentGroupLength);
              arrangementsToValidate.add((current: updatedRecord, startIndex: start + currentGroupLength, remainingGroupLengths: remainingGroupLengths));
              break searchLoop;
            }

            // Trying both possibilities in next iterations
            final possibleRecord1 = current.replaceRange(i, i + 1, springSymbols[SpringState.damaged]!);
            final possibleRecord2 = current.replaceRange(i, i + 1, springSymbols[SpringState.operational]!);

            arrangementsToValidate.addAll([
              (current: possibleRecord1, startIndex: i, remainingGroupLengths: remainingGroupLengths),
              (current: possibleRecord2, startIndex: i, remainingGroupLengths: remainingGroupLengths),
            ]);
            break searchLoop;
          }
        }
      }
    }

    return arrangements;
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

typedef SpringRecord = ({String record, List<int> damagedGroups});

enum SpringState { operational, damaged, unknown }

const springSymbols = {
  SpringState.operational: '.',
  SpringState.damaged: '#',
  SpringState.unknown: '?'
};

SpringState getSprintState(String symbol) {
  return springSymbols.keys.firstWhere((key) => springSymbols[key] == symbol);
}

