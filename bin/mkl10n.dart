library l10n.app;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart' as yaml;
import 'package:validate/validate.dart';
import 'package:where/where.dart';

import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl_translation/extract_messages.dart';
import 'package:intl_translation/src/intl_message.dart';
import 'package:intl_translation/generate_localized.dart';
import 'package:path/path.dart' as path;

import 'package:logging/logging.dart';
import 'package:console_log_handler/print_log_handler.dart';

import 'package:l10n/l10n.dart';
import 'package:l10n/locale/messages.dart';
import 'package:l10n/arb.dart' as arb;
import 'package:l10n/codegen.dart';
import 'package:l10n/extractor.dart';

import 'package:l10n/_l10n/messages_all.dart';

part 'argparser/Config.dart';
part 'argparser/Options.dart';

part 'commands/ShellCommand.dart';
part 'commands/commands.dart';

class Application {
    // final Logger _logger = new Logger("l10n.Application");

    /// Commandline options
    final _options = new Options();

    Future run(List<String> args,final String locale) async {
        Validate.notBlank(locale);

        try {
            final ArgResults argResults = _options.parse(args);
            final Config config = new Config(argResults,locale);

            _configLogging(config.loglevel);

            if (argResults[Options._ARG_HELP]) {
                _options.showUsage();

            } else if(argResults[Options._ARG_SETTINGS]) {
                config.printSettings(config.settings);

            } else if(config.dirstoscan.isEmpty) {
                _options.showUsage();
            }
            else {
                final Map<String,MainMessage> allMessages = await arb.scanDirsAndGenerateARBMessages(
                    () {
                        return MessageExtraction()
                            ..suppressWarnings = config.suppressWarnings
                        ;
                    },
                    () => L10NMessageExtraction(),
                    () => HTMLExtraction(),
                    config.dirstoscan,config.excludeDirs);

                arb.writeMessagesToOutputFile(Directory(config.outputDir), File(config.outputFile), allMessages);

                final List<String> locales = config.locales.split(',')
                    .map((final String locale) => locale.trim()).toList();

                locales.forEach((final String locale) {
                    arb.generateTranslationFile(
                        Directory(config.outputDir),
                        File(config.outputFile.replaceAll("_messages", "_${locale}")),
                        locale, allMessages,config.overwriteLocaleFile);
                });

                generateDartCode(() {
                    return MessageGeneration()
                        ..useDeferredLoading = config.useDeferredLoading
                        ..codegenMode = config.codegenMode
                    ;
                }, config.outputDir, config.codegenDir,
                        allMessages, [ config.outputFile ]);

            }
        }

        on FormatException {
            _options.showUsage();
        }
    }

    // -- private -------------------------------------------------------------

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
    findSystemLocale().then((final String locale) async {
        translate.locale = Intl.shortLocale(locale);

        // Avoids error message:
        //      LocaleDataException: Locale data has not been initialized,
        //      call initializeDateFormatting(<locale>).
        await initializeDateFormatting(locale);

        // Initialize translation-table
        await initializeMessages(Intl.shortLocale(locale));

        final Application application = new Application();
        application.run( arguments, locale );
    });

    /// only for testing
    // final L10N l1 = const L10N("Ein TEST - 290714 1648");
}

