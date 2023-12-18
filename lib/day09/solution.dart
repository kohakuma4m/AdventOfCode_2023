import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final data = readData(lines);

    final nextHistoryValues = data
        .map((values) => generateSequencesFromHistory(values))
        .map((sequences) => sequences.map((s) => s.last).toList())
        .map((lastSequenceValues) => lastSequenceValues.reversed.reduce((value, previous) => value + previous))
        .toList();

    print('Next values: $nextHistoryValues');
    print('-------------------');

    return nextHistoryValues.sum;
  }

  Future<int> solvePart2() async {
    final data = readData(lines);

    final previousHistoryValues = data
        .map((values) => generateSequencesFromHistory(values))
        .map((sequences) => sequences.map((s) => s.first).toList())
        .map((firstSequenceValues) => firstSequenceValues.reversed.reduce((value, previous) => previous - value))
        .toList();

    print('Previous values: $previousHistoryValues');
    print('-------------------');

    return previousHistoryValues.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<History> readData(List<String> lines) {
    final List<History> data = [];

    for (final line in lines) {
      final values = line.split(' ').map((n) => int.parse(n)).toList();
      data.add(values);
    }

    return data;
  }

  static Sequences generateSequencesFromHistory(History values) {
    final sequences = [values];

    do {
      final previousSequence = sequences.last;
      final List<int> nextSequence = [];
      for (var i = 0; i < previousSequence.length - 1; i++) {
        nextSequence.add(previousSequence[i + 1] - previousSequence[i]);
      }
      sequences.add(nextSequence);
    } while (sequences.last.any((v) => v != 0));

    return sequences;
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

typedef History = List<int>;
typedef Sequences = List<List<int>>;
