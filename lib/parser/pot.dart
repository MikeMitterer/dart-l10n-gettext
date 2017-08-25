/*
 * Copyright (c) 2017, Michael Mitterer (office@mikemitterer.at),
 * IT-Consulting and Development Limited.
 *
 * All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of l10n.parser;

typedef void POTVisitor(
            final List<CommentStatement> comments,
            final List<L10NStatement> statements
);

/// A POTBlock is something like this
///
///      #. HTML-Kommentar
///      #: test.dart:103
///      msgid "Test 10: 12345678aA16#"
///      msgstr ""
///
class POTBlock {
    final List<CommentStatement> comments;
    final L10NStatement statement;

    POTBlock(this.comments, this.statement);
}

/// Multiple [POTBlock] with the same msgid merged into one block
class MergedPOTBlock {
    final List<CommentStatement> comments = new List<CommentStatement>();
    final List<L10NStatement> statements = new List<L10NStatement>();

    void merge(
        final List<CommentStatement> comments,
        final L10NStatement statement) {

        this.comments.addAll(comments);
        this.statements.add(statement);
    }

    void visit(final POTVisitor potVisitor) {
        final String msgid = statements.first.msgid;
        statements.forEach((final L10NStatement statement) {
            Validate.isTrue(msgid == statement.msgid,
                "All statements must have the samem 'msgid'! "
                "(${msgid} != ${statement.msgid})");
        });
        potVisitor(comments,statements);
    }
}

/// Pump all [Statement] into a single list
List<POTBlock> collectPOTBlocks(final List<Statement> statements) {
    final List<POTBlock> blocks = new List<POTBlock>();

    for(int index = 0;index < statements.length;index++) {
        final Statement statement = statements[index];

        List<CommentStatement> _getComments() {
            final List<CommentStatement> comments = new List<CommentStatement>();
            if((statements[index - 1] is CommentStatement)) {
                comments.add(statements[ index - 1]);
            } else if(index > 1 && statements[index - 1] is NewLineStatement
                && statements[index - 2] is CommentStatement){
                comments.add(statements[ index - 2]);
            }
            return comments;
        }

        if(statement is L10NStatement) {
            final List<CommentStatement> comments = _getComments();
            blocks.add(new POTBlock(comments, statement));
        }
    }

    return blocks;
}

/// Creates the POT-File
class POT {
    final Logger _logger = new Logger('l10n.parser.POT');

    final Map<String,MergedPOTBlock> mergedBlocks = new Map<String,MergedPOTBlock>();


    void addBlocks(final List<POTBlock> blocks) {
        blocks.forEach((final POTBlock block) {
            if(!mergedBlocks.containsKey(block.statement.msgid)) {
                mergedBlocks[block.statement.msgid] = new MergedPOTBlock();

            }
            final MergedPOTBlock mergedPOTBlock = mergedBlocks[block.statement.msgid];
            mergedPOTBlock.merge(block.comments, block.statement);
        });
    }

    Future write(final String potFile, final String potTemplateHeader) async {
        final String header = await _getHeader(potTemplateHeader);
        final File file = new File(potFile);

        if(await file.exists()) {
            await file.delete();
        }


        _logger.fine(header);
        _logger.fine("");

        await file.writeAsString(header + "\n\n",flush: true);

        mergedBlocks.values.forEach((final MergedPOTBlock block) {
            // Shows its output only it the loglevel is set to Level.FINE
            block.visit(WritePOTVisitor(_logger, file));
        });

    }

    // - private -----------------------------------------------------------------------------------

    /// Reads the template-Header and replaces {date} with the current date
    Future<String> _getHeader(final String potTemplateHeader) async {
        final File file = new File(potTemplateHeader);
        Validate.isTrue(file.existsSync(),"${potTemplateHeader} does not exist!");

        String template = await file.readAsString();
        template = template.replaceAll("{date}",
            new DateFormat("yyyy-MM-dd HH:mm").format(new DateTime.now()));

        return template;
    }
}

/// Writes the POT-File
POTVisitor WritePOTVisitor(final Logger logger, final File file) {
    return (final List<CommentStatement> comments,
        final List<L10NStatement> statements) {

        final StringBuffer buffer = new StringBuffer();

        comments.forEach((final CommentStatement statement) {
            final List<String> lines = statement.comment.split(new RegExp(r"\n"));
            lines.forEach((final String line) {
                buffer.writeln("#. ${line.trimLeft()}");
            });
        });
        statements.forEach((final L10NStatement statement) {
            buffer.writeln("#: ${statement.filename}:${statement.line}");
        });

        // All Statements have the same msgid - so we pick the first one
        final L10NStatement statement = statements.first;

        buffer.writeln('msgid "${statement.msgid}"');

        if(statement.params.length > 1) {
            buffer.writeln('msgid_plural "${statement.params[1]}"');
        }

        buffer.writeln('msgstr ""');
        buffer.writeln();

        logger.fine(buffer.toString().replaceFirst(new RegExp(r"\n$"), ""));
        file.writeAsStringSync(buffer.toString(),mode: FileMode.WRITE_ONLY_APPEND,flush: true);
        };
    }

/// Prints all the POT-Blocks
/// 
/// 
///     final List<Token> tokens = lexer.scan(source);
///     
///     final List<Statement> statements = parser.parse(filename, tokens);
///     final List<POTBlock> blocks = collectPOTBlocks(statements);
///     
///     pot.addBlocks(blocks);
///     pot.addBlocks(blocks);
///     
///     pot.mergedBlocks.values.forEach((final MergedPOTBlock block) {
///         block.visit(PrintPOTVisitor);
///     });
///     
void LogPOTVisitor(
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

    // All Statements have the same msgid - so we pick the first one
    final L10NStatement statement = statements.first;

    _logger.fine('msgid "${statement.msgid}"');
    if(statement.params.length > 1) {
        _logger.fine('msgid_plural "${statement.params[1]}"');
    }
    _logger.fine('msgstr ""');
    _logger.fine('');
}
