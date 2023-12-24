import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final steps = lines.first.split(',');

    return steps.map(getHashValue).sum;
  }

  Future<int> solvePart2({bool printSteps = false}) async {
    final steps = lines.first.split(',');

    final boxes = List.generate(256, (idx) => Box(idx));
    for (final (idx, step) in steps.indexed) {
      if (step.contains('=')) {
        final [label, focalLength] = step.split('=');
        final boxNumber = getHashValue(label);
        boxes[boxNumber].updateLens(label, int.parse(focalLength));
      } else {
        final label = step.split('-').first;
        final boxNumber = getHashValue(label);
        boxes[boxNumber].removeLens(label);
      }

      if (printSteps) {
        print('After step #${idx + 1} ($step)');
        print('-------------------');
        printBoxes(boxes);
        print('');
      }
    }

    printBoxes(boxes);
    print('-------------------');

    return boxes.map((box) => box.getLensFocusingPower()).flattened.sum;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static int getHashValue(String input) {
    var current = 0;
    for (var i = 0; i < input.length; i++) {
      current += input.codeUnitAt(i); // Adding ascii value
      current *= 17;
      current = current % 256;
    }

    return current;
  }

  static printBoxes(List<Box> boxes, {bool printFocusingPower = false}) {
    for (final box in boxes.where((b) => b.lenses.isNotEmpty)) {
      print(box.toString(printFocusingPower: printFocusingPower));
    }
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

class Box {
  int number;
  Map<String, int> lensesMap = {};
  List<String> lenses = [];

  Box(this.number);

  List<int> getLensFocusingPower() {
    return lenses.mapIndexed((idx, label) => (number + 1) * (idx + 1) * lensesMap[label]!).toList();
  }

  void updateLens(String label, int focalLength) {
    lensesMap.update(label, (_) => focalLength, ifAbsent: () => focalLength);
    if (!lenses.contains(label)) {
      lenses.add(label);
    }
  }

  void removeLens(String label) {
    lensesMap.remove(label);
    lenses.removeWhere((l) => l == label);
  }

  @override
  String toString({bool printFocusingPower = false}) {
    final lensesString = lenses.map((label) => '[$label ${lensesMap[label]}]').join(' ');
    final focusingPowerString = printFocusingPower ? '--> focusing power ${getLensFocusingPower()}' : '';
    return 'Box #${number.toString().padRight(3)}: $lensesString $focusingPowerString';
  }
}
