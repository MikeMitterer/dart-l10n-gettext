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

    /// Current Token-Position
    int _offset = 0;

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

        // Reset in case of reuse
        _offset = 0;

        this._tokens.clear();
        this._tokens.addAll(tokens);

        int line = 1;
        for(Optional<Token> oToken = _peek(); oToken.isPresent && _offset < _tokens.length; oToken = _peek()) {
            Token token = oToken.value;

            switch(token.type) {
                case TokenType.COMMENT:
                    statements.add(new CommentStatement(line, token.text));
                    line += math.max(1,token.text.split("\n").length);
                    _read();
                    break;

                case TokenType.L10N:
                    // Singular
                    if(_isNext([TokenType.STRING, TokenType.RIGHT_BRACKET ])) {
                        token = _read().value;
                        statements.add(new L10NStatement(filename, line, [token.text]));
                    }
                    // Plural
                    else if(_isNext([TokenType.STRING, TokenType.COLON, TokenType.STRING, TokenType.RIGHT_BRACKET ])) {
                        final List<String> params = new List<String>();

                        // String, Colon, String
                        params.add(_read().value.text);_read();params.add(_read().value.text);

                        statements.add(
                            new L10NStatement(filename, line, params));
                    }
                    _read();
                    break;

                case TokenType.LINE:
                    statements.add(new NewLineStatement(line));
                    line++;
                    _read();
                    break;

                default:
                    _read();
            }
        };

        return statements;
    }

    // - private -----------------------------------------------------------------------------------

    /// Peek the current [Token]
    /// Avoiding null - so [Optional] is a good option
    Optional<Token> _peek() => _offset < _tokens.length ?
        new Optional.of(_tokens[_offset]) : new Optional.empty();

    /// Returns the next [Token]
    ///
    /// In case of EOF it returns an empty [Optional]
    Optional<Token>  _read() {
        _offset++;
        if (_offset < _tokens.length) {
            return new Optional.of(_tokens[_offset]);
        }
        return new Optional.empty();
    }

    /// Compares the next tokens
    bool _isNext(final List<TokenType> types) {
        Validate.notEmpty(types);

        final int endPosition = _offset + 1 + types.length;
        if(endPosition >= _tokens.length) {
            return false;
        }
        for(int index = 0;(index + _offset + 1) < endPosition; index++) {
            if(types[index] != _tokens[(index + _offset + 1)].type) {
                //print("T1 ${types[index]}, T2 ${_tokens[(index + _offset + 1)].type}");
                return false;
            }
        }
        return true;
    }
}