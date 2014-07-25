#!/usr/bin/env dart

// Weiterlesen:
//      https://www.dartlang.org/docs/serverguide.html#shell-scripting
//
// Sample:
//      git --git-dir=/Volumes/Daten/DevLocal/DevJava/MobileAdvertising/MobiAd.REST/.git history
//

import 'package:args/args.dart';
import 'dart:io';

const LINE_NUMBER = 'line-number';

class Application {
    final ArgParser _parser;

    Application() : _parser = Application._createOptions();

    int run(List<String> args) {
        try {
            final ArgResults argResults = _parser.parse(args);
            final List<String> dirstoscan = argResults.rest;

            if(dirstoscan.length == 0 && args.length == 0) {
                _showUsage();
            }

            // print("ArgResult for $LINE_NUMBER: ${argResults[LINE_NUMBER]}");

            for(final String dir in dirstoscan) {
                _iterateThroughDir(dir,(final File file) {
                    print("  -> ${file.path}");
                    Process.run('xgettext',['-kl10n', '-kL10N' '-o test.pot' '--from-code UTF-8' '-L JavaScript'])
                        .then( (final ProcessResult results) {
                            print("    ${results.stdout}");
                    });
                });
            }

            //        Process.run('ls', ['-l']).then((ProcessResult results) {
            //            print(results.stdout);
            //        });

        } on FormatException catch (error) {
            _showUsage();
        }
    }
    // -- private -------------------------------------------------------------
    void _iterateThroughDir(final String dir, void callback(final File file) ) {
        print("Scanning: $dir");

        final Directory directory  = new Directory(dir);
        directory.exists().then( (_) {
            directory.list(recursive: true)
            .where( (final FileSystemEntity entity) {
                return (
                    FileSystemEntity.isFileSync(entity.path) &&
                    entity.path.contains("packages") == false &&
                    ( entity.path.endsWith(".dart") || entity.path.endsWith("DART"))
                );

            }).any( (final File file) {
                callback(file);
            });
        })
        .catchError((final dynamic error,final StackTrace stacktrace) {
            print(error);
        });

    }

    void _showUsage() {
        print("Usage: extract-pot [options] <dir(s) to scan>");
        print(_parser.getUsage());
    }

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(LINE_NUMBER, negatable: false, abbr: 'n', help: "Shows linenumbers");

        return parser;
    }
}

void main(List<String> arguments) {
    final Application application = new Application();
    application.run(arguments);

//    final ArgParser parser = application._createOptions();
//
//    try {
//        final ArgResults argResults = parser.parse(arguments);
//        final List<String> dirstoscan = argResults.rest;
//
//        print("ArgResult for $LINE_NUMBER: ${argResults[LINE_NUMBER]}");
//
//        for(final String dir in dirstoscan) {
//            print("Path: $path");
//        }
//
////        Process.run('ls', ['-l']).then((ProcessResult results) {
////            print(results.stdout);
////        });
//
//    } on FormatException catch (error) {
//        print("Usage: extract-pot [options] <dir(s) to scan>");
//        print(parser.getUsage());
//    }
}

