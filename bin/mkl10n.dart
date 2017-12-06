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
import 'package:console_log_handler/print_log_handler.dart';

import 'package:l10n/l10n.dart';
import 'package:l10n/locale/messages.dart';
import 'package:l10n/parser.dart';

part 'argparser/Config.dart';
part 'argparser/Options.dart';

part 'commands/ShellCommand.dart';
part 'commands/commands.dart';

class Application {
    final Logger _logger = new Logger("l10n.Application");

    /// Commandline options
    final Options _options = new Options();

    Future run(List<String> args,final String locale) async {
        Validate.notBlank(locale);

        try {
            final ArgResults argResults = _options.parse(args);
            final Config config = new Config(argResults,locale);

            _configLogging(config.loglevel);

            if (argResults[Options._ARG_HELP] || (config.dirstoscan.length == 0 && args.length == 0)) {
                _options.showUsage();

            } else if(argResults[Options._ARG_SETTINGS]) {
                config.printSettings(config.settings);

            }
            else {
                await _createPOTHeaderTemplate(config.headerTemplateFile);
                final File potfile = await _createPOTFile(config.potfile);
                await _scanDirsAndFillPOTWithXGetText(config.dirstoscan,config.potfile, config.excludeDirs);

                await _scanDirsAndFillPOTWithParser(config.dirstoscan,
                    config.potfile, config.headerTemplateFile,config.excludeDirs);

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

            }
        }

        on FormatException {
            _options.showUsage();
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
    Future<File> _createPOTFile(final String potfile) async {
        final File file = new File(potfile);
        final File fileGetText = new File(potfile.replaceFirst(new RegExp(r"\.pot$"), ".gettext.pot"));

        await fileGetText.create(recursive: true);
        return file.create(recursive: true);


    }

    /// If the header-Template does not exist - it will be created
    Future _createPOTHeaderTemplate(final String templateName) async {
        final File file = new File(templateName);
        final String template = '''
            # SOME DESCRIPTIVE TITLE.
            # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
            # This file is distributed under the same license as the PACKAGE package.
            # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
            #
            msgid ""
            msgstr ""
            "Project-Id-Version: PACKAGE VERSION\\n"
            "Report-Msgid-Bugs-To: \\n"
            "POT-Creation-Date: {date}\\n"
            "PO-Revision-Date: YEAR-MO-DA HO:MI\\n"
            "Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
            "Language-Team: LANGUAGE <LL@li.org>\\n"
            "Language: \\n"
            "MIME-Version: 1.0\\n"
            "Content-Type: text/plain; charset=UTF-8\\n"
            "Content-Transfer-Encoding: 8bit\\n"        
        '''.replaceAll(new RegExp(r"^\s*",multiLine: true), "")
            .replaceFirst(new RegExp(r"\n$",multiLine: true), "");

        if(! await file.exists()) {
            await file.create(recursive: true);
            await file.writeAsString(template,flush: true);
        }
    }

    /// Iterates through dirs and adds the result to the POT-File
    Future<bool> _scanDirsAndFillPOTWithXGetText(final List<String> dirstoscan,
        String potfile, final List<String> dirsToExclude) {

        potfile = potfile.replaceFirst(new RegExp(r"\.pot$"), ".gettext.pot");
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

    /// Iterates through dirs and adds the result to the POT-File
    Future<bool> _scanDirsAndFillPOTWithParser(final List<String> dirstoscan,
        final String potfile, final String headerTemplate, final List<String> dirsToExclude) {

        final Lexer lexer = new Lexer();
        final Parser parser = new Parser();
        final POT pot = new POT();

        final Future<bool> future = new Future<bool>(() async {
            for (final String dir in dirstoscan) {
                _iterateThroughDirSync(dir, dirsToExclude, (final File file) {
                    _logger.finer("  -> ${file.path}");

                    final String filename = file.path;

                    final String source = new File(filename).readAsStringSync();
                    final List<Token> tokens = lexer.scan(source);
                    final List<Statement> statements = parser.parse(filename, tokens);
                    final List<POTBlock> blocks = collectPOTBlocks(statements);

                    if(blocks.length > 0) {
                        _logger.finer("    #${blocks.length} Translation-Blocks found in ${filename}");
                        pot.addBlocks(blocks);
                    }
                });
            }

            await pot.write(potfile,headerTemplate);
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
                _logger.finer("Entity: ${entity}");

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
                    entity.path.startsWith(".git/") || entity.path.startsWith("./.git/") ||
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
            case "finer":
                Logger.root.level = Level.FINER;
                break;

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

        Logger.root.onRecord.listen(logToConsole);
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

