import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  int solvePart1() {
    final almanac = readAlmanac<SeedValue>(lines);
    printAlmanac(almanac);
    print('-------------------');

    final SeedsMap seedsMap = getSeedsMap(almanac);

    printSeedsMap(seedsMap);
    print('-------------------');

    return seedsMap.values.map((value) => value['location']!).min;
  }

  int solvePart2() {
    final almanac = readAlmanac<SeedRange>(lines);

    final seedLocationsMap = getSeedLocationIntervalsMap(almanac);
    printSeedLocationIntervalsMap(seedLocationsMap, sortByLocation: true);
    print('-------------------');

    // return findMinValidLocation(almanac);
    return seedLocationsMap.values.sorted((a, b) => a.start - b.start).first.start;
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

      // New map
      if (lines[i].contains('-to-')) {
        final matchedGroups = typeMapLabel.allMatches(lines[i]).first.groups([1, 2]);
        [currentTypeMapSource, currentTypeMapDestination] = matchedGroups.map((m) => m.toString()).toList();
        almanac.typeMaps.addAll({(source: currentTypeMapSource, destination: currentTypeMapDestination): {}});
        continue;
      }

      // Current map intervals
      final matchedGroups = typeMapEntry.allMatches(lines[i]).first.groups([1, 2, 3]);
      final [destinationNumber, sourceNumber, nbMappedValues] = matchedGroups.map((n) => int.parse(n!)).toList();

      final currentTypeMap = almanac.typeMaps[(source: currentTypeMapSource, destination: currentTypeMapDestination)];
      currentTypeMap?.addAll({(source: sourceNumber, destination: destinationNumber, nbMappedValues: nbMappedValues)});
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
        print(
            '${typeRange.source.toString().padLeft(padLength)} --> ${typeRange.destination.toString().padLeft(padLength)} (${typeRange.nbMappedValues.toString().padLeft(padLength)})');
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
        seedMap.addAll({currentDestination: currentValue});
      }

      seedsMap.addAll({seed: seedMap});
    }

    return seedsMap;
  }

  static void printSeedsMap(SeedsMap seedsMap) {
    final maxValue = seedsMap.entries.expand((entry) => [entry.key, ...entry.value.values]).max;
    final padLength = maxValue.toString().length;

    for (final entry in seedsMap.entries) {
      final keyString = entry.key.toString().padLeft(padLength);
      print('seed $keyString, ${entry.value.entries.map((entry) => '${entry.key} ${entry.value.toString().padLeft(padLength)}').join(', ')}');
    }
  }

  ///==============================================================================================================================
  /// Brute force solution: Testing all possible location values one by one starting at zero until we find a valid matching seed
  ///                       (TODO: find way to skip values with binary search or something else ???)
  ///
  /// Find solution in 03:54 (mm:ss) for my input (at about 100 000 values / second)
  ///==============================================================================================================================
  static int findMinValidLocation(Almanac<SeedRange> almanac, {bool printLogs = true, int printInterval = 100000}) {
    if (printLogs) {
      print('-------------------');
    }

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

  ///==============================================================================================================================
  /// Optimized solution: Mapping all seed intervals directly to location intervals, removing intermediate map layers
  ///                     Seed intervals are broken in sub intervals so all values are mapped in non overlapping intervals
  ///
  ///                     At the end, since all seed values are mapped, so we have every possible valid location intervals
  ///                     (we can then take the min location interval start value directly)
  ///
  /// Find solution in 00:01 (mm:ss) only (quasi instantaneous)
  ///==============================================================================================================================
  static SeedLocationIntervalsMap getSeedLocationIntervalsMap(Almanac<SeedRange> almanac) {
    final SeedLocationIntervalsMap seedLocationsMap = {};

    final intervalsToMap = almanac.seeds.map((seedRange) {
      return (
        source: 'seed',
        seedInterval: (start: seedRange.start, end: seedRange.start + seedRange.nbSeeds),
        currentInterval: (start: seedRange.start, end: seedRange.start + seedRange.nbSeeds),
      );
    }).toList();

    do {
      final (:source, :seedInterval, :currentInterval) = intervalsToMap.removeLast();
      final nbSourceValues = seedInterval.end - seedInterval.start;
      final typeMapKey = almanac.getTypeMapKeyForSource(source)!;
      final destination = typeMapKey.destination;

      final mappedStart = almanac.getMappedValue(source, destination, currentInterval.start);
      final destinationIntervals = almanac.getDestinationIntervals(typeMapKey);

      final List<({String source, Interval seedInterval, Interval currentInterval})> newIntervals = [];
      final matchingInterval = destinationIntervals.firstWhereOrNull((interval) => mappedStart.isInRange(interval.start, interval.end));
      if (matchingInterval != null) {
        final nbIntersectingValues = matchingInterval.end - mappedStart;
        if (nbIntersectingValues > nbSourceValues) {
          // Keeping fully mapped interval intact
          newIntervals.addAll([
            (
              source: destination,
              seedInterval: (start: seedInterval.start, end: seedInterval.start + nbSourceValues),
              currentInterval: (start: mappedStart, end: mappedStart + nbSourceValues)
            )
          ]);
        } else {
          // Splitting interval in two
          newIntervals.addAll([
            (
              // Mapped intersecting part
              source: destination,
              seedInterval: (start: seedInterval.start, end: seedInterval.start + nbIntersectingValues),
              currentInterval: (start: mappedStart, end: mappedStart + nbIntersectingValues)
            ),
            (
              // Remaining unmapped part (to be reprocessed as new source later since some of it could be mapped...)
              source: source,
              seedInterval: (start: seedInterval.start + nbIntersectingValues, end: seedInterval.start + nbSourceValues),
              currentInterval: (start: currentInterval.start + nbIntersectingValues, end: currentInterval.start + nbSourceValues)
            )
          ]);
        }
      } else {
        final nextMatchingInterval = destinationIntervals.firstWhereOrNull((interval) => interval.start > mappedStart);
        final nbNonIntersectingValues = nextMatchingInterval != null ? nextMatchingInterval.start - mappedStart : nbSourceValues;
        if (nextMatchingInterval == null || nbNonIntersectingValues > nbSourceValues) {
          // Keeping fully unmapped new interval intact
          newIntervals.addAll([
            (
              source: destination,
              seedInterval: (start: seedInterval.start, end: seedInterval.start + nbSourceValues),
              currentInterval: (start: mappedStart, end: mappedStart + nbSourceValues)
            )
          ]);
        } else {
          // Splitting interval in two
          newIntervals.addAll([
            (
              // Unmapped non intersecting part
              source: destination,
              seedInterval: (start: seedInterval.start, end: seedInterval.start + nbNonIntersectingValues),
              currentInterval: (start: mappedStart, end: mappedStart + nbNonIntersectingValues)
            ),
            (
              // Remaining mapped part (to be reprocessed as new source later since some of it could be unmapped ...)
              source: source,
              seedInterval: (start: seedInterval.start + nbNonIntersectingValues, end: seedInterval.start + nbSourceValues),
              currentInterval: (start: currentInterval.start + nbNonIntersectingValues, end: currentInterval.start + nbSourceValues)
            )
          ]);
        }
      }

      for (final interval in newIntervals) {
        if (interval.source == 'location') {
          // Fully mapped interval (seed --> location) with no intermediate map
          final (source: _, :seedInterval, :currentInterval) = interval;
          seedLocationsMap.addAll({(start: seedInterval.start, end: seedInterval.end): (start: currentInterval.start, end: currentInterval.end)});
        } else {
          intervalsToMap.addAll([interval]);
        }
      }
    } while (intervalsToMap.isNotEmpty);

    return seedLocationsMap;
  }

  static void printSeedLocationIntervalsMap(SeedLocationIntervalsMap seedLocationsMap, {bool sortByLocation = false}) {
    final maxValue = seedLocationsMap.entries.expand((entry) => [entry.key.start, entry.key.end, entry.value.start, entry.value.end]).max;
    final padLength = maxValue.toString().length;

    // Print sorted map entries
    final Comparator<MapEntry<Interval, Interval>> sortFunction =
        sortByLocation ? (a, b) => a.value.start - b.value.start : (a, b) => a.key.start - b.key.start;
    for (final entry in seedLocationsMap.entries.sorted(sortFunction)) {
      final [key, value] = [entry.key, entry.value];
      final seedIntervalString = '[${key.start.toString().padLeft(padLength)}, ${key.end.toString().padLeft(padLength)}[';
      final locationIntervalString = '[${value.start.toString().padLeft(padLength)}, ${value.end.toString().padLeft(padLength)}[';
      print('seed $seedIntervalString --> location $locationIntervalString');
    }
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////
typedef SeedValue = int;
typedef SeedRange = ({int start, int nbSeeds});
typedef TypeMapKey = ({String source, String destination});
typedef TypeMapRange = ({int source, int destination, int nbMappedValues});
typedef SeedsMap = Map<int, Map<String, int>>;

typedef Interval = ({int start, int end}); // [start, end[
typedef SeedLocationIntervalsMap = Map<Interval, Interval>;

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
    } catch (_) {
      return sourceValue; // Missing values are unmapped
    }
  }

  int getReversedMappedValue(String destination, String source, int destinationValue) {
    final typeMap = typeMaps[(source: source, destination: destination)]!;
    try {
      final typeMapRange =
          typeMap.firstWhere((typeRange) => destinationValue.isInRange(typeRange.destination, typeRange.destination + typeRange.nbMappedValues));
      return typeMapRange.source + (destinationValue - typeMapRange.destination);
    } catch (_) {
      return destinationValue; // Missing values are unmapped
    }
  }

  List<Interval> getDestinationIntervals(TypeMapKey typeMapKey) {
    return typeMaps[typeMapKey]!
        .map((typeMapRange) => (start: typeMapRange.destination, end: typeMapRange.destination + typeMapRange.nbMappedValues))
        .sorted((a, b) => a.start - b.start) // Assuming no overlapping of map intervals
        .toList();
  }
}

extension NumRange on num {
  bool isInRange(num min, num max) {
    return min <= this && this < max;
  }
}
