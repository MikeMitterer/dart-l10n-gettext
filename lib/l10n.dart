library l10n;

import "dart:collection";
//import 'package:logging/logging.dart';
import 'dart:convert';

import "package:validate/validate.dart";

part "interfaces.dart";

part 'src/l10n/keys.dart';
part 'src/l10n/L10NImpl.dart';

final L10NTranslate TRANSLATOR = new L10NTranslate();

/// Shortcut to get a L10N object
L10N l10n(final String key,final String defaultMessage, [final Map<String, dynamic> l10nvariables = const {} ]) {
    return new L10N(key,defaultMessage,l10nvariables);
}

/**
 * Basis für Übersetzungen.
 * Macht zur Zeit im Prinzip nur einen String-Replace
 */
class L10NTranslate {
    final Map<String,String> _locale;

    L10NTranslate.withMap(final Map<String,String> locale) : _locale = new HashMap.from(locale);
    L10NTranslate() : _locale = new HashMap<String,String>();

    /// Wenn es einen Eintrag für message.key in der _locale Tabelle gibt wir
    /// ein String.replaceAll auf die Variablen in der message ausgeführt
    String translate(final L10N l10n) {
        Validate.notNull(l10n);

        String translatedMessage;
        if(_locale.containsKey(l10n.key)) {
            translatedMessage = _locale[l10n.key];

            l10n.variables.forEach((final String key,final value) {
                translatedMessage = translatedMessage.replaceAll("{{$key}}",value.toString());
            });

        } else {
            translatedMessage = l10n.message;
        }

        return (translatedMessage);
    }

    String call(final L10N l10n) {
        return translate(l10n);
    }

    String translateStatusCode(final int status) {
        final L10NImpl message = new L10NImpl (
                keyStatusCode(status),
                "({{statuscode}})",
                { "statuscode" : status }
            );
        return translate(message);
    }

    // -- private -------------------------------------------------------------

}

