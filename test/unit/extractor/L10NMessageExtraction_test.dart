// @TestOn("browser")
// unit
@TestOn("vm")
library test.unit.l10nmessageextraction;

import 'dart:io';

import 'package:intl_translation/src/intl_message.dart';

import 'package:test/test.dart';
import 'package:l10n/extractor.dart';

// import 'package:logging/logging.dart';
import 'package:console_log_handler/print_log_handler.dart';

main() async {
    final Logger _logger = new Logger("test.unit.l10nmessageextraction");

    configLogging(show: Level.FINE);
    //await saveDefaultCredentials();

    final extractor = L10NMessageExtraction();

    group('L10NMessageExtraction.dart', () {
        setUp(() {});

        test('> parse file', () {
            final Map<String, MainMessage> messages =
                extractor.parseFile(File("test/unit/_resources/test-l10n-login.dart"));

            expect(messages, isNotNull);
            expect(messages.length, 7);

            messages.forEach((final String key, final Message message) {
                _logger.info("K $key, M ${(message as MainMessage).toString()}");
            });

        }); // end of 'parse file' test

    });
    // End of 'L10NMessageExtraction.dart' group
}

// - Helper --------------------------------------------------------------------------------------
