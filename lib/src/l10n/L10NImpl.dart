part of l10n;

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
    final _logger = new Logger('l10n.L10NMessage');

    /// Key auf den Eintrag in der Sprachtabelle
    String _key;

    /// DefaultMessage die angzeigt wird wenn der Key nicht gefunden wird
    String _defaultMessage;

    /// Die Variablen die im _l10nkey gesetzt werden können
    Map<String, dynamic> _variables = new HashMap<String,dynamic>();

    L10NImpl(this._key,final String defaultMessage, [ Map<String, dynamic> l10nvariables = const {} ]) :
        _variables = new HashMap.from(l10nvariables), _defaultMessage = defaultMessage.trim() {

        Validate.notBlank(_key);
        Validate.notBlank(_defaultMessage);
        Validate.notNull(_variables);
    }

    L10NImpl.fromJson(final data) {
        Validate.notNull(data);
        Map<String,dynamic> json = _toJsonMap(data);

        Validate.isKeyInMap("key",json);
        Validate.isKeyInMap("defaultmessage",json);

        _key = json['key'];
        _defaultMessage = json['defaultmessage'];
        if(json.containsKey("variables")) {
            _variables = _toJsonMap(json["variables"]);
        }
    }

    Map<String, dynamic> get variables => _variables;

    String get key => _key;

    String get message {
        String message = _defaultMessage;

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
    Map<String,dynamic> _toJsonMap(final data) {
        Validate.notNull(data);

        if(data is Map) {
            return data;

        } else if(data is String) {
            return JSON.decode(data);
        }

        throw new ArgumentError("$data is not a valid basis for a JSON-Map. Data should be either a String or a Map but was ${data.runtimeType}");
    }
}


