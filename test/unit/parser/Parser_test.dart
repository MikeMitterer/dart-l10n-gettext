library test.unit.lexer;

import 'dart:io';
import 'package:test/test.dart';

import 'package:logging/logging.dart';
import 'package:l10n/parser.dart';

import '../config.dart';

class _TestPrintVisitor extends Visitor {
  final Logger _logger = new Logger('test.unit.lexer._TestVisitor');
    
  final String filename;

  _TestPrintVisitor(this.filename);

  @override
  void visitComment(final CommentStatement statement) {
      final List<String> lines = statement.comment.split(new RegExp(r"\n"));
      lines.forEach((final String line) => _logger.fine("#. ${line.trimLeft()}"));
  }

  @override
  void visitL10n(final L10NStatement statement) {
    _logger.fine("#: ${filename}:${statement.line}");
    _logger.fine('msgid "${statement.msgid}"');
    _logger.fine('msgstr ""');
    _logger.fine('');
  }
}

void _TestPrintPOTVisitor(
    final List<CommentStatement> comments,
    final List<L10NStatement> statements) {

    final Logger _logger = new Logger("test.unit.parser._TestPrintPOTVisitor");

    comments.forEach((final CommentStatement statement) {
        final List<String> lines = statement.comment.split(new RegExp(r"\n"));
        lines.forEach((final String line) => _logger.fine("#. ${line.trimLeft()}"));
    });
    statements.forEach((final L10NStatement statement) {
        _logger.fine("#: ${statement.filename}:${statement.line}");
    });
    _logger.fine('msgid "${statements.first.msgid}"');
    _logger.fine('msgstr ""');
    _logger.fine('');
}

main() async {
    //final Logger _logger = new Logger("test.unit.parser");
    
    configLogging();

    final String source = new File("test/unit/_resources/login.dart.txt").readAsStringSync();

    group('Lexer', () {
        setUp(() { });

        test('> Scan', () {
            final Lexer lexer = new Lexer();
            final List<Token> tokens = lexer.scan(source);

            _logTokes(tokens);
            final int nrOfComments = tokens.where((final Token token) =>
                token.type == TokenType.COMMENT).length;

            final int nrOfFunctions = tokens.where((final Token token) =>
            token.type == TokenType.L10N).length;

            expect(nrOfComments, equals(14));
            expect(nrOfFunctions, equals(12));
        }); // end of 'Test' test
    });
    // End of 'Parser' group

    group('Parser', () {
        setUp(() {});

        test('> Parse', () {
            final String filename = "test.dart";
            final Lexer lexer = new Lexer();
            final Parser parser = new Parser();

            final List<Token> tokens = lexer.scan(source);

            final List<Statement> statements = parser.parse(filename, tokens);
            
            expect(statements.where((final Statement statement)
                => !(statement is NewLineStatement)).length, equals(26));

            final Visitor visitor = new _TestPrintVisitor(filename);

            // A "block" means:
            // #. HTML-Kommentar
            // #: test.dart:103
            // msgid "Test 10: 12345678aA16#"
            // msgstr ""
            //
            final List<POTBlock> blocks = collectPOTBlocks(statements);
            expect(blocks.length, 12);

            // Prints all the blocks if logging is set to 'FINE'
            blocks.forEach((final POTBlock block) {
                block.comments.forEach((final CommentStatement comment) => comment.accept(visitor));
                block.statement.accept(visitor);
            });

        }); // end of 'Parse' test

    }); // End of '' group

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
                block.visit(_TestPrintPOTVisitor);
            });

            expect(blocks.length, 12);

        }); // end of 'Merge' test


    });
}

void _logTokes(final List<Token> tokens) {
    final Logger _logger = new Logger("test.unit.parser._logTokes");

    tokens.forEach((final Token token) {
        switch(token.type) {

            case TokenType.L10N:
            case TokenType.COMMENT:
                _logger.fine("${token.type.toString().padRight(20)} -> Text: ${token.text}");
                break;

            default:
                _logger.finer("${token.type.toString().padRight(20)} -> Text: ${token.text}");
                break;
        }
    });
}