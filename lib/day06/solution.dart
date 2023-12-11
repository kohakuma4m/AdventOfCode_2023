import 'package:collection/collection.dart';

class Solution {
  List<String> lines = [];

  Solution(this.lines);

  int solvePart1() {
    final races = readRaceData(lines);
    final racesWinningStrategies = races.map(getRaceWinningStrategies).toList();
    printRaceStrategies(races, racesWinningStrategies);

    return racesWinningStrategies.fold(1, (total, winningStrategies) => total * winningStrategies.length);
  }

  int solvePart2() {
    final races = readRaceData(lines, singleRaceData: true);
    final racesWinningStrategies = races.map(getRaceWinningStrategies).toList();
    printRaceStrategies(races, racesWinningStrategies, printAllStrategies: false, printOptimalStrategy: false);

    return racesWinningStrategies.fold(1, (total, winningStrategies) => total * winningStrategies.length);
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static final RegExp numberGroups = RegExp(r'(\d+) map:');

  static List<Race> readRaceData(List<String> lines, {bool singleRaceData = false}) {
    final durations = lines.first.split(':').last.split(' ').where((n) => n.isNotEmpty).map((n) => int.parse(n)).toList();
    final maxDistances = lines.last.split(':').last.split(' ').where((n) => n.isNotEmpty).map((n) => int.parse(n)).toList();

    if (singleRaceData) {
      return [(duration: int.parse(durations.join('')), maxDistance: int.parse(maxDistances.join('')))];
    }

    final List<Race> races = [];
    for (var i = 0; i < durations.length; i++) {
      races.add((duration: durations[i], maxDistance: maxDistances[i]));
    }

    return races;
  }

  static List<RaceStrategy> getRaceWinningStrategies(Race race) {
    final List<RaceStrategy> raceStrategies = [];

    for (var i = 1; i < race.duration - 1; i++) {
      final [boatSpeed, remainingRaceTime] = [i, race.duration - i];
      final boatDistance = boatSpeed * remainingRaceTime;
      if (boatDistance > race.maxDistance) {
        raceStrategies.add((holdButtonDuration: i, maxDistance: boatDistance));
      }
    }

    return raceStrategies;
  }

  static void printRaceStrategies(List<Race> races, List<List<RaceStrategy>> racesStrategies,
      {bool printAllStrategies = true, bool printOptimalStrategy = true}) {
    final raceNumberPadding = races.length.toString().length;
    final raceDurationPadding = races.map((race) => race.duration).max.toString().length;
    final raceDistancePadding = races.map((race) => race.maxDistance).max.toString().length;

    for (final (idx, race) in races.indexed) {
      final formattedRaceNumber = (idx + 1).toString().padLeft(raceNumberPadding);
      final formattedRaceDuration = race.duration.toString().padLeft(raceDurationPadding);
      final formattedRaceDistance = race.maxDistance.toString().padLeft(raceDistancePadding);
      final raceString = '#$formattedRaceNumber (duration: $formattedRaceDuration, maxDistance: $formattedRaceDistance)';
      print('Strategies for race $raceString (${racesStrategies[idx].length} winning strategies)');
      if (printAllStrategies) {
        print('-------------------');
        print('[${racesStrategies[idx].map((raceStrategy) => '(${raceStrategy.holdButtonDuration} --> ${raceStrategy.maxDistance})').join(', ')}]');
        print('-------------------');
      }
      if (printOptimalStrategy) {
        final optimalBestRecordStrategy = findOptimalBestRecordStrategy(racesStrategies[idx]);
        print('Optimal best record strategy: (${optimalBestRecordStrategy.holdButtonDuration} --> ${optimalBestRecordStrategy.maxDistance})');
        print('-------------------');
      }
    }
  }

  static RaceStrategy findOptimalBestRecordStrategy(List<RaceStrategy> raceStrategies) {
    // First strategy with max distance and least amount of time holding button
    return raceStrategies.sorted((a, b) {
      if (a.maxDistance == b.maxDistance) {
        return a.holdButtonDuration - b.holdButtonDuration;
      }

      return b.maxDistance - a.maxDistance;
    }).first;
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

typedef Race = ({int duration, int maxDistance});
typedef RaceStrategy = ({int holdButtonDuration, int maxDistance});
