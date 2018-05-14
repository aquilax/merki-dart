import 'dart:io';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:merki_dart/merki_dart.dart' as merki_dart;
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:sparkline_console/sparkline_console.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

const DELIMITER = "\t";

main(List<String> arguments) {
  var merki = new Merki(new Config(DELIMITER));
  var runner =
      new CommandRunner("merki", "Command line personal health tracker")
        ..argParser.addOption('file', abbr: 'f', defaultsTo: 'health.log')
        ..addCommand(new AddCommand(merki))
        ..addCommand(new SparklineCommand(merki))
        ..addCommand(new MeasurementsCommand(merki))
        ..addCommand(new FilterCommand(merki))
        ..addCommand(new LatestCommand(merki))
        ..run(arguments);
}

class Config {
  String delimiter;
  Config(this.delimiter);
}

class Merki {
  Config config;

  Merki(this.config);

  addRecord(String fileName, Record record) {
    var file = new File(fileName);
    var sink = file.openWrite(mode: WRITE_ONLY_APPEND);
    sink.write("\n" + record.asCSV());
    sink.close();
  }

  Stream<String> _readLines(String fileName) {
    return new File(fileName)
        .openRead()
        .transform(UTF8.decoder)
        .transform(new LineSplitter());
  }

  Stream<Record> _readFile(String fileName) async* {
    var lineStream = _readLines(fileName);
    await for (var line in lineStream) {
      yield new Record.fromString(line, config.delimiter);
    }
  }

  sparkLine(String fileName, measure) {
    List<double> values = [];
    _readFile(fileName).forEach((record) {
      if (record.measurement == measure) {
        values.add(record.value);
      }
    }).whenComplete(() => print(new SparkLine().generate(values)));
  }
}

class BadParametersException implements Exception {}

class Record {
  DateTime date;
  String measurement;
  double value;
  String name;
  String description;

  Record.fromString(String row, delimiter)
      : this.fromArgs(row.split(delimiter));

  Record.fromArgs(List<String> args) {
    if (args.length < 3) {
      throw new BadParametersException();
    }
    var formatter = new DateFormat('yyyy-MM-dd HH:mm:ss');
    date = formatter.parse(args[0]);
    measurement = args[1];
    value = double.parse(args[2]);
    name = args[3] ?? "";
    description = args[4] ?? "";
  }

  String asCSV() {
    var formatter = new DateFormat('yyyy-MM-dd HH:mm:ss');
    final list = [
      formatter.format(date),
      measurement,
      value.toStringAsFixed(2),
      name,
      description
    ];
    return const ListToCsvConverter(fieldDelimiter: "\t", eol: "\n")
        .convert([list]);
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
    var formatter = new DateFormat('yyyy-MM-dd HH:mm:ss');
    var now = formatter.format(new DateTime());
    var args = argResults.rest;
    args.insert(0, now);
    var record = new Record.fromArgs(args);
    var fileName = globalResults['file'];
    merki.addRecord(fileName, record);
  }
}

class SparklineCommand extends MerkiCommand {
  final name = "sparkline";
  final description = "Draw sparkline graph for a measure.";
  SparklineCommand(Merki merki) : super(merki);

  run() {
    var measure = argResults.rest[0];
    var fileName = globalResults['file'];
    merki.sparkLine(fileName, measure);
  }
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
