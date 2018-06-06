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
    /// Current position in source
    int _offset = 0;

    /// Current character in source
    String _character = "";

    /// Source for the current scan
    String _source = '';

    /// Many tokens are a single character, like operators and ().
    final String _singleCharTokens = "(),{}";

    /// These types are directly associated with [_singleCharTokens]
    final List<TokenType> _tokenTypes = [
        TokenType.LEFT_BRACKET, TokenType.RIGHT_BRACKET,
        TokenType.COLON, TokenType.SCOPE_BEGIN, TokenType.SCOPE_END,
    ];

    int _lineCounter = 0;

    final List<Token> _tokens = new List<Token>();

    /**
     * This function takes a script as a string of characters and chunks it into
     * a sequence of tokens. Each token is a meaningful unit of program, like a
     * variable name, a number, a string, or an operator.
     */
    List<Token> scan(final String source) {
        Validate.notNull(source);

        // Reset everything in case of reusing the Lexer
        _source = source;
        _offset = 0;
        _character = '';
        _tokens.clear();
        _lineCounter = 0;

        if(_source.isEmpty) {
            _offset = _EOF;
        } else {
            _character = _readNext();
        }
        

        String token = "";
        TokenizeState state = TokenizeState.DEFAULT;

        // Scan through the code one character at a time, building up the list of tokens.
        for (String c = _peek(); _offset != _EOF; c = _readNext()) {

            // ignore: missing_enum_constant_in_switch
            switch (state) {
                case TokenizeState.DEFAULT:
                    if (_isNext('"""')) {
                        _skip('"""');
                        _tokens.add(new Token('"""', TokenType.STRING_BLOCK));
                    }
                    else if (_isNext("'''")) {
                        _skip("'''");
                        _tokens.add(new Token("'''", TokenType.STRING_BLOCK));
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

                    // Keywords
                    else if (_isNext('_(')) {
                        _skip('_');
                        _tokens.add(new Token("_", TokenType.L10N));
                        token = "";
                    }
                    else if (_isNext('l10n(')) {
                        _skip('l10n');
                        _tokens.add(new Token("l10", TokenType.L10N));
                        token = "";
                    }
                    else if (_isNext('gettext')) {
                        _skip('gettext');
                        _tokens.add(new Token("gettext", TokenType.L10N));
                        token = "";
                    }

                    // Single-Character-Tokens
                    else if (_singleCharTokens.indexOf(c) != -1) {
                        _tokens.add(new Token(c, _tokenTypes[_singleCharTokens.indexOf(c)]));
                    }
                    else if( c == '\n') {
                        _tokens.add(new Token((_lineCounter).toString(), TokenType.LINE));
                        _lineCounter++;
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
                        _tokens.add(new Token(token, TokenType.WORD));
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
                        _tokens.add(new Token(token, TokenType.NUMBER));
                        token = "";
                        state = TokenizeState.DEFAULT;

                        _reprocess();
                    }
                    break;

                case TokenizeState.STRING_TRIPPLE_QUOTE:
                    Validate.isTrue(false,"Tripple-Quote not possible!");
                    break;

                case TokenizeState.STRING_DOUBLE_QUOTE:
                    if (c == '"' && !_isPrev('\\')) {
                        _tokens.add(new Token(token, TokenType.STRING));
                        _lineCounter += math.max(0,token.split("\n").length - 1);

                        token = "";
                        state = TokenizeState.DEFAULT;
                    }
                    else if(_isNext("\${") && !_isPrev('\\')) {
                        _tokens.add(new Token(token, TokenType.STRING));
                        _lineCounter += math.max(0,token.split("\n").length - 1);

                        token = "";

                        _readStringInterpolation();

                        state = TokenizeState.STRING_DOUBLE_QUOTE;
                    }
                    else {
                        token += c;
                    }
                    break;

                case TokenizeState.STRING_SINGLE_QUOTE:
                    if (c == "'" && !_isPrev('\\')) {
                        _tokens.add(new Token(token, TokenType.STRING));
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
                        // Remove Asterisk in Block-Comments
                        final String tempToken = token.trimLeft()
                            .replaceAll(new RegExp(r"^\s*\* *",multiLine: true), "");

                        _tokens.add(new Token(tempToken, TokenType.COMMENT));
                        _lineCounter += token.split("\n").length;

                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

                case TokenizeState.SLASH_COMMENT:
                    if (_isNext('\n')) {
                        _tokens.add(new Token(token.trimLeft(), TokenType.COMMENT));
                        _lineCounter++;
                        
                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

                case TokenizeState.HTML_COMMENT:
                    if (_isNext('-->')) {
                        _skip('-->');
                        _tokens.add(new Token(token.trimLeft(), TokenType.COMMENT));
                        token = "";
                        state = TokenizeState.DEFAULT;
                    } else {
                        token += c;
                    }

                    break;

//                case TokenizeState.L10N:
//                    {
//                        final String param = _readStringParam();
//                        token += param;
//
//                        // c has changed in _readStringParam
//                        c = _peek();
//
//                        //_logger.warning("V $value C $c");
//                        if (c == ')') {
//                            _tokens.add(new Token(token, TokenType.L10N));
//                            token = "";
//                            state = TokenizeState.DEFAULT;
//                        }
//                    }
//                    break;
            }
        }

        // HACK: Silently ignore any in-progress token when we run out of
        // characters. This means that, for example, if a script has a string
        // that's missing the closing ", it will just ditch it.
        return _tokens;
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

    bool _isPrev(final String expected) {
        final int nrOfCharacters = expected.length;
        final int tempOffset = _offset - 1 - nrOfCharacters;

        if(tempOffset < 0) {
            return false;
        }

        return _source.substring(tempOffset,tempOffset + nrOfCharacters) == expected;
    }

    String _readNext() {
        if(_offset == _EOF) {
            _character = '';
            return _character;
        }

        if(_offset >= _source.length) {
            _character = '';
            _offset = _EOF;
        } else {

            _character = _source.substring(_offset, _offset + 1);
            _offset++;
        }
        
        return _character;
    }

    /// Keep as a reminder!
    // ignore: unused_element
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
                    }
                    else if(_isNext('"""')) {
                        _skip('"""');
                        stringClosed = true;
                    }
                    else if (c == '"' && _isPrev('\\') == false) {
                        stringClosed = true;
                    }
                    else if (c == "'" && _isPrev('\\') == false) {
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

    void _readStringInterpolation() {
        TokenizeState state = TokenizeState.DEFAULT;
        String token = "";

        if(_isNext("\${") && !_isPrev('\\')) {
             _skip("\${");
        }
        else {
            return;
        }

        _tokens.add(new Token("\${", TokenType.INTERPOLATION));
        _tokens.add(new Token("{", TokenType.SCOPE_BEGIN));

        String c = _peek();
        do {
            // ignore: missing_enum_constant_in_switch
            switch(state) {
                case TokenizeState.DEFAULT:
                    if(_isNext("\${") && !_isPrev('\\')) {
                        _skip("\${");
                        state = TokenizeState.INTERPOLATION;
                    }
                    if (_isNext('"""')) {
                        _skip('"""');
                        state = TokenizeState.STRING_TRIPPLE_QUOTE;
                    }
                    else if (_isNext("'''")) {
                        _skip("'''");
                        state = TokenizeState.STRING_TRIPPLE_QUOTE;
                    }
                    else if (c == '"') {
                        _skip('"');
                        state = TokenizeState.STRING_DOUBLE_QUOTE;
                    }
                    else if (c == "'") {
                        _skip("'");
                        state = TokenizeState.STRING_SINGLE_QUOTE;
                    }

                    // Keywords
                    else if (_isNext('_(')) {
                        _skip('_');
                        _tokens.add(new Token("_", TokenType.L10N));
                        token = "";
                    }
                    else if (_isNext('l10n(')) {
                        _skip('l10n');
                        _tokens.add(new Token("l10", TokenType.L10N));
                        token = "";
                    }
                    else if (_isNext('gettext(')) {
                        _skip('gettext');
                        _tokens.add(new Token("gettext", TokenType.L10N));
                        token = "";
                    }

                    // Single-Character-Tokens
                    else if (_singleCharTokens.indexOf(c) != -1) {
                        _tokens.add(new Token(c, _tokenTypes[_singleCharTokens.indexOf(c)]));
                    }
                    else if( c == '\n') {
                        _tokens.add(new Token((_lineCounter).toString(), TokenType.LINE));
                        _lineCounter++;
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
                        _tokens.add(new Token(token, TokenType.WORD));
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
                        _tokens.add(new Token(token, TokenType.NUMBER));
                        token = "";
                        state = TokenizeState.DEFAULT;

                        _reprocess();
                    }
                    break;

                case TokenizeState.STRING_TRIPPLE_QUOTE:
                    if(_isNext("'''")) {
                        _skip("'''");
                    }
                    break;

                case TokenizeState.STRING_DOUBLE_QUOTE:
                    if (c == '"' && !_isPrev('\\')) {
                        _tokens.add(new Token(token, TokenType.STRING));
                        _lineCounter += math.max(0,token.split("\n").length - 1);

                        token = "";
                        state = TokenizeState.DEFAULT;
                    }
                    else {
                        token += c;
                    }
                    break;
                case TokenizeState.STRING_SINGLE_QUOTE:
                    if (c == "'" && !_isPrev('\\')) {
                        _tokens.add(new Token(token, TokenType.STRING));
                        _lineCounter += math.max(0,token.split("\n").length - 1);

                        token = "";
                        state = TokenizeState.DEFAULT;
                    }
                    else {
                        token += c;
                    }
                    break;

            }
            c = _readNext();
        }
        while (_offset != _EOF && c != '}' && !_isPrev("\\"));

        _tokens.add(new Token("}", TokenType.SCOPE_END));

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