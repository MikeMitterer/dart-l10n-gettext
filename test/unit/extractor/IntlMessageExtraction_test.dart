// @TestOn("browser")
// unit
@TestOn("vm")
library test.unit.l10nmessageextraction;

import 'dart:io';

import 'package:intl_translation/src/intl_message.dart';
import 'package:intl_translation/extract_messages.dart';

import 'package:test/test.dart';
//import 'package:in/extractor.dart';

// import 'package:logging/logging.dart';
import 'package:console_log_handler/print_log_handler.dart';

main() async {
    final Logger _logger = new Logger("test.unit.intlmessageextraction");

    configLogging(show: Level.FINE);
    //await saveDefaultCredentials();

    final extractor = MessageExtraction();

    group('IntlMessageExtraction.dart', () {
        setUp(() {});

        test('> parse file', () {
            final Map<String, MainMessage> messages =
                extractor.parseFile(File("test/unit/_resources/test-intlmsg-login.dart"));

            expect(messages, isNotNull);
            expect(messages.length, 6);

            extractor.suppressWarnings = true;
            messages.forEach((final String key, final Message message) {
                _logger.info("K $key, M ${(message as MainMessage).toString()}");
            });

        }); // end of 'parse file' test

    });
    // End of 'L10NMessageExtraction.dart' group
}

// - Helper --------------------------------------------------------------------------------------
