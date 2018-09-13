// @TestOn("browser")
// unit
@TestOn("vm")
library test.unit.htmlextraction;

import 'dart:io';

import 'package:test/test.dart';
import 'package:intl_translation/src/intl_message.dart';
import 'package:console_log_handler/print_log_handler.dart';
import 'package:l10n/parser.dart' as l10n;
import 'package:l10n/extractor.dart';

main() async {
    // final Logger _logger = new Logger("test.unit.htmlextraction");

    configLogging();
    //await saveDefaultCredentials();

    final String filename = "test/unit/_resources/test-l10n-login.dart";
    final String source = new File(filename).readAsStringSync();

    final startTag = r'<div class="mdl-dialog login-dialog1">';
    final endTag = r'</div>';

    group('HTMLExtraction', () {
        String contents = "";
        setUp(() {
            final re = RegExp("${startTag}(?:\\s|.)*${endTag}", multiLine: true, caseSensitive: false);
            contents = re.firstMatch(source).group(0);
        });

        test('> extract messages with Visitor', () {
            final List<l10n.Statement> ast
                = _parseCompilationUnit(contents, filename);

            final visitor = L10NStatementVisitor(filename);

            ast.where((final l10n.Statement statement) => statement is l10n.L10NStatement)
                .toList().forEach((final l10n.Statement statement) => statement.accept(visitor));

            expect(visitor.messages, isNotEmpty);
            expect(visitor.messages.length, 6);
            // visitor.messages.forEach((final String key, final MainMessage message) {
            //    _logger.info(message);
            // });

        }); // end of 'extract messages' test

        test('> extract messages with Extractor (HTMLExtraction)', () {
            final extractor = HTMLExtraction();
            final Map<String,MainMessage> messages = extractor.parseFile(File(filename));

            expect(messages, isNotEmpty);
            expect(messages.length, 6);

        }); // end of 'extract messages with Extractor (HTMLExtraction)' test

    });
    // End of 'HTMLExtraction' group
}

// - Helper --------------------------------------------------------------------------------------

List<l10n.Statement> _parseCompilationUnit(final String contents, final String origin) {
    final lexer = l10n.Lexer();
    final parser = l10n.Parser();

    final List<l10n.Token> tokens = lexer.scan(contents);
    return parser.parse(origin, tokens);
}

