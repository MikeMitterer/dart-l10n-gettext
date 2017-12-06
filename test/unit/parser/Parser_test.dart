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
    if(statement.params.length > 1) {
        _logger.fine('msgid_plural "${statement.params[1]}"');
    }

    _logger.fine('msgstr ""');
    _logger.fine('');
  }
}


main() async {
    final Logger _logger = new Logger("test.unit.parser");

    // If you want to see some log outptut set "defaultLogLevel:"
    // to Level.FINE or Level.FINER
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

            expect(nrOfComments, equals(15));
            // 14 - but one is a function declaration!
            expect(nrOfFunctions, equals(14));

            final int nrOfLeftBracket = tokens.where((final Token token) =>
            token.type == TokenType.LEFT_BRACKET).length;

            final int nrOfRightBracket = tokens.where((final Token token) =>
            token.type == TokenType.RIGHT_BRACKET).length;

            expect(nrOfLeftBracket, nrOfRightBracket);

            final int nrOfScopeBegin = tokens.where((final Token token) =>
            token.type == TokenType.SCOPE_BEGIN).length;

            final int nrOfScopeEnd = tokens.where((final Token token) =>
            token.type == TokenType.SCOPE_END).length;

            expect(nrOfScopeBegin, nrOfScopeEnd);

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
            // _logTokes(tokens);
            
            final List<Statement> statements = parser.parse(filename, tokens);

            // statements.where((final Statement statement)
            //     => !(statement is NewLineStatement)).forEach( (final Statement statement) {
            //         _logger.fine(statement);
            // });

            expect(statements.where((final Statement statement)
                => !(statement is NewLineStatement)).length, equals(28));

            final Visitor visitor = new _TestPrintVisitor(filename);

            // A "block" means:
            // #. HTML-Kommentar
            // #: test.dart:103
            // msgid "Test 10: 12345678aA16#"
            // msgstr ""
            //
            final List<POTBlock> blocks = collectPOTBlocks(statements);
            expect(blocks.length, 13);

            expect(blocks[12].comments.length, 0);
            expect(blocks[12].statement.msgid, "Test 13: Sign in");

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