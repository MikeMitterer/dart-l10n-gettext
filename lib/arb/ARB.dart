/*
 * Copyright (c) 2018, Michael Mitterer (office@mikemitterer.at),
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

part of l10n.arb;

class _ARB {
    static final _ARB _instance = _ARB._private();

    factory _ARB() => _instance;

    /// Singleton uses privat CTOR
    _ARB._private();

    /// Convert the [MainMessage] to a trivial JSON format.
    Map toJSON(final MainMessage message) {
        final out = {};

        if (message.messagePieces.isEmpty) return null;

        out[message.name] = _icuForm(message);
        out["@${message.name}"] = _arbMetadata(message);

        return out;
    }


    /// Return a version of the message string with with ICU parameters "{variable}"
    /// rather than Dart interpolations "$variable".
    String _icuForm(final MainMessage message) => message.expanded(_turnInterpolationIntoICUForm);

    Map _arbMetadata(final MainMessage message) {
        var out = {};
        var desc = message.description;
        if (desc != null) {
            out["description"] = desc;
        }
        out["type"] = "text";
        var placeholders = {};
        for (var arg in message.arguments) {
            _addArgumentFor(message, arg, placeholders);
        }
        out["placeholders"] = placeholders;
        return out;
    }

    void _addArgumentFor(final MainMessage message, final String arg,final Map result) {
        var extraInfo = {};
        if (message.examples != null && message.examples[arg] != null) {
            extraInfo["example"] = message.examples[arg];
        }
        result[arg] = extraInfo;
    }

    String _turnInterpolationIntoICUForm(final Message message,final chunk, { bool shouldEscapeICU: false }) {
        if (chunk is String) {
            return shouldEscapeICU ? _escape(chunk) : chunk;
        }
        if (chunk is int && chunk >= 0 && chunk < message.arguments.length) {
            return "{${message.arguments[chunk]}}";
        }
        if (chunk is SubMessage) {
            return chunk.expanded((message, chunk) =>
                _turnInterpolationIntoICUForm(message, chunk, shouldEscapeICU: true));
        }
        if (chunk is Message) {
            return chunk.expanded((message, chunk) => _turnInterpolationIntoICUForm(
                message, chunk,
                shouldEscapeICU: shouldEscapeICU));
        }
        throw new FormatException("Illegal interpolation: $chunk");
    }

    String _escape(String s) {
        return s.replaceAll("'", "''").replaceAll("{", "'{'").replaceAll("}", "'}'");
    }
}