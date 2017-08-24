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

/**
 * The parser takes in a sequence of tokens
 * and generates an abstract syntax tree.
 */
class Parser {
    final List<Token> _tokens = new List<Token>();

    /**
     * The top-level function to start parsing. This will keep consuming
     * tokens and routing to the other parse functions for the different
     * grammar syntax until we run out of code to parse.
     *
     * We need a [filename] to printing out filenames and linenumbers
     * The [tokens] to parse
     */
    List<Statement> parse(final String filename, final List<Token> tokens) {
        final List<Statement> statements = new List<Statement>();

        this._tokens.clear();
        this._tokens.addAll(tokens);

        int line = 0;
        _tokens.forEach((final Token token) {

            switch(token.type) {
                case TokenType.COMMENT:
                    statements.add(new CommentStatement(line, token.text));
                    line += math.max(1,token.text.split("\n").length);
                    break;

                case TokenType.L10N:
                    statements.add(new L10NStatement(filename, line, token.text));
                    break;

                case TokenType.LINE:
                    statements.add(new NewLineStatement(line));
                    line++;
                    break;

                default:
            }
        });

        return statements;
    }



}