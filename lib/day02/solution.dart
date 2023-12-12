import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  int solvePart1() {
    final games = readGamesData(lines);

    final bag = Bag({
      CubeColor.red: 12,
      CubeColor.green: 13,
      CubeColor.blue: 14,
    });

    final List<Game> validGames = games.where((game) {
      return game.rounds.every((round) {
        return round.samples.every((sample) => sample.qty <= bag.content[sample.color]!);
      });
    }).toList();

    print('-------------------');
    printGamesData(validGames);
    print('-------------------');

    return validGames.map((g) => g.number).sum;
  }

  int solvePart2() {
    final games = readGamesData(lines);

    final List<int> powers = games.map((game) {
      final bag = Bag({
        CubeColor.red: 0,
        CubeColor.green: 0,
        CubeColor.blue: 0,
      });

      for (final round in game.rounds) {
        for (final sample in round.samples) {
          if (sample.qty > bag.content[sample.color]!) {
            bag.content[sample.color] = sample.qty;
          }
        }
      }

      return bag.content.values.reduce((product, value) => product * value);
    }).toList();

    print('-------------------');
    print(powers);
    print('-------------------');

    return powers.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static List<Game> readGamesData(List<String> lines) {
    final List<Game> games = [];

    for (final line in lines) {
      final rounds = line.split(':').last.trim().split(';');

      final currentGame = Game(games.length + 1);
      for (final round in rounds) {
        final cubes = round.trim().split(',');

        final Round currentRound = Round();
        for (final cube in cubes) {
          final [value, color] = cube.trim().split(' ');
          currentRound.samples.add((color: (CubeColor.values.firstWhere((v) => v.name == color)), qty: int.parse(value)));
        }

        currentGame.rounds.add(currentRound);
      }

      games.add(currentGame);
    }

    return games;
  }

  static void printGamesData(List<Game> games) {
    final nbPaddingDigits = games.length.toString().length;

    for (final game in games) {
      print('Game ${game.number.toString().padLeft(nbPaddingDigits)}: $game');
    }
  }
}

////////////////////////////////
/// Custom types
////////////////////////////////

enum CubeColor { red, green, blue }

class Round {
  List<({CubeColor color, int qty})> samples = [];

  @override
  String toString() {
    return samples.map((d) => '${d.qty} ${d.color.name}').join(', ');
  }
}

class Game {
  int number;
  List<Round> rounds = [];

  Game(this.number);

  @override
  String toString() {
    return rounds.join('; ');
  }
}

class Bag {
  Map<CubeColor, int> content;

  Bag(this.content);

  @override
  String toString() {
    return content.toString();
  }
}
