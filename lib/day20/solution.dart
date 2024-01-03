import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:trotter/trotter.dart';

class Solution {
  List<String> lines;

  Solution(this.lines);

  Future<int> solvePart1() async {
    final modules = buildModules(lines);

    var nbLowPulses = 0;
    var nbHighPulses = 0;
    for (var i = 0; i < 1000; i++) {
      final pulseCounts = pressButton(modules);
      nbLowPulses += pulseCounts.low;
      nbHighPulses += pulseCounts.high;
    }
    print('Nb low pulses: $nbLowPulses');
    print('Nb high pulses: $nbHighPulses');
    print('----------------------------');

    return nbLowPulses * nbHighPulses;
  }

  ///===============================================================================================
  /// Solution for my specific input with the following assumptions:
  ///
  /// 1) Button --> Broacast --> X independant module groups --> Receiver --> Machine (output)
  /// 2) Receiver module is a Conjunction module with a single output module (Machine):
  ///
  ///    So once all receiver module inputs are high at the same time, then receiver send low pulse
  ///    to output module to start machine
  ///
  /// 3) All broadcast output groups are independant and connected to a separate receiver input
  /// 4) Each independant module group has a repeating pattern:
  ///
  ///    In my case, the cyclic pattern is: [period, 1, 1, 1, ...] for all receiver inputs
  ///    (i.e: each receiver input never send a low pulse again after sending first high pulse)
  ///
  ///    TODO: add support for other period pattern: [period, x, x, x, ...] ???
  ///===============================================================================================
  Future<int> solvePart2() async {
    final modules = buildModules(lines);

    // Validating input data
    final machineModule = modules.firstWhereOrNull((m) => m.name == 'rx');
    if (machineModule == null) {
      throw ArgumentError('Part 2 can only be run on real input with "rx" output module');
    }
    assert(machineModule is OutputModule, 'Machine module is not an output module');

    final receiverModules = modules.where((m) => m.outputs?.contains(machineModule) == true).toSet();
    assert(receiverModules.length == 1, 'Machine module has more than one input modules');

    final receiverModule = receiverModules.first;
    assert(receiverModule is ConjunctionModule, 'Receiver module is not a Conjunction module');

    final receiverModuleInputs = modules.where((m) => m.outputs?.contains(receiverModule) == true).toSet();
    assert(receiverModuleInputs.every((m) => m is FlipFlopModule || m is ConjunctionModule), 'Invalid receiver input modules');

    final broadcastModuleOutputGroups = splitBroacastOutputModules(modules, receiverModule);
    assert(broadcastModuleOutputGroups.length == receiverModuleInputs.length,
        'Number of outputs on broadcast module does not match number of inputs on receiver module');
    for (final pair in Combinations(2, broadcastModuleOutputGroups)()) {
      final [group1, group2] = pair;
      assert(group1.intersection(group2).isEmpty, 'All broadcast module output groups are not independant');
    }
    final unmappedReceiverModuleInputs = receiverModuleInputs.toSet();
    for (final outputGroup in broadcastModuleOutputGroups) {
      final outputGroupReceiver = outputGroup.where((m) => receiverModuleInputs.contains(m)).toSet();
      assert(outputGroupReceiver.length == 1, 'All broadcast module output groups are not linked to only one receiver input');
      unmappedReceiverModuleInputs.remove(outputGroupReceiver.first);
    }
    assert(unmappedReceiverModuleInputs.isEmpty, 'All broadcast module output groups are not linked to separate receiver inputs');

    print('Broadcast module output groups:');
    print(broadcastModuleOutputGroups.map((item) => item.map((m) => m.name).sorted()).join('\n'));
    print('-------------------');

    final Map<Module, int> receiverModuleInputsPeriod = findReceiverInputModulesPeriod(modules, receiverModuleInputs);
    print('Receiver input modules with period:');
    print(receiverModuleInputsPeriod.entries.sortedBy((e) => e.key.name).map((e) => '${e.key} (period: ${e.value})').join('\n'));
    print('-------------------');

    return receiverModuleInputsPeriod.values.fold<int>(1, (total, current) => total * current);
  }

  ///////////////////////////////////////
  /// Static methods
  ///////////////////////////////////////

  static Set<Module> buildModules(List<String> lines) {
    final buttonModule = ButtonModule();
    final broadcastModule = BroacastModule();
    buttonModule.outputs!.add(broadcastModule);

    final Set<Module> modules = {buttonModule, broadcastModule};

    // First pass to create all modules
    for (final line in lines) {
      final moduleName = line.split(' -> ').first;
      if (moduleName.startsWith('%')) {
        modules.add(FlipFlopModule(moduleName.replaceFirst('%', '')));
      } else if (moduleName.startsWith('&')) {
        modules.add(ConjunctionModule(moduleName.replaceFirst('&', '')));
      }
    }

    // Second pass to connect all modules
    for (final line in lines) {
      final [moduleName, outputs] = line.replaceFirst('%', '').replaceFirst('&', '').split(' -> ');
      final module = modules.firstWhere((m) => m.name == moduleName);

      for (final outputModuleName in outputs.split(', ')) {
        var outputModule = modules.firstWhereOrNull((m) => m.name == outputModuleName);
        if (outputModule == null) {
          outputModule = OutputModule(outputModuleName);
          modules.add(outputModule);
        }

        module.outputs?.add(outputModule);
        outputModule.inputs?.add(module);
      }
    }

    return modules;
  }

  static ({int low, int high, bool stop}) pressButton(Set<Module> modules, {PulseSignal? stopPulseSignal}) {
    final buttonModule = modules.firstWhere((m) => m is ButtonModule);

    var pulseCounts = [0, 0];
    final Queue<PulseSignal> pulseSignalsToProcess = Queue.from(buttonModule.processPulse());
    while (pulseSignalsToProcess.isNotEmpty) {
      final (module, pulse, outputModule) = pulseSignalsToProcess.removeFirst();
      pulseCounts[pulse ? 1 : 0]++;

      if ((module, pulse, outputModule) == stopPulseSignal) {
        return (low: pulseCounts[0], high: pulseCounts[1], stop: true);
      }

      if (outputModule is ConjunctionModule) {
        pulseSignalsToProcess.addAll(outputModule.processPulse(pulse, module));
      } else {
        pulseSignalsToProcess.addAll(outputModule.processPulse(pulse));
      }
    }

    return (low: pulseCounts[0], high: pulseCounts[1], stop: false);
  }

  static List<Set<Module>> splitBroacastOutputModules(Set<Module> modules, Module receiverModule) {
    final broadcastModule = modules.firstWhere((m) => m is BroacastModule);

    final List<Set<Module>> broadcastModuleOutputs = [];
    for (final output in broadcastModule.outputs!) {
      final Set<Module> modulesGroup = {output};
      final Queue<Module> modulesToCheck = Queue.from([output]);

      while (modulesToCheck.isNotEmpty) {
        final outputs = modulesToCheck.removeFirst().outputs?.where((m) => !modulesGroup.contains(m)).toList() ?? [];
        if (outputs.isNotEmpty) {
          modulesGroup.addAll(outputs);
          modulesToCheck.addAll(outputs);
        }
      }

      // Removing receiver and final output module
      modulesGroup.removeWhere((m) => [receiverModule, receiverModule.outputs?.first].contains(m));

      broadcastModuleOutputs.add(modulesGroup);
    }

    return broadcastModuleOutputs;
  }

  static Map<Module, int> findReceiverInputModulesPeriod(Set<Module> modules, Set<Module> receiverModuleInputs) {
    final Map<Module, int> receiverModuleInputsPeriod = {};
    for (final receiverInput in receiverModuleInputs) {
      for (final module in modules) {
        module.clearState();
      }

      List<int> cyclePeriods = [];
      var nbCycles = 1;
      do {
        nbCycles++;

        var nbButtonPress = 0;
        var stop = false;
        do {
          nbButtonPress++;
          stop = pressButton(modules, stopPulseSignal: (receiverInput, true, receiverInput.outputs!.first)).stop;
        } while (!stop);

        cyclePeriods.add(nbButtonPress);
      } while (nbCycles <= 3); // Enough iterations to make sure we have a cycle...

      // Validating cycle period
      final periods = cyclePeriods.toSet();
      if (periods.length > 1 && periods.difference({cyclePeriods.first, 1}).isNotEmpty) {
        throw AssertionError('Unsupported period pattern for ${receiverInput.name}: $cyclePeriods');
      }

      receiverModuleInputsPeriod.addAll({receiverInput: cyclePeriods.first});
    }

    return receiverModuleInputsPeriod;
  }
}

////////////////////////////////
/// Custom types & methods
////////////////////////////////

typedef Pulse = bool;
typedef PulseSignal = (Module, Pulse, Module); // input --> pulse --> output

abstract class Module implements Comparable<Module> {
  final String name;
  final List<Module>? inputs;
  final List<Module>? outputs;

  Module(this.name, this.inputs, this.outputs);

  List<bool> getState() {
    return [];
  }

  void clearState() {}

  List<PulseSignal> processPulse([Pulse? pulse]);

  @override
  String toString() {
    return '$name: [${inputs?.map((m) => m.name).join(',') ?? ''}] --> [${outputs?.map((m) => m.name).join(',') ?? ''}]';
  }

  @override
  bool operator ==(Object other) {
    return other is Module && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  int compareTo(Module other) {
    if (this == other) {
      return 0;
    }

    return name.compareTo(other.name);
  }
}

class ButtonModule extends Module {
  ButtonModule() : super('button', null, []);

  @override
  List<PulseSignal> processPulse([Pulse? pulse]) {
    return outputs!.map((module) => (this, false, module)).toList();
  }
}

class BroacastModule extends Module {
  BroacastModule() : super('broadcaster', null, []);

  @override
  List<PulseSignal> processPulse([Pulse? pulse]) {
    return outputs!.map((module) => (this, pulse!, module)).toList();
  }
}

class FlipFlopModule extends Module {
  bool state = false; // off

  FlipFlopModule(String name) : super(name, null, []);

  @override
  List<bool> getState() {
    return [state];
  }

  @override
  void clearState() {
    state = false;
  }

  @override
  List<PulseSignal> processPulse([Pulse? pulse]) {
    if (pulse!) {
      return [];
    }

    // Flipping state
    state = !state;

    final outputPulse = state == true;
    return outputs!.map((module) => (this, outputPulse, module)).toList();
  }
}

class ConjunctionModule extends Module {
  SplayTreeMap<Module, bool> inputStates = SplayTreeMap<Module, bool>.from({});

  ConjunctionModule(String name) : super(name, [], []);

  @override
  List<bool> getState() {
    return inputStates.values.toList();
  }

  @override
  void clearState() {
    inputStates.clear();
  }

  @override
  List<PulseSignal> processPulse([Pulse? pulse, Module? input]) {
    // Updating state
    inputStates[input!] = pulse!;

    final outputPulse = inputs!.every((module) => inputStates[module] == true) == false;
    return outputs!.map((module) => (this, outputPulse, module)).toList();
  }
}

class OutputModule extends Module {
  OutputModule(String name) : super(name, null, null);

  @override
  List<PulseSignal> processPulse([Pulse? pulse, bool printOutput = false]) {
    if (printOutput) {
      print(pulse);
    }

    return [];
  }
}
