import 'package:merki_dart/merki_dart.dart' as merki_dart;
import 'package:args/args.dart';
import 'package:args/command_runner.dart';

main(List<String> arguments) {
  var merki = new Merki(new Config());
  new CommandRunner("merki", "Command line personal health tracker")
    ..addCommand(new AddCommand(merki))
    ..addCommand(new SparklineCommand(merki))
    ..addCommand(new MeasurementsCommand(merki))
    ..addCommand(new FilterCommand(merki))
    ..addCommand(new LatestCommand(merki))
    ..run(arguments);
}

class Config {}

class Merki {
  Config config;

  Merki(this.config);

  addRecord(Record record) {
    print(config);
    print(record);
  }
}

class Record {
  Record.fromArgs(List<String> args) {
    print(args);
  }
}

abstract class MerkiCommand extends Command {
  Merki merki;

  MerkiCommand(this.merki);
}

class AddCommand extends MerkiCommand {
  final name = "add";
  final description = "Add measurement value to the file.";

  AddCommand(Merki merki) : super(merki);

  run() {
    var record = new Record.fromArgs(argResults.rest);
    merki.addRecord(record);
  }
}

class SparklineCommand extends MerkiCommand {
  final name = "sparkline";
  final description = "Draw sparkline graph for a measure.";
  SparklineCommand(Merki merki) : super(merki);
}

class MeasurementsCommand extends MerkiCommand {
  final name = "measurements";
  final description = "Return list of all used measurements.";
  MeasurementsCommand(Merki merki) : super(merki);
}

class FilterCommand extends MerkiCommand {
  final name = "filter";
  final description = "Filter records for single measuremen.";
  FilterCommand(Merki merki) : super(merki);
}

class LatestCommand extends MerkiCommand {
  final name = "latest";
  final description = "Show the latest values for all measurements.";
  LatestCommand(Merki merki) : super(merki);
}
