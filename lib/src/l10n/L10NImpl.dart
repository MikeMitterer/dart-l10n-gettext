part of l10n;

String _sanitizeMessage(final String translatedMessage) {
    Validate.notBlank(translatedMessage);
    return translatedMessage.replaceAll(new RegExp(r'(\.\n)'),". ").replaceAll(new RegExp(r'(\n|\r|\s{2,})')," ").trim();
}

/**
 * Handelt eine Message die später übersetzt werden kann.
 *
 * Sample:
 *      final L10NMessage message = new L10NMessage("test.message","Hallo {{name}}, du bist jetzt {{age}} Jahre alt",{ "name" : "Mike", "age" : 47});
 *
 * Über den key kann die MessageID aus einem Json-File abgefragt werden.
 * {{<variabl>}} werden durch die Werte in der Variablen-Tabelle ersetzt.
 *
 * Ergebnis für das oben genannte Sample wäre dann: "Hallo Mike, du bist jetzt 47 Jahre alt"
 */
class L10NImpl implements L10N {
    /// Key auf den Eintrag in der Sprachtabelle
    final String _key;

    /// DefaultMessage die angzeigt wird wenn der Key nicht gefunden wird
    final String _defaultMessage;

    /// Die Variablen die im _l10nkey gesetzt werden können
    final Map<String, dynamic> _variables;

    const L10NImpl(this._key,this._defaultMessage, [ Map<String, dynamic> this._variables = const {} ]);

    factory L10NImpl.fromJson(final data) {
        Validate.notNull(data);
        Map<String,dynamic> json = L10NImpl._toJsonMap(data);

        Validate.isKeyInMap("key",json);
        Validate.isKeyInMap("defaultmessage",json);

        final String key = json['key'];
        final String defaultMessage = json['defaultmessage'];
        Map<String, dynamic> variablesTemp = new HashMap<String,dynamic>();

        if(json.containsKey("variables")) {
            variablesTemp = L10NImpl._toJsonMap(json["variables"]);
        }
        return new L10NImpl(key,defaultMessage,variablesTemp);
    }

    Map<String, dynamic> get variables => _variables;

    String get key => _key;

    String get message {
        String message = _defaultMessage.trim();

        _variables.forEach((final String key,final value) {
            message = message.replaceAll("{{$key}}",value.toString());
        });

        return _sanitizeMessage(message);
    }

    Map<String, dynamic> toJson() {
        final Map map = new Map<String, dynamic>();

        map['key'] = _key;
        map['defaultmessage'] = _defaultMessage;
        map['variables'] = _variables;

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
            return data;

        } else if(data is String) {
            return JSON.decode(data);
        }

        throw new ArgumentError("$data is not a valid basis for a JSON-Map. Data should be either a String or a Map but was ${data.runtimeType}");
    }
}


