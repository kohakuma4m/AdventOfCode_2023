import 'package:collection/collection.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final (workflowsMap, parts) = readWorkflowsAndParts(lines);
    print('Nb parts: ${parts.length}');
    print('----------------------------');

    final (:acceptedParts, :rejectedParts) = validateParts(parts, workflowsMap);
    print('Nb accepted parts: ${acceptedParts.length}');
    print('Nb rejected parts: ${rejectedParts.length}');
    print('----------------------------');

    return acceptedParts.map((part) => part.rating).sum;
  }

  Future<int> solvePart2() async {
    final (workflowsMap, _) = readWorkflowsAndParts(lines);
    print('Nb workflows: ${workflowsMap.length}');
    print('--------------------------------------------');

    final initialPartRange = PartRange(Map.fromEntries(PartType.values.map((type) => MapEntry(type, (min: 1, max: 4000)))));
    final nbTotalParts = initialPartRange.getNbParts();
    print('Nb possible parts: $nbTotalParts');
    print('--------------------------------------------');

    final (:acceptedPartRanges, :rejectedPartRanges) = validatePartRange(initialPartRange, workflowsMap);
    final nbAcceptedParts = acceptedPartRanges.map((range) => range.getNbParts()).sum;
    final nbRejectedParts = rejectedPartRanges.map((range) => range.getNbParts()).sum;
    print('Nb accepted parts: $nbAcceptedParts (${(nbAcceptedParts / nbTotalParts * 100).toStringAsFixed(2)}%)');
    print('Nb rejected parts: $nbRejectedParts (${(nbRejectedParts / nbTotalParts * 100).toStringAsFixed(2)}%)');
    print('--------------------------------------------');

    return nbAcceptedParts;
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static final RegExp workflowLineRegex = RegExp(r'^(?<name>\w+)\{(?<steps>.+)\}$');
  static final RegExp workflowStepRegex = RegExp(r'^(?:(?<type>x|m|a|s)(?<operator>\<|\>)(?<threshold>\d+):)?(?<next>\w+)$');
  static final RegExp partLineRegex = RegExp(r'^\{(?<values>.*)\}$');

  static (Map<String, Workflow>, List<Part>) readWorkflowsAndParts(List<String> lines) {
    final separatorLineIndex = lines.indexWhere((line) => line.isEmpty);

    final Map<String, Workflow> workflowsMap = {};
    for (final line in lines.sublist(0, separatorLineIndex)) {
      final match = workflowLineRegex.allMatches(line).first;

      final name = match.namedGroup('name')!;
      final List<WorkflowStep> steps = [];
      for (final step in match.namedGroup('steps')!.split(',')) {
        final stepMatch = workflowStepRegex.allMatches(step).first;

        steps.add((
          type: PartType.values.asNameMap()[stepMatch.namedGroup('type')],
          operator: stepMatch.namedGroup('operator'),
          threshold: int.tryParse(stepMatch.namedGroup('threshold') ?? ''),
          next: stepMatch.namedGroup('next')!
        ));
      }

      workflowsMap.addAll({name: Workflow(name, steps)});
    }

    final List<Part> parts = [];
    for (final line in lines.sublist(separatorLineIndex + 1)) {
      final match = partLineRegex.allMatches(line).first;

      final Map<PartType, int> values = {};
      for (final entry in match.namedGroup('values')!.split(',')) {
        final [type, value] = entry.split('=');
        values.addAll({PartType.values.asNameMap()[type]!: int.parse(value)});
      }

      parts.add(Part(values));
    }

    return (workflowsMap, parts);
  }

  static void printWorkflows(Map<String, Workflow> workflowsMap) {
    print('Workflows:');
    print('----------------------------');
    print(workflowsMap.values.join('\n'));
    print('');
  }

  static void printParts(List<Part> parts) {
    print('Parts:');
    print('----------------------------');
    print(parts.join('\n'));
    print('');
  }

  ///============================================================================================
  /// Part 1 solution: validing parts one by one
  ///============================================================================================
  static ({List<Part> acceptedParts, List<Part> rejectedParts}) validateParts(List<Part> parts, Map<String, Workflow> workflowsMap) {
    List<Part> acceptedParts = [];
    List<Part> rejectedParts = [];

    for (final part in parts) {
      var next = 'in';
      do {
        final nextWorkflow = workflowsMap[next]!;
        next = nextWorkflow.validatePart(part);
      } while (PartBin.values.asNameMap()[next] == null);

      if (PartBin.values.asNameMap()[next] == PartBin.A) {
        acceptedParts.add(part);
      } else {
        rejectedParts.add(part);
      }
    }

    return (acceptedParts: acceptedParts, rejectedParts: rejectedParts);
  }

  ///============================================================================================
  /// Part 2 solution: validating range of possible parts all at once, splitting ranges as we go
  ///                  and keeping track of all accepted/rejected ranges
  ///
  /// Since all workflow steps are independents because possible range was split at each step,
  /// we can just add up the number of possible parts for each accepted/rejected range at the end
  ///
  /// Counts      : accepted       + rejected       = total
  /// Probability : accepted/total + rejected/total = 1 (100%)
  ///============================================================================================
  static ({List<PartRange> acceptedPartRanges, List<PartRange> rejectedPartRanges}) validatePartRange(
      PartRange initialPartRange, Map<String, Workflow> workflowsMap) {
    final List<PartRange> acceptedPartRanges = [];
    final List<PartRange> rejectedPartRanges = [];

    final List<(PartRange, String)> partRangesToProcess = [(initialPartRange, 'in')];
    while (partRangesToProcess.isNotEmpty) {
      final (currentPartRange, next) = partRangesToProcess.removeLast();
      final nextWorkflow = workflowsMap[next]!;

      for (final (newPartRange, newNext) in nextWorkflow.validatePartRange(currentPartRange)) {
        if (PartBin.values.asNameMap()[newNext] == null) {
          // Part range not fully processed yet
          partRangesToProcess.add((newPartRange, newNext));
        } else if (PartBin.values.asNameMap()[newNext] == PartBin.A) {
          // Part range accepted
          acceptedPartRanges.add(newPartRange);
        } else {
          // Part range rejected
          rejectedPartRanges.add(newPartRange);
        }
      }
    }

    return (acceptedPartRanges: acceptedPartRanges, rejectedPartRanges: rejectedPartRanges);
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

enum PartType { x, m, a, s }

enum PartBin { A, R }

typedef WorkflowStep = ({PartType? type, String? operator, int? threshold, String next});

class Workflow {
  String name;
  List<WorkflowStep> steps;

  Workflow(this.name, this.steps);

  String validatePart(Part part) {
    for (final step in steps) {
      switch (step.operator) {
        case '<':
          {
            if (part.values[step.type]! < step.threshold!) {
              return step.next;
            }
            break;
          }
        case '>':
          {
            if (part.values[step.type]! > step.threshold!) {
              return step.next;
            }
            break;
          }
        case null:
        default:
          {
            return step.next;
          }
      }
    }

    throw 'Part did not match any steps: $this --> $part';
  }

  List<(PartRange, String)> validatePartRange(PartRange partRange) {
    final List<(PartRange, String)> newPartRanges = [];
    final partRangeValues = Map.fromEntries(partRange.values.entries);

    steps:
    for (final step in steps) {
      switch (step.operator) {
        case '<':
          {
            final thresholdValue = step.threshold!;
            final (:min, :max) = partRangeValues[step.type]!;
            if (max < thresholdValue) {
              // Whole range is below threshold
              newPartRanges.add((PartRange(Map.from(partRangeValues)), step.next));
              break steps;
            } else if (min < thresholdValue) {
              // Range below threshold
              partRangeValues.update(step.type!, (_) => (min: min, max: thresholdValue - 1));
              newPartRanges.add((PartRange(Map.from(partRangeValues)), step.next));

              // Remaining range
              partRangeValues.update(step.type!, (_) => (min: thresholdValue, max: max));
            }
            break;
          }
        case '>':
          {
            final thresholdValue = step.threshold!;
            final (:min, :max) = partRangeValues[step.type]!;
            if (min > thresholdValue) {
              // Whole range is above threshold
              newPartRanges.add((PartRange(Map.from(partRangeValues)), step.next));
              break steps;
            } else if (max > thresholdValue) {
              // Range above threshold
              partRangeValues.update(step.type!, (_) => (min: thresholdValue + 1, max: max));
              newPartRanges.add((PartRange(Map.from(partRangeValues)), step.next));

              // Remaining range
              partRangeValues.update(step.type!, (_) => (min: min, max: thresholdValue));
            }
            break;
          }
        case null:
        default:
          {
            // Whole range goes to next step
            newPartRanges.add((PartRange(Map.from(partRangeValues)), step.next));
            break steps;
          }
      }
    }

    return newPartRanges;
  }

  @override
  String toString() {
    return '$name{${steps.map((s) => '${s.type?.name ?? ''}${s.operator ?? ''}${s.threshold ?? ''}${s.type != null ? ':' : ''}${s.next}').join(', ')}}';
  }
}

class Part {
  Map<PartType, int> values;
  late int rating;

  Part(this.values) {
    rating = values.values.sum;
  }

  @override
  String toString() {
    return '{${values.entries.map((e) => '${e.key.name}=${e.value}').join(', ')}}';
  }
}

class PartRange {
  Map<PartType, ({int min, int max})> values;

  PartRange(this.values);

  int getNbParts() {
    return values.values.fold(1, (total, current) => total * (current.max - current.min + 1));
  }

  @override
  String toString() {
    return '{${values.entries.map((e) => '${e.key.name}=[${e.value.min},${e.value.max}]').join(', ')}}';
  }
}
