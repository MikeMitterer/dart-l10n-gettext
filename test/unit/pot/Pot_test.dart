@TestOn("vm")
library test.unit.lexer;

import 'dart:io';
import 'package:test/test.dart';

import 'package:logging/logging.dart';
import 'package:console_log_handler/print_log_handler.dart';
import 'package:l10n/parser.dart';
import 'package:l10n/pot.dart';

main() async {
    //final Logger _logger = new Logger("test.unit.parser");

    // If you want to see some log outptut set "defaultLogLevel:"
    // to Level.FINE or Level.FINER
    configLogging(show: Level.INFO);

    final String source = new File("test/unit/_resources/test-l10n-login.dart").readAsStringSync();

    group('POT', () {
        setUp(() {});

        test('> Merge', () {
            final Lexer lexer = new Lexer();
            final Parser parser = new Parser();
            final POT pot = new POT();

            String filename = "test.dart";
            final List<Token> tokens = lexer.scan(source);

            final List<Statement> statements = parser.parse(filename, tokens);
            final List<POTBlock> blocks = collectPOTBlocks(statements);

            pot.addBlocks(blocks);
            pot.addBlocks(blocks);

            pot.mergedBlocks.values.forEach((final MergedPOTBlock block) {
                // Shows its output only it the loglevel is set to Level.FINE
                block.visit(LogPOTVisitor);
            });

            expect(blocks.length, 13);

            expect(pot.mergedBlocks.length, 13);
            expect(pot.mergedBlocks.values.last.comments.length, 0);
            expect(pot.mergedBlocks.values.last.statements.length, 2);
            expect(pot.mergedBlocks.values.last.statements.first.msgid, "Test 13: Sign in");

        }); // end of 'Merge' test


    });
}
