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
 * This defines the different kinds of tokens or meaningful chunks of code
 * that the parser knows how to consume. These let us distinguish, for
 * example, between a string "foo" and a variable named "foo".
 *
 * HACK: A typical tokenizer would actually have unique token types for
 * each keyword (print, goto, etc.) so that the parser doesn't have to look
 * at the names, but Jasic is a little more crude.
 */
enum TokenType {
    EOF,
    WORD, NUMBER, STRING, STRING_BLOCK, LINE, COMMENT,
    LEFT_BRACKET, RIGHT_BRACKET, COLON,
    SCOPE_BEGIN, SCOPE_END,
    INTERPOLATION,
    L10N
}

/**
 * This is a single meaningful chunk of code. It is created by the tokenizer
 * and consumed by the parser.
 */
class Token {

    final String text;
    final TokenType type;

    Token(this.text, this.type);
}

/**
 * This defines the different states the tokenizer can be in while it's
 * scanning through the source code. Tokenizers are state machines, which
 * means the only data they need to store is where they are in the source
 * code and this one "state" or mode value.
 *
 * One of the main differences between tokenizing and parsing is this
 * regularity. Because the tokenizer stores only this one state value, it
 * can't handle nesting (which would require also storing a number to
 * identify how deeply nested you are). The parser is able to handle that.
 */
enum TokenizeState {
    DEFAULT, WORD, NUMBER,
    STRING_SINGLE_QUOTE, STRING_DOUBLE_QUOTE, STRING_TRIPPLE_QUOTE,
    INTERPOLATION,
    COMMENT, SLASH_COMMENT, HTML_COMMENT
}
