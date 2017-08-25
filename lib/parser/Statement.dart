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

abstract class Visitor {
    void visitComment(final CommentStatement statement);
    void visitL10n(final L10NStatement statement);

    void visitNetLine(final NewLineStatement statement) {}
}

/// Base interface for a gettext statements.
abstract class Statement {
    /// Line-Number where the original Statement was found
    final int line;

    Statement(this.line);

    void accept(final Visitor visitor);
}

/// Holds the comments
class CommentStatement extends Statement {
    final String comment;
    CommentStatement(final int line, this.comment) : super(line);

    @override
    void accept(final Visitor visitor) {
        visitor.visitComment(this);
    }
}

class L10NStatement extends Statement {
    final List<String> params;
    final String filename;

    L10NStatement(this.filename, final int line, final List<String> params)
        : params = new List.from(params), super(line);

    @override
    void accept(final Visitor visitor) {
        visitor.visitL10n(this);
    }

    /// First param is always the msgid
    String get msgid => params.first;
}

class NewLineStatement extends Statement {

    NewLineStatement(final int line) : super(line);

    @override
    void accept(Visitor visitor) {
        visitor.visitNetLine(this);
    }
}
