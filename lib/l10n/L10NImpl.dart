part of l10n;

/**
 * Die MessageID darf kein \n, \r oder mehrere Spaces enthalten.
 */
String _sanitizeMessageID(final String translatedMessage) {
    Validate.notBlank(translatedMessage);
    return translatedMessage
        .replaceAll(new RegExp(r'(\.\n)'),". ")
        .replaceAll(new RegExp(r'(\n|\r)'),"")
        .replaceAll(new RegExp(r'\s{2,}')," ").trim();
}

/**
 * Handelt eine Message die später übersetzt werden kann.
 *
 * Sample:
 *      final L10NMessage message = new L10NMessage("Hallo {{name}}, du bist jetzt {{age}} Jahre alt",{ "name" : "Mike", "age" : 47});
 *
 * Über die msgid (MessageID) aus einem Json-File abgefragt werden.
 * {{<variabl>}} werden durch die Werte in der Variablen-Tabelle ersetzt.
 *
 * Ergebnis für das oben genannte Sample wäre dann: "Hallo Mike, du bist jetzt 47 Jahre alt"
 */
class L10NImpl implements L10N {
    /// Key auf den Eintrag in der Sprachtabelle
    final String _msgID;

    /// Die Variablen die im _l10nkey gesetzt werden können
    final Map<String, dynamic> _vars;

    const L10NImpl(this._msgID, [ Map<String, dynamic> this._vars = const {} ]);

    factory L10NImpl.fromJson(final data) {
        Validate.notNull(data);
        Map<String,dynamic> json = L10NImpl._toJsonMap(data);

        Validate.isKeyInMap("msgid",json);

        final String msgid = json['msgid'];
        Map<String, dynamic> vars = new HashMap<String,dynamic>();

        if(json.containsKey("vars")) {
            vars = L10NImpl._toJsonMap(json["vars"]);
        }
        return new L10NImpl(msgid,vars);
    }

    Map<String, dynamic> get vars => _vars;

    String get msgid => _sanitizeMessageID(_msgID);

    /// Gives back the msgid with all the vars set
    String get message {
        String message = msgid;

        _vars.forEach((final String key,final value) {
            message = message.replaceAll("{{$key}}",value.toString());
        });

        return message;
    }

    Map<String, dynamic> toJson() {
        final Map<String, dynamic> map = new Map<String, dynamic>();

        Map<String,dynamic> convertVarsToEncodableValues(final Map<String,dynamic> vars) {
            final Map<String,dynamic> encodableVars = new Map<String, dynamic>();

            vars.forEach((final String key,final value) {
                if(value == null || value is num || value is String || value is bool) {
                    encodableVars[key] = value;
                } else {
                    encodableVars[key] = value.toString();
                }
            });
            return encodableVars;
        }

        map['msgid'] = msgid;
        map['vars'] = convertVarsToEncodableValues(_vars);

        return map;
    }

    @override
    String toString() {
        return JSON.encode(toJson());
    }

    String toPrettyString() {
        final JsonEncoder encoder = const JsonEncoder.withIndent('   ');
        return encoder.convert(toJson());
    }

    // -- private -------------------------------------------------------------

    /// Egal wie die Daten ankommen, ob als bereits als Map oder als String, die Daten werden
    /// immer als JSON-Map zurückgegeben
    static Map<String,dynamic> _toJsonMap(final data) {
        Validate.notNull(data);

        if(data is Map) {
            return data as Map<String, dynamic>;

        } else if(data is String) {
            return JSON.decode(data) as Map<String, dynamic>;
        }

        throw new ArgumentError("$data is not a valid basis for a JSON-Map. Data should be either a String or a Map but was ${data.runtimeType}");
    }
}


