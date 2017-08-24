library l10n.app;

import 'dart:io';
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:args/args.dart';
import 'package:which/which.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:validate/validate.dart';

import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';

import 'package:l10n/l10n.dart';
import 'package:l10n/locale/messages.dart';

part 'commands/ShellCommand.dart';
part 'commands/commands.dart';

class Application {
    final Logger _logger = new Logger("mkl10llocale.Application");

    static const _ARG_LOCALES       = 'locales';
    static const _ARG_HELP          = 'help';
    static const _ARG_LOGLEVEL      = 'loglevel';
    static const _ARG_SETTINGS      = 'settings';
    static const _ARG_LIB_PREFIX    = 'libprefix';
    static const _ARG_LOCALE_DIR    = 'localedir';
    static const _ARG_DART_PATH     = 'dartpath';
    static const _ARG_EXCLUDE       = 'exclude';

    ArgParser _parser;

    Application() : _parser = Application._createOptions();

    void run(List<String> args,final String locale) {
        Validate.notBlank(locale);

        try {
            final ArgResults argResults = _parser.parse(args);
            final Config config = new Config(argResults,locale);

            _configLogging(config.loglevel);

            if (argResults[_ARG_HELP] || (config.dirstoscan.length == 0 && args.length == 0)) {
                _showUsage();

            } else if(argResults[_ARG_SETTINGS]) {
                _printSettings(config.settings);

            }
            else {
                _createPOTFile(config.potfile).then((final File potfile) {

                    _scanDirsAndFillPOT(config.dirstoscan,config.potfile, config.excludeDirs).then((_) {

                        final List<String> locales = config.locales.split(',');

                        // accumulated JSON (the one ine locale)
                        final Map<String,Map<String,String>> json = new HashMap<String,Map<String,String>>();

                        // _createJson returns ASYNC - so we wait until all locale JSON-Files are created
                        final List<Future> futuresForJson = new List<Future>();
                        locales.forEach( (final String locale) {
                            final File pofile = _preparePOFile(locale, potfile,config.getPOFile(locale));

                            _mergePO(pofile,potfile);
                            futuresForJson.add( _createJson(locale,pofile).then((final Map<String,String> jsonForLocale) => json[locale] = jsonForLocale));
                        });
                        Future.wait(futuresForJson).then((_) {
                            _createMergedJson(json,config.jsonfile);
                            _createDartFile(json,config.dartfile,libPrefix: config.libprefix);
                        });
                    });
                });
            }
        }

        on FormatException {
            _showUsage();
        }
    }

    // -- private -------------------------------------------------------------

    /// Writes the DART-File - makes translation easy
    void _createDartFile(final Map<String,Map<String,String>> json, final String filename,{ final String libPrefix: "not.defined" } ) {
        Validate.notEmpty(json);
        Validate.notBlank(filename);

        final File dartFile = new File(filename);
        if(!dartFile.existsSync()) {
            dartFile.createSync(recursive: true);
        }

        final StringBuffer buffer = new StringBuffer();

        buffer.writeln("library $libPrefix.locale;\n");
        buffer.writeln('/**');
        buffer.writeln('* DO NOT EDIT. This is code generated with:');
        buffer.writeln('*     projectdir \$ mkl10n .');
        buffer.writeln('*/');
        buffer.writeln("");
        buffer.writeln("import 'package:l10n/l10n.dart';");
        buffer.writeln("\n");
        buffer.write('final L10NTranslate translate = new L10NTranslate.withTranslations( ');
        buffer.write(_makePrettyJsonString(json));
        buffer.writeln(");\n");

        dartFile.writeAsStringSync(buffer.toString());
        _logger.info("Dart-File (${dartFile.path}) created");
    }

    /// message.json in locale, contains all the specified locales
    void _createMergedJson(final Map<String,Map<String,String>> json, final String filename) {
        Validate.notEmpty(json);
        Validate.notBlank(filename);

        final File jsonFile = new File(filename);
        jsonFile.writeAsStringSync(_makePrettyJsonString(json));
        _logger.info("Merged-Json (${jsonFile.path}) created");
    }

    /// Updates your translated PO with new records from .pot-File
    void _mergePO(final File pofile,final File potfile) {
        final ProcessResult result = msgmerge.runSync(['-U', pofile.path, potfile.path]);
        if(result.exitCode != 0) {
            _logger.severe(result.stderr);
        }
        _logger.fine("${pofile.path} merged!");
    }

    /// Mainly a copy of POT File
    File _preparePOFile(final String locale, final File potfile, final String pofilename) {
        final File pofile = new File(pofilename);
        if(!pofile.existsSync()) {
            pofile.createSync(recursive: true);
            final ProcessResult result = msginit.runSync(['--no-translator','--input', potfile.path, '--output', pofile.path, '-l', locale ]);
            if(result.exitCode != 0) {
                _logger.severe(result.stderr);
            } else {
                String contents = pofile.readAsStringSync();

                // msginit tries to find out the content-type with the according locale - today, I think, it's much better to set it to utf-8
                contents = contents.replaceFirst("Content-Type: text/plain; charset=ASCII","Content-Type: text/plain; charset=UTF-8");
                pofile.writeAsStringSync(contents);
            }
        }
        return pofile;
    }

    /// Make sure that the POT-File exists before xgettext
    Future<File> _createPOTFile(final String potfile) {
        final File file = new File(potfile);
        return file.create(recursive: true);
    }

    /// Iterates through dirs and adds the result to the POT-File
    Future<bool> _scanDirsAndFillPOT(final List<String> dirstoscan, final String potfile, final List<String> dirsToExclude) {
        final Future<bool> future = new Future<bool>(() {
            for (final String dir in dirstoscan) {
                _iterateThroughDirSync(dir, dirsToExclude, (final File file) {
                    _logger.fine(" -> ${file.path}");

                    // --from-code ... iconv -l shows all the available codes!
                    String language = 'JavaScript';
                    final ProcessResult result = xgettext.runSync(['-kl10n', '-kL10N', '-k_', '-c' ,
                        '-j', '-o', "$potfile", '-L', language ,
                        '--from-code=utf-8', '--sort-by-file', file.path ]);

                    if (result.exitCode != 0) {
                        _logger.severe("${result.stderr}");
                    }
                });
            }
            return true;
        });

        return future;
    }

    /// Goes through the files
    void _iterateThroughDirSync(final String dir, final List<String> dirsToExclude, void callback(final File file)) {
        _logger.info("Scanning: $dir");

        // its OK if the path starts with packages but not if the path contains packages (avoid recursion)
        final RegExp regexp = new RegExp("^/*packages/*");

        final Directory directory = new Directory(dir);
        if (directory.existsSync()) {
            directory.listSync(recursive: true).where((final FileSystemEntity entity) {
                _logger.fine("Entity: ${entity}");

                bool isUsableFile = (entity != null && FileSystemEntity.isFileSync(entity.path) &&
                    ( entity.path.endsWith(".dart") || entity.path.endsWith(".DART")) || entity.path.endsWith(".html") );

                if(!isUsableFile) {
                    return false;
                }
                if(entity.path.contains("packages")) {
                    // return only true if the path starts!!!!! with packages
                    return entity.path.contains(regexp);
                }

                if(entity.path.startsWith(".pub/") || entity.path.startsWith("./.pub/") ||
                   entity.path.startsWith("build/") || entity.path.startsWith("./build/")){
                    return false;
                }

                for(final String dirToExclude in dirsToExclude) {
                    final String dir = dirToExclude.trim();
                    if(entity.path.startsWith("${dir}/") || entity.path.startsWith("./${dir}/")) {
                        return false;
                    }
                }

                return true;

            }).map((final FileSystemEntity entity) => new File(entity.path))
                .forEach((final File file) {
                _logger.fine("  Found: ${file}");
                callback(file);
            });
        }
    }

    void _showUsage() {
        print(translate(l10n("Usage: mkl10n [options] <dir(s) to scan>")));
        _parser.usage.split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print(translate(l10n("Example:")));
        print("    " + translate(l10n("mkl10n . - Generates lib/locale/messages.dart")));
        print("    " + translate(l10n("mkl10n -l en,de . - Generates translation for en + de")));
        print("");
    }

    void _printSettings(final Map<String,String> settings) {
        Validate.notEmpty(settings);

        int getMaxKeyLength() {
            int length = 0;
            settings.keys.forEach((final String key) => length = max(length,key.length));
            return length;
        }

        final int maxKeyLength = getMaxKeyLength();

        String prepareKey(final String key) {
            return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLength + 1);
        }

        print(translate(l10n("Settings:")));
        settings.forEach((final String key,final String value) {
            print("    ${prepareKey(key)} $value");
        });

        print("");

        // You will see this comment in the .po/.pot-File
        print(translate(l10n("External commands:")));
        [ xgettext, msginit, msgmerge ].forEach((final ShellCommand command) {
            String exe = translate(l10n("not installed!"));
            try {
                exe = command.executable;

            } on StateError catch(_) {}

            print("    ${(command.name + ':').padRight(maxKeyLength + 1)} ${exe}");
        });
    }

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,            abbr: 'h', negatable: false, help: translate(l10n("Shows this message")))
            ..addFlag(_ARG_SETTINGS,        abbr: 's', negatable: false, help: translate(l10n("Prints settings")))

            ..addOption(_ARG_LOCALES,       abbr: 'l', help: translate(l10n("locales - separated by colon, Sample: --locales en,de,es")))
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ info | debug | warning ]")
            ..addOption(_ARG_LIB_PREFIX,    abbr: 'p', help: translate(l10n("Libprefix for generated DART-File (library <prefix>.locale;)")))
            ..addOption(_ARG_LOCALE_DIR,    abbr: 'd', help: translate(l10n("Defines where to place your locale-Dir")))
            ..addOption(_ARG_DART_PATH,     abbr: 'a', help: translate(l10n("Where should the DART-File go? (<path>/locale/messages.dart)")))
            ..addOption(_ARG_EXCLUDE,       abbr: 'x', help: translate(l10n("Exclude folders from scaning")))
        ;

        return parser;
    }

    /// Creates .json-File in the same location where the .po file is
    Future<HashMap<String,String>> _createJson(final String locale,final File pofile) {
        final Completer<Map<String,String>> completer = new Completer<Map<String,String>>();

        final Map<String,Map<String,String>> json = new HashMap<String,Map<String,String>>();
        json[locale] = new SplayTreeMap<String,String>((final String key1,final String key2) {
            // sort case insensitive
            return key1.toLowerCase().compareTo(key2.toLowerCase());
        });

        if(pofile.existsSync()) {
            final File jsonFile = new File(pofile.path.replaceFirst(new RegExp("\.po"),".json"));
            if(jsonFile.existsSync()) {
                jsonFile.deleteSync();
            }
            jsonFile.createSync(recursive: true);

            pofile.readAsString().then((final String content) {

                // There is always a newline between the msg-blocks, so split there
                final List<String> msgblocks = content.split(new RegExp("(\r\n|\n){2}"));

                String _sanitize(final String value) {
                    return value.replaceFirst("msgid","").trim().replaceFirst(new RegExp("^\""),"").replaceFirst(new RegExp('"\$'),"").trim();
                }
                // If there is a header - skip it!
                final bool skipHeader = content.contains("Project-Id-Version");
                msgblocks.skip(skipHeader ? 1 : 0).where((final String block) => block.trim().isNotEmpty)
                        .forEach((final String block) {
                    final String withoutcomment = block.replaceAll(new RegExp("#.*(\r\n|\n)"),"");
                    final List<String> message = withoutcomment.split("msgstr");

                    if(withoutcomment.isNotEmpty) {
                        final String key = _sanitize(message[0].replaceFirst("msgid", ""));
                        final String value = _sanitize(message[1]);

                        json[locale][key] = value;
                    }
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

    void _configLogging(final String loglevel) {
        Validate.notBlank(loglevel);

        hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

        // now control the logging.
        // Turn off all logging first
        switch(loglevel) {
            case "fine":
            case "debug":
                Logger.root.level = Level.FINE;
                break;

            case "warning":
                Logger.root.level = Level.SEVERE;
                break;

            default:
                Logger.root.level = Level.INFO;
        }

        Logger.root.onRecord.listen(new LogPrintHandler(messageFormat: "%m"));
    }
}

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("mkl10llocale.Config");

    static const String _KEY_LOCALE_DIR     = "localeDir";
    static const String _KEY_TEMPLATES_DIR  = "templatesDir";
    static const String _KEY_POT_FILENAME   = "potfile";
    static const String _KEY_PO_FILENAME    = "pofile";
    static const String _KEY_JSON_FILENAME  = "jsonfilename";
    static const String _KEY_DART_FILENAME  = "dartfilename";
    static const String _KEY_LIB_PREFIX     = "libprefix";
    static const String _KEY_LOGLEVEL       = "loglevel";
    static const String _KEY_LOCALES        = "locales";
    static const String _KEY_DART_PATH      = "dartpath";
    static const String _KEY_SYSTEM_LOCALE  = "systemlocale";
    static const String _KEY_EXCLUDE_DIRS   = "exclude_dirs";

    final ArgResults _argResults;
    final Map<String,String> _settings = new Map<String,String>();

    Config(this._argResults,final String systemLocale) {

        _settings[_KEY_LOCALE_DIR]      = 'locale';
        _settings[_KEY_TEMPLATES_DIR]   = 'templates/LC_MESSAGES';

        _settings[_KEY_POT_FILENAME]    = 'messages.pot';
        _settings[_KEY_PO_FILENAME]     = 'messages.po';

        _settings[_KEY_JSON_FILENAME]   = 'messages.json';
        _settings[_KEY_DART_FILENAME]   = 'messages.dart';

        _settings[_KEY_LIB_PREFIX]      = 'l10n';
        _settings[_KEY_LOGLEVEL]        = 'info';


        _settings[_KEY_DART_PATH]       = 'lib';

        _settings[_KEY_LOCALES]         = Intl.shortLocale(systemLocale);
        _settings[_KEY_SYSTEM_LOCALE]   = systemLocale;
        
        _settings[_KEY_EXCLUDE_DIRS]    = '';

        initializeDateFormatting(_settings[_KEY_SYSTEM_LOCALE],null);

        _overwriteSettingsWithConfigFile();
        _overwriteSettingsWithArgResults();
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
    String get dartfile => "${_settings[_KEY_DART_PATH]}/${_settings[_KEY_LOCALE_DIR]}/${_settings[_KEY_DART_FILENAME]}";

    String get libprefix => _settings[_KEY_LIB_PREFIX];

    String get loglevel => _settings[_KEY_LOGLEVEL];

    String get locales => _settings[_KEY_LOCALES];

    String get systemLocale => _settings[_KEY_SYSTEM_LOCALE];
    
    List<String> get excludeDirs => _settings[_KEY_EXCLUDE_DIRS].split(new RegExp(r",\s*"));

    String get configfile => ".mkl10n.yaml";

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        settings[translate(l10n("Config-File"))]  = configfile;

        settings["POT-File"]                                    = potfile;
        settings["PO-File"]                                     = getPOFile("<locale>");
        settings["JSON-File"]                                   = jsonfile;
        settings["DART-File"]                                   = dartfile;
        settings["libprefix (${Config._KEY_LIB_PREFIX})"]       = libprefix;
        settings["loglevel"]                                    = loglevel;
        settings["locales"]                                     = locales;
        settings["System-Locale"]                               = systemLocale;

        if(dirstoscan.length > 0) {
            settings[translate(l10n("Dirs to scan"))] = dirstoscan.join(", ");
        }
        settings[translate(l10n("Dirs to exclude"))
            + " (${Config._KEY_EXCLUDE_DIRS})"]  = excludeDirs.join(", ");

        return settings;
    }

    // -- private -------------------------------------------------------------

    _overwriteSettingsWithArgResults() {

        /// Makes sure that path does not end with a /
        String checkPath(final String arg) {
            String path = arg;
            if(path.endsWith("/")) {
                path = path.replaceFirst(new RegExp("/\$"),"");
            }
            return path;
        }

        if(_argResults[Application._ARG_LOGLEVEL] != null) {
            _settings[_KEY_LOGLEVEL] = _argResults[Application._ARG_LOGLEVEL];
        }

        if(_argResults[Application._ARG_LIB_PREFIX] != null) {
            _settings[_KEY_LIB_PREFIX] = _argResults[Application._ARG_LIB_PREFIX];
        }

        if(_argResults[Application._ARG_LOCALE_DIR] != null) {
            _settings[_KEY_LOCALE_DIR] = "${checkPath(_argResults[Application._ARG_LOCALE_DIR])}/${_settings[_KEY_LOCALE_DIR]}";
        }

        if(_argResults[Application._ARG_LOCALES] != null) {
            _settings[_KEY_LOCALES] = _argResults[Application._ARG_LOCALES];
        }

        if(_argResults[Application._ARG_DART_PATH] != null) {
            _settings[_KEY_DART_PATH] = checkPath(_argResults[Application._ARG_DART_PATH]);
        }

        if(_argResults[Application._ARG_DART_PATH] != null) {
            _settings[_KEY_DART_PATH] = checkPath(_argResults[Application._ARG_DART_PATH]);
        }

        if(_argResults[Application._ARG_EXCLUDE] != null) {
            _settings[_KEY_EXCLUDE_DIRS] = checkPath(_argResults[Application._ARG_EXCLUDE]);
        }
    }

    void _overwriteSettingsWithConfigFile() {
        final File file = new File(configfile);
        if(!file.existsSync()) {
            return;
        }
        final yaml.YamlMap map = yaml.loadYaml(file.readAsStringSync());
        _settings.keys.forEach((final String key) {
            if(map != null && map.containsKey(key)) {
                _settings[key] = map[key];
                print("Found $key in $configfile: ${map[key]}");
            }
        });
    }


}

void main(List<String> arguments) {

    findSystemLocale().then((final String locale) {
        translate.locale = Intl.shortLocale(locale);

        final Application application = new Application();
        application.run( arguments, locale );
    });

    /// only for testing
    // final L10N l1 = const L10N("Ein TEST - 290714 1648");
}

