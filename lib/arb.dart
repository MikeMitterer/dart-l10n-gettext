library l10n.arb;

import "dart:collection";
import 'dart:io';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:dryice/dryice.dart';
import 'package:intl_translation/src/intl_message.dart';


import "package:validate/validate.dart";

class ARB {
    static final ARB _instance = ARB._private();

    factory ARB() => _instance;

    /// Singleton uses privat CTOR
    ARB._private();

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

