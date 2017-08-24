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

const int _EOF = -1;

class Lexer {
    final Logger _logger = new Logger('l10n.parser.Lexer');

    /// Current position in source
    int _offset = 0;

    /// Current character in source
    String _character = "";

    /// Source for the current scan
    String _source = '';

    /**
     * This function takes a script as a string of characters and chunks it into
     * a sequence of tokens. Each token is a meaningful unit of program, like a
     * variable name, a number, a string, or an operator.
     */
    List<Token> scan(final String source) {
        Validate.notNull(source);

        final List<Token> tokens = new List<Token>();

        _source = source;
        if(_source.isEmpty) {
            _offset = _EOF;
        } else {
            _character = _readNext();
        }
        
        // Many tokens are a single character, like operators and ().
        final String charTokens = "\n()";

        final List<TokenType> tokenTypes = [
            TokenType.LINE, TokenType.LEFT_PAREN, TokenType.RIGHT_PAREN
        ];

        String token = "";
        TokenizeState state = TokenizeState.DEFAULT;

        // Scan through the code one character at a time, building up the list of tokens.
        for (String c = _peek(); _offset != _EOF; c = _readNext()) {

            switch (state) {
                case TokenizeState.DEFAULT:
                    if (_isNext('"""')) {
                        _skip('"""');
                        tokens.add(new Token('"""', TokenType.STRING_BLOCK));
                    }
                    else if (_isNext("'''")) {
                        _skip("'''");
                        tokens.add(new Token("'''", TokenType.STRING_BLOCK));
                    }
                    else if (c == '"') {
                        state = TokenizeState.STRING_DOUBLE_QUOTE;
                    }
                    else if (c == "'") {
                        state = TokenizeState.STRING_SINGLE_QUOTE;
                    }
                    else if (_isNext('/**')) {
                        _skip('/**');
                        state = TokenizeState.COMMENT;
                    }
                    else if (_isNext('/*')) {
                        _skip('/*');
                        state = TokenizeState.COMMENT;
                    }
                    else if (_isNext('///')) {
                        _skip('///');
                        state = TokenizeState.SLASH_COMMENT;
                    }
                    else if (_isNext('//')) {
                        _skip('//');
                        state = TokenizeState.SLASH_COMMENT;
                    }
                    else if (_isNext('<!--')) {
                        _skip('<!--');
                        state = TokenizeState.HTML_COMMENT;
                    }
                    else if (_isNext('_(')) {
                        _skip('_(');
                        state = TokenizeState.L10N;
                    }
                    else if (_isNext('l10n(')) {
                        _skip('l10n(');
                        state = TokenizeState.L10N;
                    }
                    else if (_isNext('gettext(')) {
                        _skip('gettext(');
                        state = TokenizeState.L10N;
                    }
                    else if (charTokens.indexOf(c) != -1) {
                        tokens.add(new Token(c, tokenTypes[charTokens.indexOf(c)]));
                    }
                    else if (CharacterType.isLetter(c)) {
                        token += c;
                        state = TokenizeState.WORD;
                    }
                    else if (CharacterType.isDigit(c)) {
                        token += c;
                        state = TokenizeState.NUMBER;
                    }

                    break;

                case TokenizeState.WORD:
                    if (CharacterType.isLetterOrDigit(c)) {
                        token += c;
                    }
                    else {
                        tokens.add(new Token(token, TokenType.WORD));
                        token = "";
                        state = TokenizeState.DEFAULT;

                        _reprocess();
                    }
                    break;

                case TokenizeState.NUMBER:
                    // HACK: Negative numbers and floating points aren't supported.
                    // To get a negative number, just do 0 - <your number>.
                    // To get a floating point, divide.
                    if (CharacterType.isDigit(c)) {
                        token += c;
                    }
                    else {
                        tokens.add(new Token(token, TokenType.NUMBER));
                        token = "";
                        state = TokenizeState.DEFAULT;

                        _reprocess();
                    }
                    break;

                case TokenizeState.STRING_TRIPPLE_QUOTE:
                    Validate.isTrue(false,"Tripple-Quote not possible!");
                    break;

                case TokenizeState.STRING_DOUBLE_QUOTE:
                case TokenizeState.STRING_SINGLE_QUOTE:
                    if (c == '"' || c == "'") {
                        tokens.add(new Token(token, TokenType.STRING));
                        token = "";
                        state = TokenizeState.DEFAULT;
                    }
                    else {
                        token += c;
                    }
                    break;

                case TokenizeState.COMMENT:
                    if (_isNext('*/')) {
                        _skip('*/');
                        tokens.add(new Token(token.trimLeft()
                                // Remove Asterisk in Block-Comments
                                .replaceAll(new RegExp(r"^\s*\* *",multiLine: true), ""),
                            TokenType.COMMENT));
                        
                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

                case TokenizeState.SLASH_COMMENT:
                    if (_isNext('\n')) {
                        tokens.add(new Token(token.trimLeft(), TokenType.COMMENT));
                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

                case TokenizeState.HTML_COMMENT:
                    if (_isNext('-->')) {
                        _skip('-->');
                        tokens.add(new Token(token.trimLeft(), TokenType.COMMENT));
                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

                case TokenizeState.L10N:
                    {
                        final String param = _readStringParam();
                        token += param;

                        // c has changed in _readStringParam
                        c = _peek();
                        
                        //_logger.warning("V $value C $c");
                        if (c == ')') {
                            tokens.add(new Token(token, TokenType.L10N));
                            token = "";
                            state = TokenizeState.DEFAULT;
                        }
                    }
                    break;
            }
        }

        // HACK: Silently ignore any in-progress token when we run out of
        // characters. This means that, for example, if a script has a string
        // that's missing the closing ", it will just ditch it.
        return tokens;
    }

    //- private -----------------------------------------------------------------------------------

    String _peek() => _character;

    bool _isNext(final String expected) {
        final int nrOfCharacters = expected.length;

        if(_offset + (nrOfCharacters - 1) > _source.length) {
            return false;
        }
        final int tempOffset = _offset > 0 ? _offset - 1 : 0;
        return _source.substring(tempOffset,tempOffset + nrOfCharacters) == expected;
    }

    String _readNext() {
        if(_offset == _EOF) {
            _character = '';
            return _character;
        }

        if(_offset + 1 >= _source.length) {
            _character = '';
            _offset = _EOF;
        } else {

            _character = _source.substring(_offset, _offset + 1);
            _offset++;
        }
        
        return _character;
    }

    String _readStringParam() {
        String value = "";
        TokenizeState subState = TokenizeState.DEFAULT;
        bool stringClosed = false;
        bool functionClosed = false;

        String c = _peek();
        do {
            // ignore: missing_enum_constant_in_switch
            switch(subState) {
                case TokenizeState.DEFAULT:
                    if (_isNext('"""')) {
                        _skip('"""');
                        subState = TokenizeState.STRING_TRIPPLE_QUOTE;
                    }
                    else if (_isNext("'''")) {
                        _skip("'''");
                        subState = TokenizeState.STRING_TRIPPLE_QUOTE;
                    }
                    else if (c == '"') {
                        _skip('"');
                        subState = TokenizeState.STRING_DOUBLE_QUOTE;
                    }
                    else if (c == "'") {
                        _skip("'");
                        subState = TokenizeState.STRING_SINGLE_QUOTE;
                    }
                    // Necessary for: print(translate(_(   "Test 3"   )));
                    else if (c == ")") {
                        functionClosed = true;
                    }
                    break;

                case TokenizeState.STRING_SINGLE_QUOTE:
                case TokenizeState.STRING_DOUBLE_QUOTE:
                case TokenizeState.STRING_TRIPPLE_QUOTE:
                    if(_isNext("'''")) {
                        _skip("'''");
                        stringClosed = true;
                    } else if(_isNext('"""')) {
                        _skip('"""');
                        stringClosed = true;
                    }else if (c == '"' || c == "'") {
                        stringClosed = true;
                    }
                    else {
                        value += c;
                    }
                    break;

            }
            // If 'functionClosed' we would loose ')' on the next read
            if(!functionClosed) {
                c = _readNext();
            }
        }
        while (_offset != _EOF && (!stringClosed && !functionClosed));

        return value;
    }

    /// Reprocess this character in the default state.
    void _reprocess() {
        _offset--;
    }

    /// Skip the following String
    ///
    /// [textToSkip] - Text to skip
    void _skip(final String textToSkip) {
        final int nrOfCharacters = textToSkip.length;
        final int tempOffset = _offset > 0 ? _offset - 1 : 0;

        if(_source.substring(tempOffset, tempOffset + nrOfCharacters) == textToSkip) {
            _offset = tempOffset + nrOfCharacters;
            if(_offset >= _source.length) {
                _offset = _EOF;
            }
        }
    }
}