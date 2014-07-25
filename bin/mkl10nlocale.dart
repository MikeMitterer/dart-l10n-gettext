#!/usr/bin/env dart

import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

class Application {
    static const _OPTION_LOCALES = 'locales';
    static const _FLAG_HELP = 'help';

    static const _DEFAULT_POT_DIR = 'locale/templates/LC_MESSAGES';
    static const _POT_FILE = 'messages.pot';

    final ArgParser _parser;

    Application() : _parser = Application._createOptions();

    void run(List<String> args) {
        try {
            final ArgResults argResults = _parser.parse(args);
            final List<String> dirstoscan = argResults.rest;

            if (argResults[_FLAG_HELP] || (dirstoscan.length == 0 && args.length == 0)) {
                _showUsage();

            }
            else {
                _preparePOTFile(_DEFAULT_POT_DIR, _POT_FILE).then((final File potfile) {

                    _scanDirsAndMakePOT(dirstoscan, _DEFAULT_POT_DIR).then((_) {

                        if (argResults[_OPTION_LOCALES] != null) {
                            final List<String> locales = (argResults[_OPTION_LOCALES] as String).split(',');
                            locales.forEach((final String locale) {
                                final File pofile = _preparePOFile(locale, potfile,"locale/$locale/LC_MESSAGES/messages.po");
                                _mergePO(pofile,potfile);
                                _creatJson(locale,pofile);

                            });
                        }
                    });
                });
            }
        }

        on FormatException
        catch (error) {
            _showUsage();
        }
    }

    // -- private -------------------------------------------------------------

    void _mergePO(final File pofile,final File potfile) {
        final ProcessResult result = Process.runSync('msgmerge', ['-U', pofile.path, potfile.path]);
        if(result.exitCode != 0) {
            print(result.stderr);
        }
        print("${pofile.path} merged!");
    }

    File _preparePOFile(final String locale, final File potfile, final String pofilename) {
        final File pofile = new File(pofilename);
        if(!pofile.existsSync()) {
            pofile.createSync(recursive: true);
            final ProcessResult result = Process.runSync('msginit', ['--no-translator','--input', potfile.path, '--output', pofile.path, '-l', locale]);
            if(result.exitCode != 0) {
                print(result.stderr);
            }
        }
        return pofile;
    }

    Future<File> _preparePOTFile(final String outputdir, final String outputfile) {
        final File file = new File("$outputdir/$outputfile");
        return file.create(recursive: true);
    }

    Future<bool> _scanDirsAndMakePOT(final List<String> dirstoscan, final String outDir) {
        final Future<bool> future = new Future<bool>(() {
            for (final String dir in dirstoscan) {
                _iterateThroughDirSync(dir, (final File file) {
                    print(" -> ${file.path}");
                    final ProcessResult result = Process.runSync('xgettext', ['-kl10n', '-kL10N', '-j', '-o', "$outDir/$_POT_FILE", '-L', 'JavaScript', file.path ]);

                    if (result.exitCode != 0) {
                        print("${result.stderr}");
                    }
                });
            }
            return true;
        });

        return future;
    }

    void _iterateThroughDir(final String dir, void callback(final File file)) {
        print("Scanning: $dir");

        final Directory directory = new Directory(dir);
        directory.exists().then((_) {
            directory.list(recursive: true).where((final FileSystemEntity entity) {
                return (FileSystemEntity.isFileSync(entity.path) && entity.path.contains("packages") == false && ( entity.path.endsWith(".dart") || entity.path.endsWith("DART")));

            }).any((final File file) {
                callback(file);
            });
        }).catchError((final dynamic error, final StackTrace stacktrace) {
            print(error);
        });
    }

    void _iterateThroughDirSync(final String dir, void callback(final File file)) {
        print("Scanning: $dir");

        final Directory directory = new Directory(dir);
        if (directory.existsSync()) {
            directory.listSync(recursive: true).where((final FileSystemEntity entity) {

                return (FileSystemEntity.isFileSync(entity.path) && entity.path.contains("packages") == false && ( entity.path.endsWith(".dart") || entity.path.endsWith("DART")));

            }).any((final File file) {
                callback(file);
            });
        }
    }

    void _showUsage() {
        print("Usage: l10nlocale [options] <dir(s) to scan>");
        _parser.getUsage().split("\n").forEach((final String line) {
            print("    $line");
        });
        print("");
    }

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_FLAG_HELP, abbr: 'h', negatable: false, help: "Shows this message")
            ..addOption(_OPTION_LOCALES, abbr: 'l', help: "locales - separated by colon, Sample: --locales en,de,es");

        return parser;
    }

    void _creatJson(final String locale,final File pofile) {
        if(pofile.existsSync()) {
            final File jsonFile = new File(pofile.path.replaceFirst(new RegExp("\.po"),".json"));
            if(jsonFile.existsSync()) {
                jsonFile.deleteSync();
            }
            jsonFile.createSync(recursive: true);

            pofile.readAsString().then((final String content) {
                final Map<String,Map<String,String>> json = new HashMap<String,Map<String,String>>();
                json[locale] = new HashMap<String,String>();

                final List<String> msgblocks = content.split(new RegExp("(\r\n|\n){2}"));

                String _sanityze(final String value) {
                    return value.replaceFirst("msgid","").trim().replaceFirst(new RegExp("^\""),"").replaceFirst(new RegExp('"\$'),"").trim();
                }

                const int HEADER = 1;
                msgblocks.skip(HEADER).forEach((final String block) {
                    final String withoutcomment = block.replaceAll(new RegExp("#.*(\r\n|\n)"),"");
                    final List<String> message = withoutcomment.split("msgstr");

                    final String key = _sanityze(message[0].replaceFirst("msgid",""));
                    final String value = _sanityze(message[1]);

                    json[locale][key] = value;
                });

                String _makePrettyJsonString() {
                    final JsonEncoder encoder = const JsonEncoder.withIndent('   ');
                    return encoder.convert(json);
                }

                jsonFile.writeAsString(_makePrettyJsonString()).then((final File file) {
                    print("${file.path} created!");
                });
            });

        } else {
            print("${pofile.path} does not exist!");
        }
    }
}

void main(List<String> arguments) {
    final Application application = new Application();
    application.run(arguments);
}

