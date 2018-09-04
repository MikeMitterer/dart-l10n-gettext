library l10n.codegen;

import "dart:collection";
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl_translation/extract_messages.dart';
import 'package:intl_translation/generate_localized.dart';
import 'package:intl_translation/src/intl_message.dart';
import 'package:intl_translation/src/icu_parser.dart';

import 'utils.dart' as utils;

const jsonDecoder = const JsonCodec();

final pluralAndGenderParser = new IcuParser().message;
final plainParser = new IcuParser().nonIcuMessage;

typedef Map<String, List<MainMessage>> ProcessedMessages();

generateDartCode(
    MessageGeneration generator(),
    final String arbDir,
    final String targetDir,
    final Map<String,MainMessage> allMessages, final List<String> filesToExclude) {

    // Keeps track of all the messages we have processed so far, keyed by message name.
    final messages = Map<String, List<MainMessage>>();

    allMessages.forEach((final String key,value) {
        messages.putIfAbsent(key, () => []).add(value);
    });

    final generation = generator();

    final dir = Directory(targetDir);
    if(!dir.existsSync()) { dir.createSync(recursive: true); }

    utils.iterateThroughDirSync(arbDir, [ ".arb" ], [], (final File file) {
        if(!filesToExclude.contains(path.basename(file.path))) {
            _generateLocaleFile( file, targetDir, generation ,() => messages);
        }
    });

    var mainImportFile = new File(path.join(
        targetDir, '${generation.generatedFilePrefix}messages_all.dart'));

    mainImportFile.writeAsStringSync(generation.generateMainImportFile());
}

/// Create the file of generated code for a particular locale. We read the ARB
/// data and create [BasicTranslatedMessage] instances from everything,
/// excluding only the special _locale attribute that we use to indicate the
/// locale. If that attribute is missing, we try to get the locale from the last
/// section of the file name.
void _generateLocaleFile(
    final File file,
    final String targetDir,
    final MessageGeneration generation,
    final ProcessedMessages messages) {

    final src = file.readAsStringSync();
    final data = jsonDecoder.decode(src);
    var locale = data["@@locale"] ?? data["_locale"];
    if (locale == null) {
        // Get the locale from the end of the file name. This assumes that the file
        // name doesn't contain any underscores except to begin the language tag
        // and to separate language from country. Otherwise we can't tell if
        // my_file_fr.arb is locale "fr" or "file_fr".
        var name = path.basenameWithoutExtension(file.path);
        locale = name.split("_").skip(1).join("_");
        print("No @@locale or _locale field found in $name, "
            "assuming '$locale' based on the file name.");
    }
    generation.allLocales.add(locale);

    List<TranslatedMessage> translations = [];
    data.forEach((id, messageData) {
        final TranslatedMessage message = _recreateIntlObjects(id, messageData, messages);
        if (message != null) {
            translations.add(message);
        }
    });
    generation.generateIndividualMessageFile(locale, translations, targetDir);
}

/// Regenerate the original IntlMessage objects from the given [data]. For
/// things that are messages, we expect [id] not to start with "@" and
/// [data] to be a String. For metadata we expect [id] to start with "@"
/// and [data] to be a Map or null. For metadata we return null.
BasicTranslatedMessage _recreateIntlObjects(
    final String id,
    final data,
    final ProcessedMessages messages) {

    if (id.startsWith("@")) return null;
    if (data == null) return null;

    var parsed = pluralAndGenderParser.parse(data).value;
    if (parsed is LiteralString && parsed.string.isEmpty) {
        parsed = plainParser.parse(data).value;
    }

    return new BasicTranslatedMessage(id, parsed, messages);
}

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our [messages].
class BasicTranslatedMessage extends TranslatedMessage {

    /// Callback that returns all processed messages
    final ProcessedMessages messages;

    BasicTranslatedMessage(final String name,final translated,this.messages)
        : super(name, translated);

    List<MainMessage> get originalMessages => (super.originalMessages == null)
        ? _findOriginals()
        : super.originalMessages;

    // We know that our [id] is the name of the message, which is used as the
    // key in [messages]. (id == name)
    List<MainMessage> _findOriginals() => originalMessages = messages()[id];
}
