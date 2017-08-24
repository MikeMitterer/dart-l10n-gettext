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

class POT {
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
}