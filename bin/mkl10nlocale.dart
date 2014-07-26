#!/usr/bin/env dart

import 'package:args/args.dart';
import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import 'package:validate/validate.dart';

class Config {
    final Logger _logger = new Logger("mkl10llocale.Config");

    static const String _KEY_LOCALE_DIR = "localeDir";
    static const String _KEY_TEMPLATES_DIR = "templatesDir";
    static const String _KEY_POT_FILENAME = "potfile";
    static const String _KEY_PO_FILENAME = "pofile";
    static const String _KEY_JSON_FILENAME = "jsonfilename";
    static const String _KEY_DART_FILENAME = "jsonfilename";
    static const String _KEY_LIB_PREFIX = "libprefix";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {
        _settings[_KEY_LOCALE_DIR]      = 'locale';
        _settings[_KEY_TEMPLATES_DIR]   = 'templates/LC_MESSAGES';

        _settings[_KEY_POT_FILENAME]    = 'messages.pot';
        _settings[_KEY_PO_FILENAME]     = 'messages.po';

        _settings[_KEY_JSON_FILENAME]   = 'messages.json';
        _settings[_KEY_DART_FILENAME]   = 'messages.dart';

        _settings[_KEY_LIB_PREFIX]      = 'l10n';
    }


    List<String> get dirstoscan => _argResults.rest;

    /// Something like: locale/templates/LC_MESSAGES
    String get potdir => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_TEMPLATES_DIR]}";

    /// Something like: locale/templates/LC_MESSAGES/messages.pot
    String get potfile => "$potdir/${_settings[_KEY_POT_FILENAME]}";

    /// Something like: locale/en/LC_MESSAGES/messages.po
    String getPOFile(final String locale) => "${_settings[_KEY_LOCALE_DIR]}/$locale/LC_MESSAGES/${_settings[_KEY_PO_FILENAME]}";

    /// Something like: locale/messages.json
    String get jsonfile => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_JSON_FILENAME]}";

    /// Something like: locale/messages.dart
    String get dartfile => "${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_DART_FILENAME]}";

    String get libprefix => _settings[_KEY_LIB_PREFIX];

}

class Application {
    final Logger _logger = new Logger("mkl10llocale.Application");

    static const _OPTION_LOCALES = 'locales';
    static const _FLAG_HELP = 'help';

    final ArgParser _parser;

    Application() : _parser = Application._createOptions();

    void run(List<String> args) {
        try {
            final ArgResults argResults = _parser.parse(args);
            final Config config = new Config(argResults);

            if (argResults[_FLAG_HELP] || (config.dirstoscan.length == 0 && args.length == 0)) {
                _showUsage();

            }
            else {
                _configLogging();
                _createPOTFile(config.potfile).then((final File potfile) {

                    _scanDirsAndFillPOT(config.dirstoscan,config.potfile).then((_) {

                        if (argResults[_OPTION_LOCALES] != null) {

                            final List<String> locales = (argResults[_OPTION_LOCALES] as String).split(',');

                            // accumulated JSON (the one ine locale)
                            final Map<String,Map<String,String>> json = new HashMap<String,Map<String,String>>();

                            // _createJson returns ASYNC - so we wait until all locale JSON-Files are created
                            final List<Future> futuresForJson = new List<Future>();
                            locales.forEach( (final String locale) {
                                final File pofile = _preparePOFile(locale, potfile,config.getPOFile(locale));

                                _mergePO(pofile,potfile);
                                futuresForJson.add( _creatJson(locale,pofile).then((final Map<String,String> jsonForLocale) => json[locale] = jsonForLocale));
                            });
                            Future.wait(futuresForJson).then((_) {
                                _createMergedJson(json,config.jsonfile);
                                _createDartFile(json,config.dartfile,libPrefix: config.libprefix);
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

    /// Writes the DART-File - makes translation easy
    void _createDartFile(final Map<String,Map<String,String>> json, final String filename,{ final String libPrefix: "not.defined" } ) {
        Validate.notEmpty(json);
        Validate.notBlank(filename);

        final File dartFile = new File(filename);
        final StringBuffer buffer = new StringBuffer();

        buffer.writeln("library $libPrefix.locale;\n");
        buffer.writeln('/**');
        buffer.writeln('* DO NOT EDIT. This is code generated via pkg/l10n/bin/mkl10llocale.dart');
        buffer.writeln('* This is a library that provides messages for all your locales.');
        buffer.writeln('*/');
        buffer.writeln("");
        buffer.writeln("import 'package:l10n/l10n.dart';");
        buffer.writeln("\n");
        buffer.write('final L10NTranslate translate = new L10NTranslate.withTranslations( ');
        buffer.write(_makePrettyJsonString(json));
        buffer.writeln(");\n");

        dartFile.writeAsStringSync(buffer.toString());
        _logger.fine("${dartFile.path} created");
    }

    /// message.json in locale, contains all the specified locales
    void _createMergedJson(final Map<String,Map<String,String>> json, final String filename) {
        Validate.notEmpty(json);
        Validate.notBlank(filename);

        final File jsonFile = new File(filename);
        jsonFile.writeAsStringSync(_makePrettyJsonString(json));
        _logger.fine("${jsonFile.path} created");
    }

    /// Updates your translated PO with new entries from .pot-File
    void _mergePO(final File pofile,final File potfile) {
        final ProcessResult result = Process.runSync('msgmerge', ['-U', pofile.path, potfile.path]);
        if(result.exitCode != 0) {
            _logger.fine(result.stderr);
        }
        _logger.fine("${pofile.path} merged!");
    }

    /// Mainly a copy of POT File
    File _preparePOFile(final String locale, final File potfile, final String pofilename) {
        final File pofile = new File(pofilename);
        if(!pofile.existsSync()) {
            pofile.createSync(recursive: true);
            final ProcessResult result = Process.runSync('msginit', ['--no-translator','--input', potfile.path, '--output', pofile.path, '-l', locale]);
            if(result.exitCode != 0) {
                _logger.fine(result.stderr);
            }
        }
        return pofile;
    }

    /// Make sure that the POT-File exists before xgettext
    Future<File> _createPOTFile(final String potfile) {
        final File file = new File(potfile);
        return file.create(recursive: true);
    }

    /// Itarees through dirs and adds the result to the POT-File
    Future<bool> _scanDirsAndFillPOT(final List<String> dirstoscan, final String potfile) {
        final Future<bool> future = new Future<bool>(() {
            for (final String dir in dirstoscan) {
                _iterateThroughDirSync(dir, (final File file) {
                    _logger.fine(" -> ${file.path}");
                    final ProcessResult result = Process.runSync('xgettext', ['-kl10n', '-kL10N', '-j', '-o', "$potfile", '-L', 'JavaScript', file.path ]);

                    if (result.exitCode != 0) {
                        _logger.fine("${result.stderr}");
                    }
                });
            }
            return true;
        });

        return future;
    }

    /**
     * Only for testing - I'm using the SYNC-Version because otherwise it bring xgettext into trouble
     */
    void _iterateThroughDir(final String dir, void callback(final File file)) {
        _logger.fine("Scanning: $dir");

        final Directory directory = new Directory(dir);
        directory.exists().then((_) {
            directory.list(recursive: true).where((final FileSystemEntity entity) {
                return (FileSystemEntity.isFileSync(entity.path) && entity.path.contains("packages") == false && ( entity.path.endsWith(".dart") || entity.path.endsWith("DART")));

            }).any((final File file) {
                callback(file);
            });
        }).catchError((final dynamic error, final StackTrace stacktrace) {
            _logger.fine(error);
        });
    }

    void _iterateThroughDirSync(final String dir, void callback(final File file)) {
        _logger.fine("Scanning: $dir");

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
        _logger.fine("Usage: l10nlocale [options] <dir(s) to scan>");
        _parser.getUsage().split("\n").forEach((final String line) {
            _logger.fine("    $line");
        });
        _logger.fine("");
    }

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_FLAG_HELP, abbr: 'h', negatable: false, help: "Shows this message")
            ..addOption(_OPTION_LOCALES, abbr: 'l', help: "locales - separated by colon, Sample: --locales en,de,es");

        return parser;
    }

    /// Creates .json-File in the same location where the .po file is
    Future<HashMap<String,String>> _creatJson(final String locale,final File pofile) {
        final Completer<HashMap<String,String>> completer = new Completer<HashMap<String,String>>();

        final Map<String,Map<String,String>> json = new HashMap<String,Map<String,String>>();
        json[locale] = new HashMap<String,String>();

        if(pofile.existsSync()) {
            final File jsonFile = new File(pofile.path.replaceFirst(new RegExp("\.po"),".json"));
            if(jsonFile.existsSync()) {
                jsonFile.deleteSync();
            }
            jsonFile.createSync(recursive: true);

            pofile.readAsString().then((final String content) {

                // There is always a newline between the msg-blocks, so split there
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

                jsonFile.writeAsString(_makePrettyJsonString(json)).then((final File file) {
                    _logger.fine("${file.path} created!");
                    completer.complete(json[locale]);
                });
            });

        } else {
            _logger.fine("${pofile.path} does not exist!");
        }

        return completer.future;
    }

    String _makePrettyJsonString(final json) {
        Validate.notEmpty(json);

        final JsonEncoder encoder = const JsonEncoder.withIndent('   ');
        return encoder.convert(json);
    }

    void _configLogging() {
        hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

        // now control the logging.
        // Turn off all logging first
        Logger.root.level = Level.FINE;
        Logger.root.onRecord.listen(new LogPrintHandler(messageFormat: "%m"));
    }
}

void main(List<String> arguments) {
    final Application application = new Application();
    application.run(arguments);
}

