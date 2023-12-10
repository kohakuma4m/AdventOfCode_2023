import 'dart:math';
import 'package:collection/collection.dart';

class Solution {
  List<String> lines = [];

  Solution(this.lines);

  int solvePart1() {
    final almanac = readAlmanac<SeedValue>(lines);
    printAlmanac(almanac);

    final SeedsMap seedsMap = getSeedsMap(almanac);

    print('-------------------');
    printSeedsMap(seedsMap);
    print('-------------------');

    return seedsMap.values.map((value) => value['location']!).min;
  }

  int solvePart2() {
    final almanac = readAlmanac<SeedRange>(lines);

    return findMinValidLocation(almanac);
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static final RegExp typeMapLabel = RegExp(r'(\w+)-to-(\w+) map:');
  static final RegExp typeMapEntry = RegExp(r'(\d+) (\d+) (\d+)');

  static Almanac<T> readAlmanac<T>(List<String> lines) {
    final seedsData = lines.first.replaceAll('seeds: ', '').split(' ').map((n) => int.parse(n)).toList();

    dynamic seeds;
    if (T == SeedValue) {
      seeds = seedsData;
    } else if (T == SeedRange) {
      seeds = seedsData.slices(2).map((range) => (start: range[0], nbSeeds: range[1])).toList();
      (seeds as List<SeedRange>).sort((a, b) => a.start - b.start);
    }

    final almanac = Almanac<T>(seeds, {});

    late String currentTypeMapSource;
    late String currentTypeMapDestination;
    for (var i = 1; i < lines.length; i++) {
      if (lines[i].isEmpty) {
        continue;
      }

      if (lines[i].contains('-to-')) {
        final matchedGroups = typeMapLabel.allMatches(lines[i]).first.groups([1, 2]);
        [currentTypeMapSource, currentTypeMapDestination] = matchedGroups.map((m) => m.toString()).toList();
        almanac.typeMaps.addAll({ (source: currentTypeMapSource, destination: currentTypeMapDestination): {} });
        continue;
      }

      final matchedGroups = typeMapEntry.allMatches(lines[i]).first.groups([1, 2, 3]);
      final [destinationNumber, sourceNumber, nbMappedValues] = matchedGroups.map((n) => int.parse(n!)).toList();

      final currentTypeMap = almanac.typeMaps[(source: currentTypeMapSource, destination: currentTypeMapDestination)];
      currentTypeMap?.addAll({ (source: sourceNumber, destination: destinationNumber, nbMappedValues: nbMappedValues) });
    }

    return almanac;
  }

  static void printAlmanac<T>(Almanac<T> almanac) {
    if (T == SeedValue) {
      print('seeds: ${almanac.seeds.join(' ')}');
    } else if (T == SeedRange) {
      print('seed ranges: ${(almanac.seeds as List<SeedRange>).map((range) => '(${range.start}, ${range.nbSeeds})').join(', ')}');
    }

    for (final entry in almanac.typeMaps.entries) {
      final (:source, :destination) = entry.key;
      print('\n$source-to-$destination map:');

      final maxValue = entry.value.expand((typeRange) => [typeRange.source, typeRange.destination, typeRange.nbMappedValues]).max;
      final padLength = maxValue.toString().length;

      for (final typeRange in entry.value.sorted((a, b) => a.source - b.source)) {
        print('${typeRange.source.toString().padLeft(padLength)} --> ${typeRange.destination.toString().padLeft(padLength)} (${typeRange.nbMappedValues.toString().padLeft(padLength)})');
      }
    }
  }

  static SeedsMap getSeedsMap(Almanac<int> almanac) {
    final SeedsMap seedsMap = {};

    for (final seed in almanac.seeds) {
      final Map<String, int> seedMap = {};

      var currentValue = seed;
      var currentSource = 'seed';
      var currentDestination = '';
      while (currentDestination != 'location') {
        final typeMapKey = almanac.getTypeMapKeyForSource(currentSource)!;
        currentDestination = typeMapKey.destination;
        currentValue = almanac.getMappedValue(currentSource, currentDestination, currentValue);
        currentSource = currentDestination;
        seedMap.addAll({ currentDestination: currentValue });
      }

      seedsMap.addAll({ seed: seedMap });
    }

    return seedsMap;
  }

  static void printSeedsMap(SeedsMap seedsMap) {
    final maxValue = seedsMap.entries.expand((entry) => [entry.key, ...entry.value.values]).max;
    final padLength = maxValue.toString().length;

    for (final entry in seedsMap.entries) {
      print('seed ${entry.key.toString().padLeft(padLength)}, ${entry.value.entries.map((entry) => '${entry.key} ${entry.value.toString().padLeft(padLength)}').join(', ')}');
    }
  }

  ///==============================================================================================================================
  /// Brute force solution: testing all possible location values one by one starting at zero until we find a valid matching seed
  /// Find solution in 3:54 (at 100 000 values / second)
  ///
  /// TODO: Map seedRange to locationRange instead and find min location directly...
  ///==============================================================================================================================
  static int findMinValidLocation(Almanac<SeedRange> almanac, {bool printLogs = true, int printInterval = 100000}) {
    var locationValue = 0;
    do {
      // Finding matching seed value
      var currentValue = locationValue;
      var currentDestination = 'location';
      var currentSource = '';
      while (currentSource != 'seed') {
        final typeMapKey = almanac.getTypeMapKeyForDestination(currentDestination)!;
        currentSource = typeMapKey.source;
        currentValue = almanac.getReversedMappedValue(currentDestination, currentSource, currentValue);
        currentDestination = currentSource;
      }

      if (printLogs && locationValue % printInterval == 0) {
        print('Validating location value $locationValue --> seed value $currentValue');
      }

      final seedRange = almanac.seeds.firstWhereOrNull((seedRange) => currentValue.isInRange(seedRange.start, seedRange.start + seedRange.nbSeeds));
      if (seedRange != null) {
        if (printLogs) {
          print('Found matching seed range: [${seedRange.start}, ${seedRange.start + seedRange.nbSeeds - 1}]');
          print('-------------------');
        }

        return locationValue;
      }

      locationValue++;
    } while (true);
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

typedef SeedValue = int;
typedef SeedRange = ({int start, int nbSeeds});
typedef LocationRange = ({int start, int nbValues});
typedef TypeMapKey = ({String source, String destination});
typedef TypeMapRange = ({int source, int destination, int nbMappedValues});
typedef SeedMap = Map<String, int>;
typedef SeedsMap = Map<int, SeedMap>;

class Almanac<T> {
  final List<T> seeds;
  final Map<TypeMapKey, Set<TypeMapRange>> typeMaps;

  Almanac(this.seeds, this.typeMaps);

  TypeMapKey? getTypeMapKeyForSource(String source) {
    return typeMaps.keys.firstWhere((key) => key.source == source);
  }

  TypeMapKey? getTypeMapKeyForDestination(String destination) {
    return typeMaps.keys.firstWhere((key) => key.destination == destination);
  }

  int getMappedValue(String source, String destination, int sourceValue) {
    final typeMap = typeMaps[(source: source, destination: destination)]!;
    try {
      final typeMapRange = typeMap.firstWhere((typeRange) => sourceValue.isInRange(typeRange.source, typeRange.source + typeRange.nbMappedValues));
      return typeMapRange.destination + (sourceValue - typeMapRange.source);
    } catch(_) {
      return sourceValue; // Missing values are unmapped
    }
  }

  int getReversedMappedValue(String destination, String source, int destinationValue) {
    final typeMap = typeMaps[(source: source, destination: destination)]!;
    try {
      final typeMapRange = typeMap.firstWhere((typeRange) => destinationValue.isInRange(typeRange.destination, typeRange.destination + typeRange.nbMappedValues));
      return typeMapRange.source + (destinationValue - typeMapRange.destination);
    } catch(_) {
      return destinationValue; // Missing values are unmapped
    }
  }
}

extension Range on int {
  bool isInRange(int min, num max) {
    return min <= this && this < max;
  }
}
