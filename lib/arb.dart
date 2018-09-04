library l10n.arb;

import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:logging/logging.dart';
import 'package:intl_translation/extract_messages.dart';
import 'package:intl_translation/src/intl_message.dart';

import 'package:l10n/utils.dart' as utils;

import "package:validate/validate.dart";

export 'package:intl_translation/extract_messages.dart' ;

part 'arb/ARB.dart';

final Logger _logger = new Logger("l10n.arb");

/// Iterates through dirs and generates a map of [MainMessage]s
Future<Map<String, MainMessage>> scanDirsAndGenerateARBMessages(
    MessageExtraction extractor(),
    final List<String> dirstoscan, final List<String> dirsToExclude) {

    Validate.notNull(extractor());
    Validate.notEmpty(dirstoscan);
    Validate.notNull(dirsToExclude);

    final extraction = extractor();
    final allMessages = Map<String, MainMessage>(); // Map<dynamic, dynamic>(); // Map<String, MainMessage>();

    final future = new Future<Map<String, MainMessage>>(() async {
        for (final String dir in dirstoscan) {
            utils.iterateThroughDirSync(dir, [ ".dart" ], dirsToExclude, (final File file) {
                _logger.info("  -> ${file.path}");

                //final String filename = file.path;

                final Map<String, MainMessage> messages  = extraction.parseFile(file);
                allMessages.addAll(messages);

            });
        }

        return allMessages;
    });

    return future;
}

/// Generates the base .arb-File
///
/// By default this is l10n/intl_messages.arb
void writeMessagesToOutputFile(
    final Directory dir,
    final File file,
    final Map<String,MainMessage> allMessages) {

    Validate.notNull(dir);
    Validate.notNull(file);
    Validate.notNull(allMessages);

    final messages = {};
    final arb = _ARB();

    if(!dir.existsSync()) {
        dir.createSync(recursive: true);
    }

    final fullPath = File(path.join(dir.path,file.path));

    messages["@@last_modified"] = new DateTime.now().toIso8601String();
    allMessages.forEach((final String k, final MainMessage v) {
        messages.addAll(arb.toJSON((v)));
    });

    fullPath.writeAsStringSync(utils.makePrettyJsonString(messages));
}

/// Bases on intl_messages.arb a translatable file gets create
/// if it doesn't exist
///
/// E.g. if the locale is "de" this creates intl_de.arb
void generateTranslationFile(
    final Directory dir,
    final File file,
    final String locale,
    final Map<String,MainMessage> allMessages) {

    Validate.notNull(dir);
    Validate.notNull(file);
    Validate.notBlank(locale);
    Validate.notNull(allMessages);

    final fullPath = File(path.join(dir.path,file.path));

    if(fullPath.existsSync()) {
        _logger.warning("Localized file already existst! (${fullPath.path})");
        return;
    }

    final messages = {};
    final arb = _ARB();

    messages["@@last_modified"] = new DateTime.now().toIso8601String();
    messages["@@locale"] = locale;

    allMessages.forEach((final String k, final MainMessage v) {
        messages.addAll(arb.toJSON((v)));
    });

    fullPath.writeAsStringSync(utils.makePrettyJsonString(messages));
}
